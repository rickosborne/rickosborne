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

GetOptions(
    'library=s' => \$libraryPath,
    'mix=s'     => \$mix,
    'out=s'     => \$outputPath,
    'verbose'   => \$verbose
);

my @sequence = sequenceFromMix($mix);
my $songCache = cacheSongsForSequence(\@sequence);
print Dumper(\@sequence);

exit(0);

sub cacheSongsForSequence {
    my (@sequence) = @_;
    my %cache;
    foreach my $segment (@sequence) {
        my $key = $segment->{'inStart'} . '-' . $segment->{'inFinish'};
        debug("Key: $key");
    }
    return \%cache;
}

sub getLibrary {
    unless ($library) {
        $library = Mac::iTunes::Library::XML->parse($libraryPath);
    }
    return $library;
} # getLibrary

sub getSongsForPaceRange {
    my $library = getLibrary();
    my %items = $library->items();
    while (my ($artist, $artistSongs) = each %items) {
        while (my ($songName, $artistSongItems) = each %$artistSongs) {
            foreach my $item (@$artistSongItems) {
                print $item->name(), ":", $item->bpm(), "\n";
            }
        }
    }
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
            'inStart'   => '*',
            'inFinish'  => '*',
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
            ($stats{'inStart'}, $stats{'inFinish'}) = pacesFromMix($inPace);
            if ($stats{'inStart'} eq $stats{'inFinish'}) {
                debug("  In: $stats{'inStart'}");
            } else {
                debug("  In: $stats{'inStart'}-$stats{'inFinish'}");
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