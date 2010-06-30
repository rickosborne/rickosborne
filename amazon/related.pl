#!/opt/local/bin/perl -w
#!/usr/bin/perl -w
use Data::Dumper;
use Net::Amazon;
use strict;

my $KEYFILE  = 'amazon-keys.txt';
my $MAXPAGES = 1;

my ($keyAccess, $keySecret) = readAmazonKeys($KEYFILE);
# print Dumper($keyAccess, $keySecret);
my $amz = Net::Amazon->new( token => $keyAccess, secret_key => $keySecret, max_pages => $MAXPAGES );
my ( $artist, $album ) = @ARGV;
my $hit = amazonFetch( $amz, artist => $artist, album => $album, mode => 'music' );
$hit = amazonFetch( $amz, similar => $hit->Asin() );
print Dumper( $hit );
#my @similar = $hit->similar_asins();
#foreach my $asin ( @similar ) {
#    $hit = amazonFetch( $amz, asin => $asin, mode => 'music' );
#    print $hit->artist(), ', "', $hit->album(), '", ', $asin, "\n";
#} # foreach

exit(0);

sub amazonFetch {
    my $amz = shift(@_);
    my $resp = $amz->search( artist => $artist, album => $album, mode => 'music' );
    if ( $resp->is_success() ) {
	if ( $resp->total_results() > 0 ) {
	    return $resp->properties();
	} else {
	    print "No results.\n";
	}
    } else {
	print "Error: ", $resp->message(), "\n";
    }
    return undef;
}

sub readAmazonKeys {
    my ( $keyPath ) = @_;
    my @keys;
    if(open(KEYS, "<$keyPath")) {
	@keys = split(/\s+/, <KEYS>);
	close(KEYS);
    }
    return @keys;
} #readAmazonKeys
