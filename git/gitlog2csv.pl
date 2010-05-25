#!/opt/local/bin/perl -w
use strict;

# Original coding by Rick Osborne, 2010-05-24
# Note that this is an *intentionally* hokey CSV file, as it's
# used in a final exam practical for my course on databases. I
# DO NOT recommend that you use this in any meaningful context.

my $course = shift(@ARGV) or usage();
my $t = ',';
my $log = `git log --all --format='"%h"$t"%p"$t""$t"%aN"$t"%aE"$t"%ci"$t"%d"$t"%s"$t"%f"' --numstat --reverse`;
my @lines = split(/\n+/, $log);

print qq!"course_id","commit_id","parent1_id","parent2_id","user_name","user_email","commit_date","reflog","subject","slug","file_name","file_adds","file_deletes"\n!;

my $lastLine = "";
my $fileLines = 0;
foreach my $line (@lines) {
    if($line =~ /^\s*(\d)\s+(\d+)\s+(.+)$/) {
	print qq!"$course",$lastLine,"$3",$1,$2\n!;
	$fileLines++;
    }
    elsif($line =~ /^\s*-\s+-\s+(.+)$/) {
	print qq!"$course",$lastLine,"$1",NULL,NULL\n!;
	$fileLines++;
    }
    elsif($line =~ /^"/) {
	print(qq!"$course",$lastLine,NULL,NULL,NULL\n!) if(($fileLines == 0) && ($lastLine ne ""));
	$line =~ s/^("[^"]+",")([^" ]+) ([^" ]+)",""/$1$2","$3"/;
	$line =~ s/""/NULL/g;
	$lastLine = $line;
	$fileLines = 0;
    } # elsif
} # foreach
print(qq!"$course",$lastLine,NULL,NULL,NULL\n!) if($fileLines == 0);

exit(0);

sub usage {
    print<<__USAGE__;
Usage: gitlog2tab.pl courseName
__USAGE__
    exit(-1);
} # usage
