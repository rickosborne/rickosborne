#!/opt/local/bin/perl -w
$| = 1;

use Data::Dumper;
use POSIX qw( ceil strftime );
use Cwd;
use File::Spec;
use File::Basename;
use MP3::Info;
use MP3::Tag;
use MP4::Info;
use Getopt::Long;
use Config::JSON;
use XML::RSS;
# use Term::Size::Any qw( chars );
use strict;

my $scriptDir = dirname(Cwd::abs_path(__FILE__));
my $configFile = $scriptDir . '/audiobookify.config.json';
my $config = (-f $configFile) ? Config::JSON->new($configFile) : Config::JSON->create($configFile);
my $isWin = ($^O =~ /mswin/i);
my $cwd = getcwd();
my $apps = $isWin ? "k:\\rick" : "";
my $ssa = config("bin/ssa", "ssa");
my $mp3wrap = config("bin/mp3wrap", "mp3wrap");
my $cmdCopy = ($isWin ? 'copy' : 'cp');
my $cmdMove = ($isWin ? 'move' : 'mv');
my @files = sort((<*.mp3>, <*.m4a>, <*.m4b>));
my $maxseconds = 60 * 60 * 4.25;
my @images = sort(<*.jpg>);  unless(scalar(@images)) { die "Need a cover image!"; }
my $cover = pop(@images);
my $margin = 1.05;
my @splitats = ();
my $performer = '';
my $noempty = 0;
my $skipre = '';
my $onlyre = '';
my $quality = 0;
my $bitrate = 0;
my $encodeQuality = '';
my $album = '';
my $artist = '';
my $year = '';
my $verbose = 0;
my $titleStrip = '';
# my ($termCols, $termRows) = chars();
my ($termCols, $termRows) = (80, 20);
my ($termTrack, $termTime) = (4, 12);
my $termVar = int(($termCols - ($termTrack + $termTime + 7)) / 2);
GetOptions(
	"margin=f"    => \$margin,
	"splits=s"    => \@splitats,
	"performer=s" => \$performer,
	"noempty=i"   => \$noempty,
	"verbose=i"   => \$verbose,
	"skipre=s"    => \$skipre,
	"onlyre=s"    => \$onlyre,
	"quality=f"   => \$quality,
	"bitrate=i"   => \$bitrate,
	"album=s"     => \$album,
	"artist=s"    => \$artist,
	"year=i"      => \$year,
	"stripre=s"   => \$titleStrip
);
@splitats = split(',', join(',', @splitats));
if (($quality == 0) and ($bitrate == 0)) { $bitrate = 48; }
if (($quality < 1) or ($quality > 100)) { $quality = 80; }
if ($bitrate > 0) { $encodeQuality = "-b $bitrate"; }
else { $encodeQuality = "-q $quality"; }

my %titles  = ();
my %artists = ();
my %albums  = ();
my %years   = ();
my $seconds = 0;
my @tracks  = ();
my $trackcount = 0;
my $maxTitle = 0;

foreach my $file (@files) {
	my $is3 = ($file =~ /\.mp3$/i);
	my $mp3info = $is3 ? get_mp3info($file) : get_mp4info($file);
	my $tag = $is3 ? MP3::Tag->new($file) : MP4::Info->new($file);
	my %track = ();
	push(@tracks, \%track);
	$trackcount++;
	$track{'FILE'}    = $file;
	$track{'SECS'}    = $mp3info->{'SECS'};
	$track{'TITLE'}   = $tag->title() || '';
	$track{'ORDER'}   = $trackcount;
	$track{'SIZE'}    = (-s $file);
	$track{'CHAPLEN'} = 0;
	if($tag->year() ne '')   { $years{$tag->year()}++; }
	if($tag->title() ne '')  { $titles{$tag->title()}++; }
	if($tag->artist() ne '') { $artists{$tag->artist()}++; }
	if($tag->album() ne '')  { $albums{$tag->album()}++; }
	$seconds += $mp3info->{'SECS'};
	$track{'SKIP'} = (($noempty && ($track{'TITLE'} eq '')) || (($skipre ne '') && ($track{'TITLE'} =~ /$skipre/i)) || (($onlyre ne '') && !($track{'TITLE'} =~ /$onlyre/i)));
	unless ($track{'SKIP'}) {
		my $titleLen = length($track{'TITLE'});
		$maxTitle = ($maxTitle > $titleLen ? $maxTitle : $titleLen);
	}
} # foreach file

$termVar = ($termVar > $maxTitle ? $maxTitle : $termVar);

my @dirs = File::Spec->splitdir($cwd);
my $parentdir = pop(@dirs);
if($parentdir =~ /^(.+?)\s+\((\d+)\)\s+(.+?)$/) {
	if ($artist eq '') { $artist = $1; }
	if ($year eq '')   { $year   = $2; }
	if ($album eq '')  { $album  = $3 };
}

if ($album eq '')  { $album  = (sort { $albums{$b} <=> $albums{$a} } keys %albums)[0] || ''; }
if ($artist eq '') { $artist = (sort { $artists{$b} <=> $artists{$a} } keys %artists)[0] || ''; }
if ($year eq '')   { $year   = (sort { $years{$b} <=> $years{$a} } keys %years)[0] || ''; }
my $duration = secs2index($seconds);
my $splitcount = POSIX::ceil($seconds / $maxseconds);
push(@splitats, $trackcount+1) if(scalar(@splitats));
$splitcount = scalar(@splitats) if(scalar(@splitats));
my $targetseconds = POSIX::ceil($seconds / $splitcount) * $margin;
my $targetdur = secs2index($targetseconds);
my %templateable = (
	'$artist' => urlsafe($artist),
	'$album' => urlsafe($album),
	'$year' => urlsafe($year)
);

print "Artist:\t$artist\nAlbum:\t$album\nYear:\t$year\nTime:\t$duration ($seconds)\nTracks:\t$trackcount\nFiles:\t$splitcount\nSplits:\t$targetdur ($targetseconds)\n" . ($noempty ? "No Empties\n" : "");

my $rssVersion = config('rss/version', '2.0');
my $rssLink = config('rss/link', 'http://rickosborne.org');
my $rssWebMaster = config('rss/webMaster', 'Rick Osborne');
my $rssBasePath = template(config('rss/basePath', 'http://example.com'));
my $rss = XML::RSS->new(version => $rssVersion);
my $rssDate = pubDate();

$rss->add_module(prefix => 'blogChannel', uri => 'http://backend.userland.com/blogChannelModule');
$rss->add_module(prefix => 'itunes', uri => 'http://www.itunes.com/dtds/podcast-1.0.dtd');
$rss->channel(
	title => "$artist ($year) $album",
	link => $rssLink,
	description => "$artist ($year) $album" . ($performer ne '' ? ", read by $performer" : ''),
	language => 'en-us',
	copyright => "Copyright $year $artist",
	pubDate => $rssDate,
	lastBuildDate => $rssDate,
	webMaster => $rssWebMaster,
	itunes => {
		image => "$rssBasePath/$cover",
		author => $artist,
		complete => 'yes',
		owner => {
			name => $rssWebMaster
		}
	}
);
$rss->image(
	title => "$artist ($year) $album",
	url => "$rssBasePath/$cover",
	link => $rssLink
);

my @splits = ( []  );
my @counts = ( 0 );

if(scalar(@splitats) > 1) {
	splitTracksAtGivens(\@tracks, \@splits, \@counts, \@splitats);
} else {
	splitTracksAtChapters(\@tracks, \@splits, \@counts);
} # if split

# print Dumper(\@splits);

my $splitnum = 0;
my $realnum = 0;
$splitcount = scalar(@splits);

if($isWin) {
	open(BAT0,">Encode $parentdir.bat");
	print BAT0 "\@echo off\n\n"
} else {
	open(BAT1,">Encode $parentdir.sh");
}

unlink(<*.pod>);
unlink(<*.chapters.txt>);
unlink(<*.chap>);
unlink(<*.csv>);

foreach my $part (@splits) {
	$splitnum++;
	my $partname = $parentdir . formatPart($splitnum, $splitcount);
	my $partnamees = escapeSingle($partname);
	my $safealbum = escapeSingle($album);
	my $parttitle = $album . formatPart($splitnum, $splitcount);
	my $chapcount = shift(@counts);
	print "\n$partname\n";
	if ($isWin) {
		open(BAT1,">Encode $partname.bat");
		print BAT1 qq!\@echo off\ncall k:\\rick\\Source\\Audiobookify\\cmdrenice.bat\n\n"$apps\\madplay.exe" -o wave:- !;
		print BAT0 qq!start /belownormal cmd.exe /c "Encode $partname.bat"\n!;
		open(CHAP,">$parttitle.chap");
		open(POD,">$parttitle.pod");
		open(CSV,">$parttitle.csv");
		print POD<<__PODHEAD__;
[Podcast]
basename=$parttitle
audiofile=$partname.m4a
artwork=$cover
editpointcount=$chapcount

[metadata]
©gen=Audiobooks
©nam=$parttitle
©ART=$artist
©alb=$album
catg=music
©day=$year

__PODHEAD__
	} else {
		print BAT1 qq!part${splitnum}() {\n\tmadplay -q -o wave:- !;
		open(CHAP,">$partname.chapters.txt");
	}
	my $tracknum = 0;
	my $offset = 0;
	my $skippedLen = 0;
	my $lastOffset = 0;
	my $title = '';
	foreach my $track (@{$part}) {
		$title = $track->{'TITLE'};
		$title =~ s/$titleStrip// if ($titleStrip);
		unless($title || $track->{'SKIP'}) { $title = 'Disc ' . $track->{'ORDER'}; }
		$tracknum++ unless($track->{'SKIP'});
		$realnum++;
		my $index = secs2index($offset);
		$offset += $track->{'SECS'};
		if ($verbose || !$track->{'SKIP'}) {
			print lpad($realnum, $termTrack) . "  " . ($track->{'SKIP'} ? "     " . rpad($title, $termVar - 5) : rpad($title, $termVar)) . "  " . ($verbose ? rpad($track->{'FILE'}, $termVar) . "  " : "") . rpad(secs2index($verbose ? $track->{'SECS'} : $track->{'CHAPLEN'}), $termTime) . "\n";
			$lastOffset = $offset;
		}
		my $safefile = $track->{'FILE'};
		if ($isWin) {
			$safefile =~ s/"/""/g;
			print BAT1 '"' . $safefile . '" ';
		} else {
			# $safefile =~ s/'/'\\''/g;
			# $safefile =~ s/"/\\"/g;
			print BAT1 bashEscapeSingle($safefile) . ' ';
		}
		unless($track->{'SKIP'}) {
			if ($isWin) {
				print POD "[Editpoint_$tracknum]\nstart=$index\nchapter=$title\ntitle=$title\n\n";
				print CSV "$index,$title\n";
			}
			print CHAP "CHAPTER$tracknum=$index\nCHAPTER${tracknum}NAME=$title\n";
			$rss->add_item(
				title => "$tracknum: $title",
				description => "$title",
				permaLink => "$rssBasePath/$safefile",
				pubDate => pubDate($tracknum),
				enclosure => {
					url => "$rssBasePath/$safefile",
					length => $track->{'SIZE'},
					type => $safefile =~ /\.mp3$/i ? 'audio/mp3' : 'audio/mp4'
				},
				itunes => {
					summary => "$artist ($year) $album\n\n$tracknum: $title",
					duration => duration($track->{'SECS'})
				}
			);
		}
	}
	if (($performer ne '') && ($splitnum == $splitcount)) {
		$tracknum++;
		my $index = secs2index($offset - 1);
		print CHAP "CHAPTER$tracknum=$index\nCHAPTER${tracknum}NAME=Read by $performer\n";
		if ($isWin) {
			print POD "[Editpoint_$tracknum]\nstart=$index\nchapter=Read by $performer\ntitle=Read by $performer\n\n";
			print CSV "$index,Read by $performer\n";
		}
	}
	close(CHAP);
	if ($isWin) {
		close(POD);
		close(CSV);
	}
	my $safeartist = escapeSingle($artist);
	my $safeparttitle = escapeSingle($parttitle);
	my $safecover = escapeSingle($cover);
	if ($isWin) {
		print BAT1 qq! | "$apps\\faac.exe" $encodeQuality --artist "$safeartist" --title "$safeparttitle" --genre "Audiobook" --album "$safealbum" ! . ($splitcount > 1 ? qq!--track "$splitnum/$splitcount" ! : "") . qq! --year "$year" --cover-art "$safecover" -o "$partnamees.m4a" -\n!;
		print BAT1 qq!"$ssa" "$parttitle.pod"\n!;
		print BAT1 qq!"$apps\\neroAacTag.exe" -meta:year="$year" -meta:album="$album" -meta:artist="$artist" -meta:title="$parttitle" -meta-user:Performer="$performer" -meta:genre=Audiobook -add-cover:front:"$cover" ! . ($splitcount > 1 ? qq!-meta:track=$splitnum -meta:trackcount=$splitcount ! : '') . qq!"$parttitle.m4a"\n!;
		print BAT1 qq!"$apps\\MP4Box.exe" -rem 3 -chap "$parttitle.chap" "$parttitle.m4a"\n!;
		print BAT1 qq!move "$parttitle.m4a" "q:\\Audiobooks\\$partname.m4b"\n!;
		close(BAT1);
	} else {
		print BAT1 qq! | faac $encodeQuality --artist ! . bashEscapeSingle($artist) . ' --title ' . bashEscapeSingle($parttitle) . " --genre 'Audiobook' --album " . bashEscapeSingle($album) . ($splitcount > 1 ? qq! --track '$splitnum/$splitcount' ! : '') . ($performer eq "" ? "" : qq! --comment ! . bashEscapeSingle("Read by $performer")) . qq! --year '$year' --cover-art ! . bashEscapeSingle($safecover) . ' -o ' . bashEscapeSingle("$partname.m4a") . " -\n";
		print BAT1 qq!\tmp4chaps -i ! . bashEscapeSingle("$partname.m4a") . "\n";
		print BAT1 qq!\tmv ! . bashEscapeSingle("$partname.m4a") . " " . bashEscapeSingle("$partname.m4b") . "\n";
		print BAT1 qq!}\n!;
	}
	print "\tTotal Time: " . secs2index($offset) . "\n";
}

$rss->save('rss.xml');

if ($isWin) {
	close(BAT0);
} else {
	foreach my $part (1..$splitnum) {
		if ($part > 1) {
			print BAT1 ' & ';
		}
		print BAT1 qq!part${part}!;
	}
	print BAT1 qq!\nwait\nmv *.m4b ~/Audiobooks/\n!;
	close(BAT1);
	system(qq!chmod +x ! . bashEscapeSingle("Encode $parentdir.sh"));
	system(qq!chmod +x 'Faster Chapters.sh'!);
	system(qq!chmod +x 'Wrap Chapters.sh'!);
}

exit(0);

sub splitTracksAtGivens {
	my ($tracks, $splits, $counts, $splitats) = @_;
	my $tracknum = 0;
	my $lastNotSkipped;
	foreach my $track (@{$tracks}) {
		$tracknum++;
		if($tracknum == $splitats->[0]) {
			shift(@{$splitats});
			push(@{$splits},[]);
			push(@{$counts}, 0);
		}
		push(@{$splits->[-1]}, $track);
		unless($track->{'SKIP'}) {
			$counts->[-1]++;
			$lastNotSkipped = $track;
		}
		$lastNotSkipped->{'CHAPLEN'} += $track->{'SECS'};
	} # foreach track
} # splitTracksAtGivens

sub splitTracksAtChapters {
	my ($tracks, $splits, $counts) = @_;
	if($isWin) {
		open(WRAP,">Wrap Chapters.bat");
		print WRAP qq!\@echo off\nmkdir wrapped\n!;
	} else {
		open(WRAP,">Wrap Chapters.sh");
		print WRAP qq|#!/bin/sh\nmkdir wrapped\n|;
		open(FASTER,">Faster Chapters.sh");
		print FASTER qq{#!/bin/sh\nTEMPO="\$1"\nif [ -z "\$TEMPO" ] ; then\n\techo "Please provide a multiplier, such as 1.2"\n\texit -1\nfi\nif [ ! -d "notempo" ] ; then\n\tmkdir "notempo"\nfi\n};
	}
	my $chapterLength = 0;
	my $lastChapter = [];
	my @chapterLengths;
	my @chapterTracks;
	push(@chapterTracks, $lastChapter);
	# group tracks by chapter
	foreach my $track (@{$tracks}) {
		unless ($track->{'SKIP'}) {
			unless ($chapterLength == 0) {
				$lastChapter->[0]->{'CHAPLEN'} = $chapterLength;
				$lastChapter = [];
				push(@chapterTracks, $lastChapter);
				push(@chapterLengths, $chapterLength);
				$chapterLength = 0;
			} # unless no tracks yet
		} # unless a skippable track
		push(@{$lastChapter}, $track);
		$chapterLength += $track->{'SECS'};
	} # foreach track
	$lastChapter->[0]->{'CHAPLEN'} = $chapterLength;
	push(@chapterLengths, $chapterLength);
	# group chapters into files
	my ($splitLength, $newSplitLength, $origErr, $newErr) = (0, 0);
	my $chapterNum = 0;
	my $splitNum = 1;
	foreach my $chapter (@chapterTracks) {
		$chapterLength = shift(@chapterLengths);
		$newSplitLength = $splitLength + $chapterLength;
		$origErr = abs($targetseconds - $splitLength);
		$newErr = abs($targetseconds - $newSplitLength);
		$chapterNum++;
		if (($newSplitLength > $targetseconds) && (($splitLength > $maxseconds) || ($newErr > $origErr))) {
			$splitLength = $chapterLength;
			push(@{$splits}, []);
			push(@{$counts}, 0);
			$splitNum++;
		} else {
			$splitLength = $newSplitLength;
		}
		foreach my $track (@{$chapter}) {
			push(@{$splits->[-1]}, $track);
		}
		$counts->[-1]++;
		my $chapZero = substr("00$chapterNum", -2);
		my $safeTitle = bashEscapeSingle($chapter->[0]->{'TITLE'});
		if ($isWin) {
			$safeTitle = escapeSingle($chapter->[0]->{'TITLE'});
		}
		print FASTER qq!\necho "Adjusting tempo for $safeTitle"\nmadplay -q -o wave:- ! unless($isWin);
		if (scalar(@{$chapter}) == 1) {
			print WRAP $cmdCopy . ' ' . bashEscapeSingle($chapter->[0]->{'FILE'}) . qq! "$splitNum-${chapZero}_MP3WRAP.mp3"\n!;
			print FASTER ' ' . bashEscapeSingle($chapter->[0]->{'FILE'}) unless($isWin);
		} elsif (scalar(@{$chapter}) > 1) {
			print WRAP qq!$mp3wrap "$splitNum-$chapZero"!;
			foreach my $track (@{$chapter}) {
				print WRAP ' ' . bashEscapeSingle($track->{'FILE'});
				print FASTER ' ' . bashEscapeSingle($track->{'FILE'}) unless($isWin);
			}
			print WRAP "\n";
		}
		print FASTER qq! | sox --norm -t wav - "faster-$splitNum-$chapZero.mp3" tempo -s \$TEMPO\nid3v2 --song $safeTitle "faster-$splitNum-$chapZero.mp3"\n! unless($isWin);
		foreach my $track (@{$chapter}) {
			print WRAP $cmdMove . qq! ! . bashEscapeSingle($track->{'FILE'}) . qq! wrapped\n!;
			print FASTER $cmdMove . qq! ! . bashEscapeSingle($track->{'FILE'}) . qq! notempo\n! unless($isWin);
		}
		my $wrapFile = "$splitNum-${chapZero}.mp3";
		print WRAP $cmdMove . qq! "$splitNum-${chapZero}_MP3WRAP.mp3" "$wrapFile"\n!;
		if ($isWin) {
			print WRAP qq!"$apps\\tag.exe" --remove "$wrapFile"\n!;
			print WRAP qq!"$apps\\tag.exe" --title "$safeTitle" "$wrapFile"\n!;
		} else {
			print WRAP qq!id3v2 --delete-all ! . bashEscapeSingle($wrapFile) . "\n";
			print WRAP qq!id3v2 --song $safeTitle ! . bashEscapeSingle($wrapFile) . "\n";
		}
	} # foreach chapter
	print WRAP "$cmdMove Encode*.* wrapped\n$cmdMove *.csv wrapped\n$cmdMove *.pod wrapped\n";
	close(WRAP);
	close(FASTER) unless($isWin);
} # splitTracksAtChapters

sub formatPart {
	my ($n, $x) = @_;
	if($x == 1) { return ""; }
	if(($x > 10) and ($n < 10)) { return " 0$n"; }
	return " $n";
}

sub index2secs {
	my ($idx) = @_;
	my ($m, $s, $ms) = split(':', $idx);
	return (int($m) * 60) + int($s) + (int($ms) * 0.01);
} # index2secs

sub secs2index {
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

sub leadzero {
	my ($n) = @_;
	return($n > 9 ? $n : '0' . $n);
} # leadzero

sub bashEscapeSingle {
	my ($s) = @_;
	return($s) unless(defined($s));
	if (($s =~ /'/) and ($s =~ /"/)) {
		$s =~ s/'/'"'"'/g;
		return "'$s'";
	} elsif ($s =~ /'/) {
		return qq!"$s"!;
	}
	return "'$s'";
}

sub escapeSingle {
	my ($s) = @_;
	return($s) unless(defined($s));
	if ($isWin) {
		$s =~ s/"/""/g;
	} else {
		$s =~ s/"/\\"/g;
	}
#	$s =~ s/\(/\\(/g;
#	$s =~ s/\)/\\)/g;
	return $s;
} # escapeSingle

sub rpad {
	my ($s, $l) = @_;
	my $x = ' ' x $l;
	return substr($s . $x, 0, $l);
} # rpad

sub lpad {
	my ($s, $l) = @_;
	my $x = ' ' x $l;
	return substr($x . $s, 0 - $l);
} # lpad

sub config {
	my ($path, $default) = @_;
	my $result = $config->get($path);
	$result = defined($result) ? $result : $default;
	print "Config: $path = $result\n";
	return $result;
} # config

sub template {
	my ($before) = @_;
	my $after = $before;
	while (my ($key, $value) = each %templateable) {
		my $qk = quotemeta($key);
        $after =~ s/$qk/$value/g;
    }
	return $after;
} # template

sub urlsafe {
	my ($before) = @_;
	my $after = lc($before);
	$after =~ s/[^a-zA-Z0-9]+/-/g;
	return $after;
} # urlsafe

sub pubDate {
	my ($offset) = @_;
	my $base = time();
	if (defined($offset)) {
        $base -= scalar(@files);
		$base += $offset;
    }
	return strftime("%a, %d %b %Y %H:%M:%S %z", localtime($base));
} # pubDate

sub duration {
	my ($secs) = @_;
	my $dur = secs2index($secs);
	$dur =~ s/\..+$//;
	return $dur;
} # duration