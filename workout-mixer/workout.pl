#! perl -w

use Getopt::Long;
use Data::Dumper;
use Mac::iTunes::Library::XML;
use strict;

my $libraryPath = $ENV{'HOME'} . '/Music/iTunes/iTunes Music Library.xml';
my $mix = '30'; # '5@130-150:140-150;20@150-165:160;5@130-150:150-140'
my $tempDir = '__workout_temp__';
my $outputTitle = 'workout';
my $verbose = '';
my $library;
my $acceptFilter = '';
my $rejectFilter = '';
my $cutoff = 15;
my $bitrate = 128;
my $artist = '';
my $year = (localtime())[5] + 1900;
my $image = '';

GetOptions(
    'library=s' => \$libraryPath,
    'mix=s'     => \$mix,
    'title=s'   => \$outputTitle,
    'accept=s'  => \$acceptFilter,
    'reject=s'  => \$rejectFilter,
    'artist=s'  => \$artist,
    'bitrate=i' => \$bitrate,
    'cutoff=i'  => \$cutoff,
    'image=s'   => \$image,
    'verbose'   => \$verbose
);

my @sequence = sequenceFromMix($mix);
# print Dumper(\@sequence);
my $songCache = cacheSongsForSequence(\@sequence);
# print Dumper($songCache);
my $playlist = buildPlaylist(\@sequence, $songCache);
# print Dumper($playlist);
# unlink($tempDir) if(-d $tempDir);
# mkdir($tempDir);
my $songN = 0;
my $wavFiles = '';
open(CHAP,">$outputTitle.chapters.txt");
open(FAAC,"| faac -b $bitrate -o '$outputTitle.m4a' --title '$outputTitle' --artist '$artist' --year $year -s " . (($image ne '') && (-f $image) ? "--cover-art '$image' " : '') . '-');
select(FAAC); $|=1; select(STDOUT);
my $place = 0;
my $type = 'wav';
foreach my $song (@{$playlist}) {
    $songN++;
    my $artist = $song->{'artist'};
    my $title = $song->{'title'};
    my $album = $song->{'album'};
    my $tempo = $song->{'tempo'};
    my $invTempo = 1.0 / $tempo;
    my $path = $song->{'path'};
    my $pace = $song->{'pace'};
    my $cut = $song->{'cut'};
    my $ms = $song->{'ms'};
    my $startMS = int(($ms - $cut) / 2);
    my $finishMS = $ms - $startMS;
    my $startTime = formatMS($startMS);
    my $finishTime = formatMS($finishMS);
    debug("Song: $title $pace, $tempo, " . formatMS($cut) . " > " . formatMS($cut / $tempo));
    # my $file = "'$tempDir/$songN.wav'";
    # $wavFiles .= " $file";
    my $index = formatMS($place);
    # print qq!sox --norm "$path" -t wav -c 2 -r 44100 -b 16 - trim =$startTime =$finishTime | sox -t wav - -t $type -c 2 -r 44100 -b 16 - tempo -m $tempo |!; # tempo -m $tempo
    open(SOX, qq!sox -q -V0 --norm "$path" -t $type -c 2 -r 44100 -b 16 - trim =$startTime =$finishTime tempo -m $tempo |!); # tempo -m $tempo
    select(SOX); $|=1; select(STDOUT);
    while(<SOX>) { print FAAC; }
    close(SOX);
    print CHAP "CHAPTER$songN=$index\nCHAPTER${songN}NAME=$artist / $album / $title\n";
    $place += int($cut / $tempo);
    $type = 'raw';
}
close(FAAC);
close(CHAP);
# system("play -t wav $wavFiles - | faac -b $bitrate -o '$tempDir/$outputTitle.m4a' -");
system("mp4chaps -i '$outputTitle.m4a'");
# for (my $i = 0; $i <= $songN; $i++) {
#    unlink("$tempDir/$i.wav");
#}
unlink("$outputTitle.chapters.txt");
#unlink($tempDir);
exit(0);

sub formatMS {
    my ($t) = @_;
    my $ms = $t % 1000; $t = int($t / 1000);
    my $s = $t % 60; $t = int($t / 60);
    my $m = $t % 60; $t = int($t / 60);
    return $t . ":" . substr("00$m:",-3,3) . substr("00$s.",-3,3) . substr("000$ms",-3,3);
}

sub buildPlaylist {
    my ($sequence, $songs) = @_;
    my @playlist = ();
    my $totalSegments = 0;
    foreach my $segment (@$sequence) {
        $totalSegments++;
        my $msTarget = $segment->{'seconds'} * 1000;
        my $ms = 0;
        my $minPace = $segment->{'inMin'};
        my $maxPace = $segment->{'inMax'};
        my $startPace = $segment->{'outStart'};
        my $finishPace = $segment->{'outFinish'};
        my @parts = ();
        my $paceRange = $finishPace - $startPace;
        while ($ms < $msTarget) {
            my $song = nextSongForPace($minPace, $maxPace, $songs);
            bail("Ran out of songs for pace $minPace-$maxPace, $totalSegments @ " . formatMS($ms)) unless($song);
            $song->{'tempo'} = ($startPace eq '*') ? 1 : ($startPace + (($ms / $msTarget) * $paceRange)) / $song->{'pace'};
            $ms += $song->{'ms'} / $song->{'tempo'};
            push @parts, $song;
        }
        my $scale = $msTarget / $ms;
        foreach my $part (@parts) {
            $part->{'cut'} = int($part->{'ms'} * $scale);
            push @playlist, $part;
        }
    }
    return \@playlist;
} # buildPlaylist

sub nextSongForPace {
    my ($minPace, $maxPace, $songs) = @_;
    my $key = $minPace . '-' . $maxPace;
    bail("Something weird happened with the pace $minPace/$maxPace") unless (defined($songs->{$key}));
    my $song = shift(@{$songs->{$key}});
    return $song;
} # nextSongForPace

sub cacheSongsForSequence {
    my ($sequence) = @_;
    my %cache;
    foreach my $segment (@$sequence) {
        my $key = $segment->{'inMin'} . '-' . $segment->{'inMax'};
        unless (defined($cache{$key})) {
            my $songs = getSongsForPaceRange($segment->{'inMin'}, $segment->{'inMax'});
            debug("Songs for pace: $key, " . scalar(@$songs));
            $cache{$key} = $songs;
        }
    }
    return \%cache;
}

sub getLibrary {
    unless ($library) {
        $library = Mac::iTunes::Library::XML->parse($libraryPath);
    }
    return $library;
} # getLibrary

sub urldecode { # via http://code.activestate.com/recipes/577450-perl-url-encode-and-decode/
    my ($s) = @_;
    # $s =~ s/\+/ /g;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $s;
}

sub shuffle { # via http://www.perlmonks.org/?node_id=1869
    my ($a) = @_;
    my $i = @$a;
    return unless($i > 1);
    while (--$i) {
        my $j = int rand($i + 1);
        @$a[$i,$j] = @$a[$j,$i];
    }
}

sub filterSong {
    my ($song) = @_;
    if (($acceptFilter eq '') && ($rejectFilter eq '')) { return 1; }
    if ($rejectFilter ne '') {
        if (($song->album() && ($song->album() =~ /$rejectFilter/i))
         || ($song->name() =~ /$rejectFilter/i)
         || ($song->artist() =~ /$rejectFilter/i)) { return 0; }
    }
    if ($acceptFilter ne '') {
        if (($song->album() && ($song->album() =~ /$acceptFilter/i))
         || ($song->name() =~ /$acceptFilter/i)
         || ($song->artist() =~ /$acceptFilter/i)) { return 1; }
        return 0;
    }
    return 1;
}

sub getSongsForPaceRange {
    my ($minPace, $maxPace) = @_;
    my $library = getLibrary();
    my %items = $library->items();
    my @songs = ();
    my %dupes = ();
    while (my ($artist, $artistSongs) = each %items) {
        while (my ($songName, $artistSongItems) = each %$artistSongs) {
            foreach my $item (@$artistSongItems) {
                my $pace = $item->bpm();
                next unless ($pace && ($pace =~ /^\s*(\d+)\s*/));
                $pace = int($1);
                next unless (($minPace eq '*') || (($pace >= $minPace) && ($pace <= $maxPace)));
                my $ms = int($item->totalTime());
                my $path = urldecode($item->location());
                $path =~ s!^file\://localhost!!;
                next unless((substr($path,-4,4) eq '.mp3') && (-f $path));
                next unless(filterSong($item));
                next unless($cutoff * 60000 >= $ms);
                my $artist = $item->artist();
                my $title = $item->name();
                next if(defined($dupes{$artist . ' / ' . $title}));
                $dupes{$artist . ' / ' . $title} = 1;
                my %song = (
                    'artist' => $artist,
                    'album'  => $item->album(),
                    'title'  => $title,
                    'path'   => $path,
                    'pace'   => $pace,
                    'ms'     => $ms
                );
                push @songs, \%song;
            }
        }
    }
    shuffle(\@songs);
    return \@songs;
} # getSongsForPaceRange

sub debug {
    return unless($verbose);
    print join("\n",@_), "\n";
} # debug

sub trim {
    my ($s) = @_;
    $s =~ s/^\s+|\s+$//g;
    return $s;
} # trim

sub bail {
    my ($msg) = @_;
    print join("\n",@_), "\n";
    exit(1);
} # bail

sub sequenceFromMix {
    my ($mix) = @_;
    my @sequence = ();
    foreach my $segment (split(';', $mix)) {
        debug("Segment: $segment");
        my %stats = (
            'seconds'   => 0,
            'inMin'   => '*',
            'inMax'  => '*',
            'outStart'  => '*',
            'outFinish' => '*'
        );
        my ($duration, $paceSpec) = split('@', $segment);
        if ($duration =~ /^\s*(\d+)\s*s\s*$/)     { $stats{'seconds'} = int($1); }
        elsif ($duration =~ /^\s*(\d+)\s*m?\s*$/) { $stats{'seconds'} = int($1) * 60; }
        elsif ($duration =~ /^\s*(\d+)\s*h\s*$/)  { $stats{'seconds'} = int($1) * 3600; }
        unless ($stats{'seconds'} > 0) { bail("Invalid segment duration: $duration"); }
        debug("  Dur: $duration ($stats{'seconds'}s)");
        unless ($paceSpec =~ /^\s*$/) {
            my ($inPace, $outPace) = split(':', $paceSpec);
            ($stats{'inMin'}, $stats{'inMax'}) = pacesFromMix($inPace);
            if ($stats{'inMin'} eq $stats{'inMax'}) {
                debug("  In: $stats{'inMin'}");
            } else {
                debug("  In: $stats{'inMin'}-$stats{'inMax'}");
            }
            ($stats{'outStart'}, $stats{'outFinish'}) = pacesFromMix($outPace);
            if ($stats{'outStart'} eq $stats{'outFinish'}) {
                debug("  Out: $stats{'outStart'}");
            } else {
                debug("  Out: $stats{'outStart'}-$stats{'outFinish'}");
            }
        }
        push @sequence, \%stats;
    }
    return @sequence;
} # sequenceFromMix

sub pacesFromMix {
    my ($paceSpec) = @_;
    my ($start, $finish);
    if ($paceSpec eq '*') { $start = '*'; $finish = '*'; }
    elsif ($paceSpec =~ /^\s*(\d+)\s*$/) { $start = $finish = int($paceSpec); }
    elsif ($paceSpec =~ /^\s*(\d+)\s*\-\s*(\d+)\s*$/) { $start = int($1); $finish = int($2); }
    else { bail("Invalid pace: $paceSpec"); }
    return ($start, $finish);
}