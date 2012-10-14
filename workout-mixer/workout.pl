#! perl -w

use Getopt::Long;
use Data::Dumper;
use Mac::iTunes::Library::XML;
use strict;

my $libraryPath = $ENV{'HOME'} . '/Music/iTunes/iTunes Music Library.xml';
my $mix = '30'; # '5@130-150:140-150;20@150-165:160;5@130-150:150-140'
my $outputPath = 'workout.mp3';
my $verbose = '';
my $library;
my $songFilter = '';
my $cutoff = 15;

GetOptions(
    'library=s' => \$libraryPath,
    'mix=s'     => \$mix,
    'out=s'     => \$outputPath,
    'filter=s'  => \$songFilter,
    'cutoff=i'  => \$cutoff,  
    'verbose'   => \$verbose
);

my @sequence = sequenceFromMix($mix);
# print Dumper(\@sequence);
my $songCache = cacheSongsForSequence(\@sequence, $songFilter);
# print Dumper($songCache);
my $playlist = buildPlaylist(\@sequence, $songCache);
print Dumper($playlist);
exit(0);

sub buildPlaylist {
    my ($sequence, $songs) = @_;
    my @playlist = ();
    foreach my $segment (@$sequence) {
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
            $song->{'tempo'} = ($startPace eq '*') ? 1 : ($startPace + (($ms / $msTarget) * $paceRange)) / $song->{'pace'};
            $ms += $song->{'ms'} * $song->{'tempo'};
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
    bail("Ran out of songs for pace $key") unless($song);
    return $song;
} # nextSongForPace

sub cacheSongsForSequence {
    my ($sequence, $songFilter) = @_;
    my %cache;
    foreach my $segment (@$sequence) {
        my $key = $segment->{'inMin'} . '-' . $segment->{'inMax'};
        unless (defined($cache{$key})) {
            debug("Songs for pace: $key");
            my $songs = getSongsForPaceRange($segment->{'inMin'}, $segment->{'inMax'}, $songFilter);
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
    my ($song, $filter) = @_;
    return (($song->album() =~ /$filter/i)
     || ($song->name() =~ /$filter/i)
     || ($song->artist() =~ /$filter/i));
}

sub getSongsForPaceRange {
    my ($minPace, $maxPace, $songFilter) = @_;
    my $library = getLibrary();
    my %items = $library->items();
    my @songs = ();
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
                next unless(-f $path);
                next unless(($songFilter eq '') || filterSong($item, $songFilter));
                next unless($cutoff * 60000 >= $ms);
                my %song = (
                    'artist' => $item->artist(),
                    'title'  => $item->name(),
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