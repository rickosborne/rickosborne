#! perl
$| = 1;

use Data::Dumper;
use Cwd;
use MP3::Info;
use strict;

my $cwd = getcwd();
my $d = shift(@ARGV) or usage();
my $pod = shift(@ARGV) or usage();
chdir($d) or usage();
my @files = <*.*>;

my @discs = ();

foreach my $file (sort(@files)) {
	next unless($file =~ /[.]([^.]+)$/);
	my $ext = lc($1);
	next unless($ext eq 'mp3');
	processDisc($file, \@discs);
	makepods(\@discs, $pod);
} # foreach file

chdir($cwd);

exit(0);

sub usage {
	print<<__USAGE__;
Usage: $0 DIR PODFILE
__USAGE__
	exit(-1);
} # usage

sub processDisc($,$) {
	my ($discfile, $discsref) = @_;
	my $discnum = 0;
	my $ret = 0;
	if($discnum =~ /(\d+)( of \d+)?[.]mp3$/i) { $discnum = int($1); }
	print "Disc: $discfile\n";
	my %disc = ();
	$disc{'AUDIO'} = $discfile;
	unless(-f $discfile) {
		print "\tMissing audio file: $discfile\n";
		return(0);
	} # unless file exists
	my $mp3info = get_mp3info($discfile);
	$disc{'TIME'} = $mp3info->{'SECS'};
	push(@{$discsref}, \%disc);
	return($ret);
} # processdisc

sub index2secs($) {
	my ($idx) = @_;
	my ($m, $s, $ms) = split(':', $idx);
	return (int($m) * 60) + int($s) + (int($ms) * 0.01);
} # index2secs

sub secs2index($) {
	my ($secs) = @_;
	my ($h, $m, $s, $ms) = (0, 0, 0, 0);
	$ms = int(($secs - int($secs)) * 100);
	$secs = int($secs);
	$s = $secs % 60;
	$secs = int($secs / 60);
	$m = $secs % 60;
	$h = int($secs / 60);
	return leadzero($h) . ':' . leadzero($m) . ':' . leadzero($s) . '.' . leadzero($ms);
} # secs2index

sub leadzero($) {
	my ($n) = @_;
	return($n > 9 ? $n : '0' . $n);
} # leadzero

sub makepods($) {
	my ($discsref, $podfile) = @_;
	open(POD,">$podfile") or die($!);
	my $n = 0;
	my $t = 0;
	my $disccount = scalar(@{$discsref});
	print POD<<__PODHEAD__;
[Podcast]
basename=
audiofile=
artwork=
;imgwidth=
;imgheight=
editpointcount=$disccount

[metadata]
©gen=Audiobooks
©nam=
©ART=
©alb=
catg=music
©day=&today

__PODHEAD__
	my $discnum = 0;
	foreach my $disc (@{$discsref}) {
		my $tn = 0;
		$discnum++;
		my $discstart = secs2index($t);
		print POD "[Editpoint_$discnum]\nstart=$discstart\nchapter=Disc $discnum\n\n";
		$t += $disc->{'TIME'};
	} # foreach disc
	close(pod);
} # makepods