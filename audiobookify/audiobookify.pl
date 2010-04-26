#!/usr/bin/perl
$| = 1;

use Data::Dumper;
use Cwd;
use File::Spec;
use MP3::Info;
use MP3::Tag;
use Getopt::Long;
use POSIX;
use strict;

my $cwd = getcwd();
my $apps = "";
my $ssa = "c:\\program files\\slideshow assembler\\ssa.exe";
my @files = sort(<*.mp3>);
my $maxseconds = 60 * 60 * 5.5;
my @images = sort(<*.jpg>);
my $cover = pop(@images);
my $margin = 1.1;
my @splitats = ();
my $performer = '';
my $noempty = 0;
my $skipre = '';
my $quality = 80;
GetOptions(
	"margin=f"    => \$margin,
	"splits=s"    => \@splitats,
	"performer=s" => \$performer,
	"noempty=i"   => \$noempty,
	"skipre=s"    => \$skipre,
	"quality=f"   => \$quality
);
@splitats = split(',', join(',', @splitats));

my %titles  = ();
my %artists = ();
my %albums  = ();
my %years   = ();
my $seconds = 0;
my @tracks  = ();
my $trackcount = 0;

foreach my $file (@files) {
	my $mp3info = get_mp3info($file);
	my $tag = MP3::Tag->new($file);
	my %track = ();
	push(@tracks, \%track);
	$trackcount++;
	$track{'FILE'}  = $file;
	$track{'SECS'}  = $mp3info->{'SECS'};
	$track{'TITLE'} = $tag->title() || '';
	$track{'ORDER'} = $trackcount;
	if($tag->year() ne '')   { $years{$tag->year()}++; }
	if($tag->title() ne '')  { $titles{$tag->title()}++; }
	if($tag->artist() ne '') { $artists{$tag->artist()}++; }
	if($tag->album() ne '')  { $albums{$tag->album()}++; }
	$seconds += $mp3info->{'SECS'};
	$track{'SKIP'} = (($noempty && ($track{'TITLE'} eq '')) || (($skipre ne '') && ($track{'TITLE'} =~ /$skipre/i)));
} # foreach file

my $album  = (sort { $albums{$b} <=> $albums{$a} } keys %albums)[0] or '';
my $artist = (sort { $artists{$b} <=> $artists{$a} } keys %artists)[0] or '';
my $year   = (sort { $years{$b} <=> $years{$a} } keys %years)[0] or '';
my $duration = secs2index($seconds);
my $splitcount = POSIX::ceil($seconds / $maxseconds);
push(@splitats, $trackcount+1) if(scalar(@splitats));
$splitcount = scalar(@splitats) if(scalar(@splitats));
my $targetseconds = POSIX::ceil($seconds / $splitcount) * $margin;
my $targetdur = secs2index($targetseconds);

my @dirs = File::Spec->splitdir($cwd);
my $parentdir = pop(@dirs);
if($parentdir =~ /^(.+?)\s+\((\d+)\)\s+(.+?)$/) {
	$artist = $1;
	$year = $2;
	$album = $3;
}

print "Artist:\t$artist\nAlbum:\t$album\nYear:\t$year\nTime:\t$duration ($seconds)\nTracks:\t$trackcount\nFiles:\t$splitcount\nSplits:\t$targetdur ($targetseconds)\n" . ($noempty ? "No Empties\n" : "");

my @splits = ( []  );
my $splitlength = 0;
my @counts = ( 0 );

if(scalar(@splitats) > 1) {
	my $tracknum = 0;
	foreach my $track (@tracks) {
		$tracknum++;
		if($tracknum == $splitats[0]) {
			shift(@splitats);
			push(@splits,[]);
			push(@counts, 0);
		}
		push(@{$splits[$#splits]}, $track);
		$counts[$#counts]++ unless($track->{'SKIP'});
	}
} else {
	foreach my $track (@tracks) {
		# print "Length: $splitlength\n";
		$splitlength += $track->{'SECS'};
		if($splitlength > $targetseconds) {
			# print "$splitlength gt $targetseconds\n";
			$splitlength = $track->{'SECS'};
			push(@splits, []);
			push(@counts, 0);
		}
		push(@{$splits[$#splits]}, $track);
		$counts[$#counts]++ unless($track->{'SKIP'});
	}
}

# print Dumper(\@splits);

my $splitnum = 0;
my $splitcount = scalar(@splits);
my $realnum = 0;

open(BAT1,">Encode $parentdir.sh");
# print BAT1 "\@echo off\n";
# open(BAT2,">Tag $parentdir.sh");
# print BAT2 "\@echo off\n";

foreach my $part (@splits) {
	$splitnum++;
	my $partname = $parentdir . formatPart($splitnum, $splitcount);
	my $partnamees = escapeSingle($partname);
	my $safealbum = escapeSingle($album);
	# $safealbum =~ s/[^A-Za-z0-9 ]//g;
	my $parttitle = $album . formatPart($splitnum, $splitcount);
	print "\n$partname\n";
	print BAT1 qq!madplay -q -o wave:- !;
	open(CHAP,">$partname.chapters.txt");
	open(POD,">$parttitle.pod");
	open(CSV,">$parttitle.csv");
	# my $chapcount = scalar(@{$part});
	my $chapcount = shift(@counts);
	print POD<<__PODHEAD__;
[Podcast]
basename=$parttitle
audiofile=$partname.m4a
artwork=$cover
editpointcount=$chapcount

[metadata]
?gen=Audiobooks
?nam=$parttitle
?ART=$artist
?alb=$album
catg=music
?day=$year

__PODHEAD__
	my $tracknum = 0;
	my $offset = 0;
	foreach my $track (@{$part}) {
		my $title = $track->{'TITLE'};
		unless($title || $track->{'SKIP'}) { $title = 'Disc ' . $track->{'ORDER'}; }
		$tracknum++ unless($track->{'SKIP'});
		$realnum++;
		my $index = secs2index($offset);
		$offset += $track->{'SECS'};
		print "$realnum\t" . ($track->{'SKIP'} ? "\t" : "") . $title . "\t" . $track->{'FILE'} . "\t" . secs2index($track->{'SECS'}) . "\n";
		my $safefile = $track->{'FILE'};
		$safefile =~ s/'/'\\''/g;
		print BAT1 "'" . $safefile . "' ";
		unless($track->{'SKIP'}) {
			print CHAP "CHAPTER$tracknum=$index\nCHAPTER${tracknum}NAME=$title\n";
			print POD "[Editpoint_$tracknum]\nstart=$index\nchapter=$title\ntitle=$title\n\n";
			print CSV "$index,$title\n";
		}
	}
	close(CHAP);
	close(POD);
	close(CSV);
	my $safeartist = escapeSingle($artist);
	my $safeparttitle = escapeSingle($parttitle);
	my $safecover = escapeSingle($cover);
	print BAT1 qq! | faac -q $quality --artist '$safeartist' --title '$safeparttitle' --genre 'Audiobook' --album '$safealbum' ! . ($splitcount > 1 ? qq!--disc '$splitnum/$splitcount' ! : '') . qq! --year '$year' --cover-art '$safecover' -o '$partnamees.m4a' -\n!;
	print BAT1 qq!mp4chaps -i '$partnamees.m4a'\n!;
	print BAT1 qq!mv '$partnamees.m4a' '$partnamees.m4b'\n!;
	# print BAT2 qq!\n"$ssa" "$parttitle.pod"\n!;
	# print BAT2 qq!neroAacTag -meta:year="$year" -meta:album="$album" -meta:artist="$artist" -meta:title="$parttitle" -meta-user:Performer="$performer" -meta:genre=Audiobook -meta:totaltracks="$chapcount" -add-cover:front:"$cover" ! . ($splitcount > 1 ? qq!-meta:disc=$splitnum -meta:totaldiscs=$splitcount ! : '') . qq!"$parttitle.m4a"\n!;
	# print BAT2 qq!MP4Box -rem 3 -chap "$parttitle.chap" "$parttitle.m4a"\n!;
	# print BAT2 qq!mv "$parttitle.m4a" "$partname.m4b"\n!;
	print "\tTotal Time: " . secs2index($offset) . "\n";
}
print BAT1 qq!mv *.m4b ~/Audiobooks/\n!;
close(BAT1);
# close(BAT2);

system(qq!chmod +x 'Encode ! . escapeSingle($parentdir) . qq!.sh'!);

exit(0);

sub formatPart($,$) {
	my ($n, $x) = @_;
	if($x == 1) { return ""; }
	if(($x > 10) and ($n < 10)) { return " 0$n"; }
	return " $n";
}

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

sub escapeSingle($) {
	my ($s) = @_;
	$s =~ s/'/'\\''/g;
#	$s =~ s/\(/\\(/g;
#	$s =~ s/\)/\\)/g;
	return $s;
}
