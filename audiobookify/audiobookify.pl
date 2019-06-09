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
use Audio::Wav;
use Getopt::Long;
use Config::JSON;
use XML::RSS;
use JSON;
use DateTime;
use DateTime::TimeZone;
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
my @files = sort((<*.mp3>, <*.m4a>, <*.m4b>, <*.wav>));
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
my $month = '';
my $day = '';
my $verbose = 0;
my $titleStrip = '';
my $series = '';
my $grouping = '';
my $episode = '';
# my ($termCols, $termRows) = chars();
my ($termCols, $termRows) = (80, 20);
my ($termTrack, $termTime) = (4, 12);
my $termVar = int(($termCols - ($termTrack + $termTime + 7)) / 2);
my $timeZone = '';
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
	"stripre=s"   => \$titleStrip,
	"series=s"    => \$series,
	"grouping=s"  => \$grouping,
	"episode=s"   => \$episode,
	"timezone=s"  => \$timeZone,
);
@splitats = split(',', join(',', @splitats));
# if (($quality == 0) and ($bitrate == 0)) { $bitrate = 48; }
if (($quality < 1) or ($quality > 100)) { $quality = 80; }
if ($quality > 0) { $encodeQuality = "-q $quality"; }
elsif ($bitrate > 0) { $encodeQuality = "-b $bitrate"; }
else { $encodeQuality = ""; }
if (defined($timeZone) && ($timeZone ne '') && !DateTime::TimeZone->is_valid_name($timeZone)) {
    die("Invalid timezone: $timeZone\n");
}
if (!defined $timeZone || $timeZone eq '') { $timeZone = DateTime::TimeZone->new(name => 'local'); }

my %titles  = ();
my %artists = ();
my %albums  = ();
my %years   = ();
my $seconds = 0;
my @tracks  = ();
my $trackcount = 0;
my $maxTitle = 0;

foreach my $file (@files) {
	my $tag;
	my $secs;
	my $title;
	if ($file =~ /\.wav$/i) {
		my $wav = Audio::Wav->read($file);
		my $info = $wav->get_info();
		if (defined($info)) {
            $title = $info->{'name'} || '';
        }
		$secs = $wav->length_seconds();
    } else {
		my $is3 = ($file =~ /\.mp3$/i);
		my $mp3info = $is3 ? get_mp3info($file) : get_mp4info($file);
		$tag = $is3 ? MP3::Tag->new($file) : MP4::Info->new($file);
		if (defined($tag)) {
            $title = $tag->title;
        }
        
		$secs = $mp3info->{'SECS'} || 0;
	}
	my %track = ();
	push(@tracks, \%track);
	$trackcount++;
	$track{'FILE'}    = $file;
	$track{'SECS'}    = $secs || 0;
	$track{'TITLE'}   = defined $title ? $title || '' : '';
	$track{'ORDER'}   = $trackcount;
	$track{'SIZE'}    = (-s $file);
	$track{'CHAPLEN'} = 0;
	$track{'TITLE'} =~ s/$titleStrip//g if ($titleStrip);
	if (defined $tag) {
		if(defined $tag->year() && $tag->year() ne '')   { $years{$tag->year()}++; }
		if(defined $tag->title() && $tag->title() ne '')  { $titles{$tag->title()}++; }
		if(defined $tag->artist() && $tag->artist() ne '') { $artists{$tag->artist()}++; }
		if(defined $tag->album() && $tag->album() ne '')  { $albums{$tag->album()}++; }
    }
	die("File $file has no duration") if ($track{'SECS'} == 0);
    $seconds += $track{'SECS'};
	$track{'SKIP'} = (($noempty && ($track{'TITLE'} eq '')) || (($skipre ne '') && ($track{'TITLE'} =~ /$skipre/i)) || (($onlyre ne '') && !($track{'TITLE'} =~ /$onlyre/i)));
	unless ($track{'SKIP'}) {
		my $titleLen = length($track{'TITLE'});
		$maxTitle = ($maxTitle > $titleLen ? $maxTitle : $titleLen);
	}
} # foreach file

$termVar = ($termVar > $maxTitle ? $maxTitle : $termVar);

my @dirs = File::Spec->splitdir($cwd);
my $parentdir = pop(@dirs);
if($parentdir =~ /^(.+?)\s+\((\d+|\d+-\d+|\d+-\d+-\d+)\)\s+(.+?)(?:\s+\((.+?) #(\d+)\))?$/) {
	if ($artist eq '') { $artist = $1; }
	if ($year eq '')   { ($year, $month, $day) = split('-', $2); }
	if ($album eq '')  {
		$album  = $3;
	};
	if ($series eq '' && defined($4) && defined($5)) {
        $series = $4;
		$grouping = $4;
		$episode = $5;
    }
    if ($album =~ /^(.+?)\s+\(read by (.+?)\)$/) {
        $album = $1;
        $performer = $2;
    }
}

if ($album eq '')  { $album  = (sort { $albums{$b} <=> $albums{$a} } keys %albums)[0] || ''; }
if ($artist eq '') { $artist = (sort { $artists{$b} <=> $artists{$a} } keys %artists)[0] || ''; }
if ($year eq '')   { $year   = (sort { $years{$b} <=> $years{$a} } keys %years)[0] || ''; }
if ($month eq '') { $month = (localtime())[4] + 1; }
if ($day eq '') { $day = (localtime())[3]; }
my $baseDate = DateTime->new(year => $year || '', month => $month, day => $day, hour => 9, time_zone => $timeZone);
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

my $phpTemplate = <<__PHP_TEMPLATE__;
<?php
\$file = 'rss.xml';
header('Content-Type: text/xml; charset=UTF-8');
header('Content-Length: ' . filesize(\$file));
header('Content-Disposition: inline');
readfile(\$file);
__PHP_TEMPLATE__

print <<__DEBUG_CONFIG__;
Artist:   $artist
Album:    $album
Year:     $year
Month:    $month
Day:      $day
Time:     $duration ($seconds)
Tracks:   $trackcount
Files:    $splitcount
Splits:   $targetdur ($targetseconds)
No Empty: $noempty
Series:   $series
Grouping: $grouping
Episode:  $episode
TimeZone: $timeZone
__DEBUG_CONFIG__

my $rssVersion = config('rss/version', '2.0');
my $rssLink = config('rss/link', 'http://rickosborne.org');
my $rssWebMaster = config('rss/webMaster', 'Rick Osborne');
my $sshfsTmp = config('sshfs/tmp', 'sshtmp');
my $sshfsHost = config('sshfs/host', '');
my $sshfsBasePath = config('sshfs/basePath', '/var/www/example.com/media');
my $sshfsRssPath = template(config('sshfs/rssPath'), '$artist/$year/$album');
my $sshfsServer = config('sshfs/sftpServer', '');
my $sshfsCmd = config('sshfs/cmd', "sshfs '$sshfsHost:$sshfsBasePath' '$sshfsTmp'" . ($sshfsServer eq '' ? '' : " -o sftp_server='$sshfsServer'") . ' -o defer_permissions');
my $sshfsIndexFile = config('sshfs/index/file', 'index.php');
my $sshfsIndexContent = config('sshfs/index/content', $phpTemplate);
my $s3Bucket = config('s3/bucket', '');
my $s3Path = template(config('s3/path', '$artist/$year/$album'));
my $rssBasePath = template(config('rss/basePath', 'http://example.com'));
my $rssPublishPath = template(config('rss/publishPath', 'http://example.com'));
my $rss = XML::RSS->new(version => $rssVersion);
my $rssDate = pubDate(999);

$rss->add_module(prefix => 'blogChannel', uri => 'http://backend.userland.com/blogChannelModule');
$rss->add_module(prefix => 'itunes', uri => 'http://www.itunes.com/dtds/podcast-1.0.dtd');
$rss->channel(
	title => "$album by $artist ($year)",
	link => $rssLink,
	description => "$album by $artist ($year)" . ($series eq '' ? '' : (', ' . $series . ($episode eq '' ? '' : " book $episode"))) . ($performer ne '' ? ", read by $performer" : ''),
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
		},
		category => {
			text => "Arts",
			category => {
				text => "Literature"
			}
		},
		summary => "$album by $artist ($year)" . ($series eq '' ? '' : (', ' . $series . ($episode eq '' ? '' : " book $episode"))) . ($performer ne '' ? ", read by $performer" : ''),
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
	open(TOS3,">Publish.sh");
	open(SSHINDEX, ">ssh-index.txt");
	print SSHINDEX $sshfsIndexContent;
	close(SSHINDEX);
	print TOS3<<__PUBLISH_HEAD__;
#!/bin/sh
S3_BUCKET=$s3Bucket
S3_PATH=s3://\${S3_BUCKET}/$s3Path
#SSHFS_TMP=$sshfsTmp
#SSHFS_PATH=$sshfsRssPath
#SSHFS_WORK="\${SSHFS_TMP}/\${SSHFS_PATH}"
# SSH
#if [ -d "\${SSHFS_TMP}" ]; then
#  umount "\${SSHFS_TMP}"
#  echo "Removing \${SSHFS_TMP}"
#  # rm -R "\${SSHFS_TMP}"
#fi
#mkdir -p "\${SSHFS_TMP}"
#$sshfsCmd
#mkdir -p "\${SSHFS_WORK}"
#cp rss.xml "\${SSHFS_WORK}/rss.xml"
#cp ssh-index.txt "\${SSHFS_WORK}/$sshfsIndexFile"
#umount "\${SSHFS_TMP}"
# S3
send_to_s3() {
	FILE_NAME=\$1
	MIME_TYPE=\$2
	s3cmd sync "\${FILE_NAME}" "\${S3_PATH}/" -m "\${MIME_TYPE}" -P --signature-v2 --rr
}
send_to_s3 "$cover" 'image/jpeg'
send_to_s3 rss.xml 'application/rss+xml'
__PUBLISH_HEAD__
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
		my $mimeType = ($safefile =~ /\.mp3$/i ? 'audio/mp3' : 'audio/mp4');
		if ($isWin) {
			$safefile =~ s/"/""/g;
			print BAT1 '"' . $safefile . '" ';
		} else {
			# $safefile =~ s/'/'\\''/g;
			# $safefile =~ s/"/\\"/g;
			print BAT1 bashEscapeSingle($safefile) . ' ';
			print TOS3 "send_to_s3 " . bashEscapeSingle($safefile) . " $mimeType\n";
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
					type => $mimeType
				},
				itunes => {
					summary => "Episode $tracknum: $title\n$artist ($year) $album\n" . ($series eq '' ? '' : $series . ($episode eq '' ? '' : " book $episode\n")) . ($performer ne '' ? "\nRead by $performer" : ''),
					duration => duration($track->{'SECS'}),
					author => $artist,
					subtitle => "$album part $tracknum",
					image => "$rssBasePath/$cover",
					order => $episode ne '' ? $episode * 1000 + $tracknum : $tracknum
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
	print TOS3 qq!#rm -R "\${SSHFS_TMP}"\necho "Published to: $rssPublishPath"!;
	close(TOS3);
	system(qq!chmod +x ! . bashEscapeSingle("Encode $parentdir.sh"));
	system(qq!chmod +x 'Faster Chapters.sh'!);
	system(qq!chmod +x 'MP4 Wrap Chapters.sh'!);
	system(qq!chmod +x 'Wrap Chapters.sh'!);
	system(qq!chmod +x 'Publish.sh'!);
	system(qq!chmod +x 'Retag.sh'!);
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
		my $wrapHead = <<__WRAP_HEAD__;
#!/bin/sh
trap "exit 1" TERM
export TOP_PID=\$\$
set -e
if [[ "\$1" -eq "-v" ]] ; then
	set -x
fi
YEAR="$year"
AUTHOR="$artist"
ALBUM="$album"
PERFORMER="$performer"
SERIES="$series"
GROUPING="$grouping"
EPISODE="$episode"
ARTWORK="$cover"
mkdir -p wrapped
wrap() {
	TRACK=\$1
	TITLE=\$2
	FILE_NAME=\$3
	shift 3
	MP3_FILE="\${FILE_NAME}.mp3"
	M4A_FILE="\${FILE_NAME}.m4a"
	WRAP_FILE="\${FILE_NAME}_MP3WRAP.mp3"
	if [[ -f "\$WRAP_FILE" ]] ; then
		echo "Already exists!  \$WRAP_FILE"
		kill -s TERM \$TOP_PID
	fi
	if [[ "\$#" -gt 1 ]] ; then
		mp3wrap "\$FILE_NAME" "\$@"
	else
	    cp "\$1" "\$WRAP_FILE"
	fi
	while (( "\$#" )) ; do
		mv "\$1" wrapped
		shift
	done
	mv "\$WRAP_FILE" "\$MP3_FILE"
	mp3val -f "\$MP3_FILE"
	if [[ -f "\${MP3_FILE}.bak" ]] ; then
		rm "\${MP3_FILE}.bak"
	fi
	id3v2 --delete-all "\$MP3_FILE"
	id3v2 --song "\$TITLE" "\$MP3_FILE"
}
__WRAP_HEAD__
		open(WRAP,">Wrap Chapters.sh");
		print WRAP $wrapHead;
		open(WRAPMP4,">MP4 Wrap Chapters.sh");
		print WRAPMP4 $wrapHead;
		print WRAPMP4 <<__MP4_WRAP_HEAD__;
mkdir -p converted
mp4ify() {
	TRACK=\$1
	TITLE=\$2
	FILE_NAME=\$3
	if [[ -f "\${FILE_NAME}.m4a" ]] ; then
		rm "\${FILE_NAME}.m4a"
	fi
	ffmpeg -hide_banner -loglevel panic -nostats -i "\${FILE_NAME}.mp3" -c:a libfdk_aac -profile:a aac_he -b:a 32k -metadata title="\$TITLE" -metadata year=\$YEAR -metadata artist="\$AUTHOR" -metadata album_artist="\$AUTHOR" -metadata author="\$AUTHOR" -metadata album="\$ALBUM" -metadata track="\$TRACK" -metadata comment="Read by \$PERFORMER" -metadata grouping="\$GROUPING" -metadata show="\$SERIES" -metadata episode_id="\$EPISODE" -vn "\${FILE_NAME}.m4a"
	mv "\${FILE_NAME}.mp3" converted/
	mp4art -o --add "\$ARTWORK" "\${FILE_NAME}.m4a"
}
__MP4_WRAP_HEAD__
		open(FASTER,">Faster Chapters.sh");
		print FASTER qq{#!/bin/sh\nTEMPO="\$1"\nif [ -z "\$TEMPO" ] ; then\n\techo "Please provide a multiplier, such as 1.2"\n\texit -1\nfi\nif [ ! -d "notempo" ] ; then\n\tmkdir "notempo"\nfi\n};
	}
	open(RETAG, ">Retag.sh");
	print RETAG<<__RETAG_HEAD__;
#!/bin/sh
set -e
set -x
AUTHOR="$artist"
ALBUM="$album"
YEAR="$year"
PERFORMER="$performer"
SERIES="$series"
GROUPING="$grouping"
EPISODE="$episode"
ARTWORK="$cover"
retag() {
	TRACK=\$1
	TITLE=\$2
	FILE_NAME=\$3
	set +e
	mp4art -o -k --remove "\$FILE_NAME"
	set -e
	ffmpeg -hide_banner -loglevel error -nostats -i "\$FILE_NAME" -vn -codec copy -metadata title="\$TITLE" -metadata year=\$YEAR -metadata artist="\$AUTHOR" -metadata album_artist="\$AUTHOR" -metadata author="\$AUTHOR" -metadata album="\$ALBUM" -metadata track="\$TRACK" -metadata comment="Read by \$PERFORMER" -metadata grouping="\$GROUPING" -metadata show="\$SERIES" -metadata episode_id="\$EPISODE" "retagged-\$FILE_NAME"
	mv "retagged-\$FILE_NAME" "\$FILE_NAME"
	mp4art -o --add "\$ARTWORK" "\$FILE_NAME"
}
__RETAG_HEAD__
	my $chapterLength = 0;
	my $lastChapter = [];
	my @chapterLengths;
	my @chapterTracks;
	push(@chapterTracks, $lastChapter);
	my $totalSecs = 0;
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
		my $secs = $track->{'SECS'};
		$chapterLength += $secs;
		$totalSecs += $secs;
	} # foreach track
	$lastChapter->[0]->{'CHAPLEN'} = $chapterLength;
	push(@chapterLengths, $chapterLength);
	# group chapters into files
	my ($splitLength, $newSplitLength, $origErr, $newErr) = (0, 0);
	my $multipart = $totalSecs > $targetseconds;
	my $chapterNum = 0;
	my $splitNum = 1;
	my $chapterCount = scalar(@chapterTracks);
	my $zeroCount = length($chapterCount);
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
		my $chapZero = substr("0000$chapterNum", 0 - $zeroCount);
		my $safeTitle = bashEscapeSingle($chapter->[0]->{'TITLE'});
		if ($isWin) {
			$safeTitle = escapeSingle($chapter->[0]->{'TITLE'});
		}
		print FASTER qq!\necho "Adjusting tempo for $safeTitle"\nmadplay -q -o wave:- ! unless($isWin);
		my $baseName = $multipart ? qq!"$splitNum-$chapZero"! : qq!"$chapZero"!;
		print WRAP qq!wrap $chapterNum $safeTitle $baseName!;
		print WRAPMP4 qq!wrap $chapterNum $safeTitle $baseName!;
		foreach my $track (@{$chapter}) {
			my $safeTrack = bashEscapeSingle($track->{'FILE'});
			print WRAP " $safeTrack";
			print WRAPMP4 " $safeTrack";
			print FASTER " $safeTrack" unless($isWin);
			print RETAG "retag $chapterNum $safeTitle $safeTrack\n";
		}
		print WRAP "\n";
		print WRAPMP4 "\n";
		print FASTER qq! | sox --norm -t wav - "faster-$splitNum-$chapZero.mp3" tempo -s \$TEMPO\nid3v2 --song $safeTitle "faster-$splitNum-$chapZero.mp3"\n! unless($isWin);
		foreach my $track (@{$chapter}) {
			print FASTER $cmdMove . qq! ! . bashEscapeSingle($track->{'FILE'}) . qq! notempo\n! unless($isWin);
		}
		my $wrapFile = "$splitNum-${chapZero}.mp3";
		if ($isWin) {
			print WRAP qq!"$apps\\tag.exe" --remove "$wrapFile"\n!;
			print WRAP qq!"$apps\\tag.exe" --title "$safeTitle" "$wrapFile"\n!;
		} else {
			my $mp4wrap = $wrapFile;
			$mp4wrap =~ s/\.mp3/.m4a/i;
			print WRAPMP4 qq!mp4ify $chapterNum $safeTitle $baseName\n!;
		}
	} # foreach chapter
	print WRAP "$cmdMove Encode*.* wrapped\n$cmdMove *.csv wrapped\n$cmdMove *.pod wrapped\n";
	close(WRAP);
	print WRAPMP4 "$cmdMove Encode*.* wrapped\n$cmdMove *.csv wrapped\n$cmdMove *.pod wrapped\n";
	close(WRAPMP4);
	close(FASTER) unless($isWin);
	close(RETAG);
} # splitTracksAtChapters

sub formatPart {
	my ($splitNum, $splitCount) = @_;
	if($splitCount == 1) { return ""; }
	if(($splitCount > 10) and ($splitNum < 10)) { return " 0$splitNum"; }
	return " $splitNum";
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
	print("Config: $path = $result\n") unless(defined($default) && ($result eq $default));
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
	$after =~ s/'//g;
	$after =~ s/[^a-zA-Z0-9]+/-/g;
    $after =~ s/^-|-$//g;
	return $after;
} # urlsafe

sub pubDate {
	my ($offset) = @_;
	my $base = $baseDate->clone();
	if (defined($offset)) {
		# $base->subtract(seconds => scalar(@files));
		$base->add(seconds => $offset);
    }
	return $base->strftime("%a, %d %b %Y %H:%M:%S %z");
} # pubDate

sub duration {
	my ($secs) = @_;
	my $dur = secs2index($secs);
	$dur =~ s/\..+$//;
	return $dur;
} # duration