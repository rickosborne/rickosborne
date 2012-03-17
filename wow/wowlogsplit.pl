# use DateTime;
use Data::Dumper;
use strict;

my $WOWLOG = shift(@ARGV) || 'WoWCombatLog.txt';
my $MONTH  = (localtime())[4] + 1;
my $YEAR   = (localtime())[5] + 1900;
my $SPAN   = shift(@ARGV) || 30;
my $EPOCH  = 2000;
my $DTRE   = qr/^(\d+)\/(\d+)\s+(\d+)\:(\d+)\:/;
my $LINERE = qr/^(1[012]|0?[1-9])+\/(3[01]|[12][0-9]|0?[1-9]) +(2[0-3]|0[0-9]|1[0-9])\:([0-5][0-9])\:([0-5][0-9])\.[0-9]{3}\s+[A-Z_]+(,(0x[0-9A-Fa-f]+|-?[0-9]+|"[^"]+"|nil|[A-Z]+))+\x0d\x0a$/;

die("Can't open: $WOWLOG") unless open(LOG, "<$WOWLOG");

my $pd = 0;  # DateTime->new('year'=>$EPOCH,'month'=>1,'day'=>1);
my ($line, $dt);
my $OUT = undef;
my $lft = '';

while (($line = <LOG>) && ($dt = getTime($line))) {
    next unless($dt);
    # my $dd = $dt->delta_ms($pd);
    # if ($dd->minutes >= 30) {
    if ($dt - $ pd >= $SPAN) {
        close($OUT) if($OUT);
        $OUT = undef;
    }
    $pd = $dt;
    #my $fm = $dt->strftime('%H%M');
    #if ($fm ne $lft) {
    #    print "\t$fm\n";
    #    $lft = $fm;
    #}
    if($OUT == undef) {
        # my $ftime = $dt->strftime('%y%m%d %H%M%S') . ".txt";
        my $ftime = "$dt $WOWLOG";
        # print "$ftime\n";
        print "Splitting to $ftime\n";
        open($OUT, ">$ftime") or die("Could not open $ftime to write.");
    }
    print $OUT $line;
}

close(LOG);
close($OUT) if($OUT);

exit(0);

sub getTime {
    my ($line) = @_;
    unless($line =~ $LINERE) {
        print $line;
        hdump($line);
        return(undef);
    }
    #my $dt = DateTime->new(
    #    'year'   => ($1 > $MONTH) ? $YEAR - 1 : $YEAR,
    #    'month'  => $1,
    #    'day'    => $2,
    #    'hour'   => $3,
    #    'minute' => $4,
    #    'second' => $5
    #);
    #return $dt;
    return ($1 * 44640) + ($2 * 1440) + ($3 * 60) + $4;
}

sub hdump {
    my $offset = 0;
    my(@array,$format);
    foreach my $data (unpack("a16"x(length($_[0])/16)."a*",$_[0])) {
        my($len)=length($data);
        if ($len == 16) {
            @array = unpack('N4', $data);
            $format="0x%08x (%05d)   %08x %08x %08x %08x   %s\n";
        } else {
            @array = unpack('C*', $data);
            $_ = sprintf "%2.2x", $_ for @array;
            push(@array, '  ') while $len++ < 16;
            $format="0x%08x (%05d)" .
               "   %s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n";
        } 
        $data =~ tr/\0-\37\177-\377/./;
        printf $format,$offset,$offset,@array,$data;
        $offset += 16;
    }
}


# Times look like: 12/16 21:52:00.249