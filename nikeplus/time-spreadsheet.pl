#!/usr/bin/perl -w

use ODF::lpOD qw(CONTENT META);
use XML::Twig;
use Data::Dumper;
use IO::File;
use strict;

my $longestRun = 0;
my %data = ();

my $fh = IO::File->new("nikeplus.ods", "w");
#my $doc = odf_new_document('spreadsheet');
#my $content = $doc->get_part(CONTENT);
#my $meta = $doc->get_part(META);

my @volumes = </Volumes/*>;
foreach my $volume (sort @volumes) {
    next unless(-d $volume);
    my $empedPath = "$volume/iPod_Control/Device/Trainer/Workouts/Empeds";
    next unless(-d $empedPath);
    print "Scanning volume " . fname($volume) . "\n";
    my @chips = <"$empedPath"/*>;
    foreach my $chip (sort @chips) {
	next unless(-d $chip);
	my $syncPath = "$chip/synched";
	next unless(-d $syncPath);
	my $chipName = fname($chip);
	print "    Loading chip $chipName\n";
	my @runs = <"$syncPath"/*.xml>;
	foreach my $run (sort (@runs)) {
	    # next if(scalar(keys %data) > 0);
	    next unless(-f $run);
	    my $runName = fname($run);
	    next unless($runName =~ /^(20[01][0-9]\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])) ([01][0-9]|2[0-3]);[0-5][0-9];[0-5][0-9]\.xml$/);
	    my $runTitle = $1;
	    print "        Importing $runTitle\n";
	    XML::Twig->new(
		twig_handlers => {
		    'extendedDataList/extendedData' => sub {
			my ($tw, $el) = @_;
			my @points = split(/,\s+/, $el->text_only);
			my $pointCount = scalar(@points);
			print "Found $pointCount points.\n";
			unless(defined($data{$runTitle}) && (scalar(@{$data{$runTitle}}) > $pointCount)) {
			    @{$data{$runTitle}} = @points;
			}
			$longestRun = ($longestRun > $pointCount) ? $longestRun : $pointCount;
		    }
		}
	    )->parsefile($run);
	}
    }
}

foreach my $title (keys %data) {
    delete($data{$title}) unless(scalar(@{$data{$title}}) > 90); # 15 minutes
}

# print Dumper(\%data);

print "Longest run: $longestRun\n";

open(OUT,">nikeplus.csv");
print OUT '"Time (s)","Time (m)","Time (h)"';
my @titles = sort { $b cmp $a } keys %data;
foreach my $title (@titles) {
    print OUT ",\"$title\"";
}
print OUT "\n";
for(my $point = 0; $point < $longestRun; $point++) {
    my $times = $point * 10;
    my $timem = int(10000 * ($times / 60)) / 10000;
    my $timeh = int(1000000 * ($times / 3600)) / 1000000;
    print OUT "$times,$timem,$timeh";
    foreach my $title (@titles) {
	print OUT ",";
	if (scalar(@{$data{$title}}) > $point) {
	    print OUT @{$data{$title}}[$point];
	}
    }
    print OUT "\n";
}
close(OUT);


sub fname {
    my ($path) = @_;
    return (split('/', $path))[-1];
}