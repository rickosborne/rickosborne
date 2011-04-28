#!/usr/bin/perl -w

use Data::Dumper;
use Net::DNS;
use File::Copy;
use strict;

# The basic concept here is this:
# 1. Go through the existing .hosts files to find old Amazon records.
# 2. Replace the old names and addresses with the new ones.
# 3. If the file has changed, update it and archive the old version.
#    a. If the file is a .hosts file, update the sequence number.
# This is not the sharpest of scalpels.  It's really, really not
# a good idea to use this if you have more than one Amazon host.

my $newhost = shift(@ARGV) or die('Need a new hostname!');

my $dns = Net::DNS::Resolver->new;

my $packet = $dns->query($newhost);
my @answers = $packet->answer;
die("Could not resolve $newhost") unless(scalar(@answers) > 0);
my $ip = $answers[0]->address;
my $name = $answers[0]->name;
print "New host: $name/$ip\n";
my @fixaddr = ();
my %fixname = ();

my @files = </var/lib/bind/*.hosts>;
foreach my $file (@files) {
	my $content = slurp($file);
	while ($content =~ /\s+IN\s+NS\s+(\S+?\.amazonaws\.com)\./gs) {
        my $host = $1;
        next if($host eq $name);
        unless(defined($fixname{$host})) {
            $packet = $dns->query($host);
            @answers = $packet->answer;
            foreach my $answer (@answers) {
                print "Replace: " . $answer->name . "/" . $answer->address . "\n";
                $fixname{$answer->name} = 1;
                push(@fixaddr, $answer->address);
            }
            $fixname{$host} = 1;
        }
    }
}
push (@files, '/etc/bind/named.conf.local');
push (@files, '/etc/bind/named.conf.options');

die("Nothing to change!") unless(scalar(@fixaddr) > 0);

my $namere = join('|', map { quotemeta($_) } keys %fixname);
my $addrre = join('|', map { quotemeta($_) } @fixaddr);
print "Names: $namere\nAddresses: $addrre\n";
my @lt = localtime();
my $ts = ($lt[5] + 1900) . zeropad($lt[4] + 1) . zeropad($lt[3]) . zeropad($lt[2]) . zeropad($lt[1]) . zeropad($lt[0]);
print "Timestamp: $ts\n";

my @reload = ();

foreach my $file (@files) {
    my $oldcontent = slurp($file);
    my $newcontent = $oldcontent;
    $newcontent =~ s/$namere/$name/igs;
    $newcontent =~ s/$addrre/$ip/igs;
    if ($oldcontent ne $newcontent) {
        if ($file =~ /\/([^\/]+?)\.hosts$/) {
            my $domain = $1;
            my @lines = split("\n", $newcontent);
            my $seq = $lines[2];
            if ($seq =~ /^(\s+)(\d\d\d\d\d\d\d+)\s*$/) {
                $seq = int($2) + 1;
                $lines[2] = $1 . $seq;
                print "Updated sequence for $domain from $2 to $seq\n";
                push (@reload, $domain);
            }
            $newcontent = join("\n", @lines);
        }
        print "Changed: $file\n";
        move($file, $file . "." . $ts);
        open(OUT, ">$file");
        print OUT $newcontent;
        close(OUT);
    }
}

print "You should restart bind now:\nsudo /etc/init.d/bind9 restart\n";
map { print "sudo rndc notify $_\n"; } sort @reload;

exit;

sub slurp {
    my ($file) = @_;
    my $content = '';
    if (-f $file) {
        if(open(IN,"<$file")) {
            $content = join('', <IN>);
            close(IN);
        }
    }
    return $content;
}

sub zeropad {
    my ($s, $c) = @_;
    $c = 2 unless($c);
    my $z = "0" x $c;
    return substr($z . $s, 0 - $c);
}
