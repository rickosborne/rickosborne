#! perl
$| = 1;

use Data::Dumper;
use Cwd;
use MP3::Info;
use Audio::Cuefile::Parser;
use strict;

my $cwd = getcwd();
my $d = shift(@ARGV) or usage();
my $chaps = shift(@ARGV) or usage();
chdir($d) or usage();
my @files = <*.*>;

my @cues = ();

foreach my $file (sort(@files)) {
	next unless($file =~ /[.]([^.]+)$/);
	my $ext = lc($1);
	next unless($ext eq 'cue');
	processCue($file, \@cues);
	makeChapters(\@cues, $chaps);
} # foreach file

chdir($cwd);

exit(0);

sub usage {
	print<<__USAGE__;
Usage: $0 DIR CHAPTERFILE
__USAGE__
	exit(-1);
} # usage

sub processCue($,$) {
	my ($cuefile, $cuesref) = @_;
	my $ret = 0;
	print "Cue: $cuefile\n";
	my $cue = Audio::Cuefile::Parser->new($cuefile);
	my $mp3file = $cue->file;
	my %disc = ();
	$disc{'CUE'} = $cuefile;
	$disc{'AUDIO'} = $mp3file;
	$disc{'TITLE'} = $cue->title;
	@{$disc{'TRACKS'}} = ();
	unless(-f $mp3file) {
		print "\tMissing audio file: $mp3file\n";
		return(0);
	} # unless file exists
	my $mp3info = get_mp3info($mp3file);
	$disc{'TIME'} = $mp3info->{'SECS'};
	foreach my $track ($cue->tracks) {
		# track-> position index performer title
		push(@{$disc{'TRACKS'}}, [ index2secs($track->index), $track->title ]);
	} # foreach track
	push(@{$cuesref}, \%disc);
	return($ret);
} # processCue

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

sub makeChapters($) {
	my ($cuesref, $chapfile) = @_;
	open(CHAP,">$chapfile") or die($!);
	my $n = 0;
	my $t = 0;
	foreach my $cue (@{$cuesref}) {
		my $tn = 0;
		foreach my $track (@{$cue->{'TRACKS'}}) {
			$n++;
			$tn++;
			print CHAP 'CHAPTER' . $n . '=' . secs2index($t + $track->[0]) . "\n";
			print CHAP 'CHAPTER' . $n . 'NAME=' . $track->[1] . "\n";
		} # foreach track
		$t += $cue->{'TIME'};
	} # foreach cue
	close(CHAP);
} # makeChapters