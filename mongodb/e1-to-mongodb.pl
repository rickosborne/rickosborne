#!/opt/local/bin/perl -w
use Data::Dumper;
use DateTime;
use MongoDB;
use strict;

my $inSpecPath = shift(@ARGV) || usage();
my $inDataPath = shift(@ARGV) || usage();
my $pkSuffixes = lc(shift(@ARGV)) || usage();
my $mongoDbName = shift(@ARGV) || usage();
my $mongoCollection = shift(@ARGV) || usage();

my %spec = readSpec($inSpecPath);
print Dumper(\%spec);
my $prefix = lc(substr((keys(%spec))[0], 0, 2));
my @pks = split(',', $pkSuffixes);

my $mongo = MongoDB::Connection->new();
my $mdb   = $mongo->get_database($mongoDbName);
my $mco   = $mdb->get_collection($mongoCollection);

open(DATA, "<$inDataPath") or die("No such data file $inDataPath");
my $line = <DATA>;
my @cols = readDataHeader($line);
my $rowNum = 0;
if ($cols[0] eq 'Row #') {
    shift(@cols);
    $rowNum = 1;
}
while (!eof(DATA)) {
    $line = <DATA>;
    chomp($line);
    my @data = split("\t", $line);
    shift(@data) if($rowNum);
    my %doc = ();
    foreach my $col (@cols) {
	my $val = trim(shift(@data));
	my $info = $spec{$col};
	my $type = $info->{'type'};
	if (!defined($type)) {
	    print "Undefined type for '$col'\n";
	    print Dumper($info);
	    die();
	} elsif ($type eq 'NUMERIC') {
	    if ($val =~ /^-?\d+(\.\d+)?$/) {
		my $prec = $info->{'prec'};
		if (defined($prec) && ($prec > 0)) {
		#    my $mult = 10 ** $prec;
		#    $val = int($val * $mult) / $mult;
		    $val = $val * 1.0;
		} else {
		    $val = int($val);
		}
	    } else {
		$val = undef;
	    }
	} elsif (($type eq 'VARCHAR') or ($type eq 'CHAR')) {
	    # no-op
	} elsif ($type eq 'DATE') {
	    if ($val =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
		$val = DateTime->new('year' => $1, 'month' => $2, 'day' => $3, 'hour' => $4, 'minute' => $5, 'second' => $6);
	    } elsif ($val =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
		$val = DateTime->new('year' => $1, 'month' => $2, 'day' => $3);
	    } else {
		$val = undef;
	    }
	} else {
	    die("Unknown data type $type for column $col");
	}
	if (defined($val) && ($val ne '')) {
	    $doc{lc(substr($col, 2))} = $val;
	}
    } # foreach
    my $id = makeID(\%doc);
    $doc{'_id'} = $id;
    my $cur = $mco->query({ '_id' => $id });
    if (my $rec = $cur->next) {
	print "Updating: $id\n";
	$mco->update({ '_id' => $id }, { '$set' => \%doc });
    } else {
	print "Inserting: $id\n";
	$mco->insert(\%doc);
	# print Dumper(\%doc);
	# exit(0);
    }
} # while
close(DATA);

exit(0);

sub makeID {
    my ($data) = @_;
    my $id = $prefix;
    foreach my $col (@pks) {
	my $val = $data->{$col};
	if (defined($val) && (ref($val) eq 'DateTime')) {
	    $val = (int($val->year - 1900) * 1000) + $val->day_of_year;
	}
	$id .= '-' . (defined($val) ? $val : '');
    }
    return $id;
}

sub readDataHeader {
    my ($head) = @_;
    chomp($head);
    my @cols = split("\t", $head);
    return @cols;
} # readDataHeader

sub readSpec {
    my ($path) = @_;
    my %spec = ();
    open(INSPEC, "<$path") or die("Couldn't read spec file: $path");
    while (!eof(INSPEC)) {
	my $line = <INSPEC>;
	chomp($line);
	my ($name, $type, $dec, $prec, $isn, $human) = split("\t", $line);
	$dec = trim($dec);
	$prec = trim($prec);
	$dec = ($dec eq '') ? undef : int($dec);
	$prec = ($prec eq '') ? undef : int($prec);
	%{$spec{$name}} = (
	    'type' => trim($type),
	    'dec'  => $dec,
	    'prec' => $prec,
	    'null' => trim($isn),
	    'name' => trim($human)
	);
    } # while
    close(INSPEC);
    return %spec;
} # readSpec

sub trim {
    my ($s) = @_;
    if (defined($s)) {
	$s =~ s/^\s+|\s+$//g;
    }
    return $s;
}

sub usage {
    print<<__USAGE__;
Usage: e1-to-mongodb.pl inTableSpec inTableData pk dbname collection
__USAGE__
    exit(-1);
}