#! perl -w

use Getopt::Long;
use Data::Dumper;
use Mac::iTunes::Library::XML;
use strict;

my $libraryPath = $ENV{'HOME'} . '/Music/iTunes/iTunes Music Library.xml';
my $mix = '30@*:*'; # '5@130-150:140-150;20@150-165:160;5@130-150:150-140'
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
my $album = '';
my $overlap = 3000;
my $help = 0;

GetOptions(
    'library=s' => \$libraryPath,
    'mix=s'     => \$mix,
    'title=s'   => \$outputTitle,
    'accept=s'  => \$acceptFilter,
    'reject=s'  => \$rejectFilter,
    'artist=s'  => \$artist,
    'album=s'   => \$album,
    'bitrate=i' => \$bitrate,
    'cutoff=i'  => \$cutoff,
    'image=s'   => \$image,
    'overlap=i' => \$overlap,
    'verbose'   => \$verbose,
    'help'      => \$help
);

if ($help) {
    print<<__HELP__;
Workout Mixer by Rick Osborne

Input Options:
  --library 'path'    Path to your iTunes Library XML
      Default: ${libraryPath}
  --reject 'regex'    Match and reject tracks on Album, Artist, Title
      Note: the default state is 'allow all'
  --accept 'regex'    Match and accept (overridden by reject)
      Note: using --accept sets up 'reject by default' state
  --cutoff nn         Reject tracks longer than nn minutes, default: $cutoff
  --overlap nnnn      Crossfade between tracks in ms, default: $overlap
  --mix 'mixspec'     See the MIX SPECS section below.

Output Options:
  --title 'title'     The Title of the output MP4
  --artist 'artist'   etc.
  --album 'album'     etc.
  --image 'path'      Cover art (preferably JPEG)
  --bitrate nn        Bitrate in kbps, default: $bitrate

Misc. Options:
  --verbose           Prattle on about minutia
  --help              This lovely text

Mix Specs:
  Mix specifications are semicolon (;) delimited strings detailing a series
  of workout segments.  Each segment consists of:
  
    * Duration
    * Input tempo range (BPM)
    * Output tempo range
    
  For example, a segment might define 15 minutes at a 160bpm tempo mixed from
  songs with an original tempo between 120 and 140 bpm.  An entire workout
  can combine any number of segments, each with its own duration and tempos.

  Each segment is in the format "dd\@tt" with ";" between segments, like so:
    "dd\@tt;dd\@tt;dd\@tt"

  The duration ("dd") parameter is a whole number that defaults to minutes
  but can be specified in seconds, minutes, or hours with a "s", "m", or "h"
  suffix.  For example: "45m", "90s" or "1h".
  
  The tempo ("tt") parameter defaults to "*" which then does not perform any
  tempo adjustment.  Otherwise, tempo should be in an "aa:bb" format, where
  "aa" is the input tempo range and "bb" is the output tempo range.  Each
  range may be a single number, such as "145", or a range with a minimum and
  maximum, such as "120-140".
  
  The input ("aa") filters tracks to reject those outside that BPM range.
  
  The output ("bb") specifies the target BPM to which the tracks will be
  adjusted.  If this is a single number, such as "165", then all tracks in
  that segment will be adjusted to match that tempo.  Ranges such as "160-140"
  specify the starting and ending BPM for that segment.  Tracks will be
  adjusted to match that range according to where they fall in the segment.
  
  If no output tempo is specified then no adjusment is performed.
  
  Examples:
  
    '10\@160'  (shorthand for: '10m\@160:*')
    10 minutes of tracks with an original BPM of 160; no tempo adjustment.
    
    '10\@145-165'  (shorthand for: "10m\@145-165:*')
    The same as before, but the input BPM is between 145 and 165.
    
    '10\@145-165:160'  (shorthand for: '10m\@145-165:160')
    Like the last, but tempo-adjust the tracks to 160bpm.
    
    '10\@145-165:160-180'  (shorthand for: '10m\@145-165:160-180')
    Like the last, but tempo-adjust the tracks to begin the segment at 160bpm
    and end the segment at 180bpm.
    
    '1h'  (shorthand for: '1h\@*:*')
    One hour of tracks of any original BPM, not tempo-adjusted.
    
    '10m\@*:160;25\@*:170;5\@*:160'
    A 3-segment workout:
      10-minute warmup, tempo-adjusted to 160bpm
      25-minute workout, tempo-adjusted to 170bpm
      5-minute cooldown, tempo-adjusted to 160bpm

    '10m\@110-170:160;25\@120-180:170;5\@110-170:160'
    The same as before, but filtering out tracks that would be too slow or
    too fast and might not sound good when tempo-adjusted.  (Subjective!)

__HELP__
    exit(-1);
}

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
# open(FAAC,"| faac -b $bitrate -o '$outputTitle.m4a' --title '$outputTitle' --artist '$artist' --year $year -s " . (($image ne '') && (-f $image) ? "--cover-art '$image' " : '') . '-');
# select(FAAC); $|=1; select(STDOUT);
my $wavCount = 0;
my @titles = ();
my @times = ();
my $place = 0;
foreach my $song (@{$playlist}) {
    $songN++;
    my $artist = $song->{'artist'};
    my $title = $song->{'title'};
    my $album = $song->{'album'};
    my $tempo = $song->{'tempo'};
    my $path = $song->{'path'};
    my $pace = $song->{'pace'};
    my $cut = $song->{'cut'};
    my $ms = $song->{'ms'};
    my $newPace = int($pace * $tempo);
    push @titles, "$artist / $title \@ ${newPace}bpm"; 
    my ($startMS, $finishMS, $startTime, $finishTime);
    $startMS = int(($ms - ($cut + ($songN == 1 ? 0 : $overlap * $tempo))) / 2);
    if ($startMS < 0) { $startMS = 0; }
    $finishMS = $ms - $startMS;
    $startTime = formatMS($startMS);
    $finishTime = formatMS($finishMS);
    my $clipMS = ($finishMS - $startMS) / $tempo;
    my $clipTime = formatMS($clipMS);
    debug("Song: $pace > $newPace : $clipTime : $artist / $title");
    if (($songN > 1) && ($overlap > 0)) {
        my $nextWav = $wavCount + 1;
        my $fadeMS = (($finishMS - $startMS) / 8);
        if ($fadeMS < 12000) { $fadeMS = 12000; }
        my $nextFinish = $startMS + $fadeMS;
        my $nextFinishTime = formatMS($nextFinish);
        my $prevFinishTime = trim(`soxi -D $wavCount.wav`);
        debug("Crossfade Trim: " . formatMS($fadeMS));
        system(qq!sox -V0 --norm "$path" -t wav fadeIn.wav trim =$startTime =$nextFinishTime tempo -m $tempo!);
        debug("Crossfade: $prevFinishTime");
        system(qq!sox -V0 --norm $wavCount.wav fadeIn.wav 0.wav splice -q $prevFinishTime,! . ($overlap / 1000));
        unlink("fadeIn.wav");
        unlink("$wavCount.wav");
        rename("0.wav", "$wavCount.wav");
        $startMS = $nextFinish;
        $startTime = formatMS($startMS);
    }    
    my $index = formatMS(int($place - ($songN == 1 ? 0 : $overlap / 2)));
    push @times, $index;
    $wavCount++;
    system(qq!sox -V0 --norm "$path" -t wav $wavCount.wav trim =$startTime =$finishTime tempo -m $tempo!);
    $place += 1000 * trim(`soxi -D $wavCount.wav`);
}
my $faacLine = "sox -V0 ";
open(CHAP,">$outputTitle.chapters.txt");
for(my $wavN = 1; $wavN <= $wavCount; $wavN++) {
    $faacLine .= "$wavN.wav ";
    my $title = $titles[$wavN-1];
    my $place = $times[$wavN-1];
    print CHAP "CHAPTER$wavN=$place\nCHAPTER${wavN}NAME=$title\n";
}
close(CHAP);
system("$faacLine  -t wav -c 2 -b 16 -r 44100 - | faac -b $bitrate -o '$outputTitle.m4a' --title '$outputTitle' --artist '$artist' --album '$album' --year $year -s " . (($image ne '') && (-f $image) ? "--cover-art '$image' " : '') . ' -');
for(my $wavN = 1; $wavN <= $wavCount; $wavN++) { unlink("$wavN.wav"); }
system("mp4chaps -i '$outputTitle.m4a'");
unlink("$outputTitle.chapters.txt");
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
    my $songN = 0;
    foreach my $segment (@$sequence) {
        $totalSegments++;
        my $msTarget = $segment->{'seconds'} * 1000;
        my $ms = 0;
        my $minPace = $segment->{'inMin'};
        my $maxPace = $segment->{'inMax'};
        my $startPace = $segment->{'outStart'};
        my $finishPace = $segment->{'outFinish'};
        my @parts = ();
        my $paceRange = ($startPace eq $finishPace) ? 0 : $finishPace - $startPace;
        while ($ms < $msTarget) {
            my $song = nextSongForPace($minPace, $maxPace, $songs);
            bail("Ran out of songs for pace $minPace-$maxPace, $totalSegments @ " . formatMS($ms)) unless($song);
            $song->{'tempo'} = ($startPace eq '*') ? 1 : ($startPace + (($ms / $msTarget) * $paceRange)) / $song->{'pace'};
            $ms += $song->{'ms'} / $song->{'tempo'};
            push @parts, $song;
        }
        my $scale = $msTarget / $ms;
        foreach my $part (@parts) {
            $songN++;
            $part->{'cut'} = int(($part->{'ms'} + ($songN > 1 ? $overlap : 0)) * $scale);
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