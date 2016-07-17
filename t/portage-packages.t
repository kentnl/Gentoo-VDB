use strict;
use warnings;

BEGIN {
    if ( !-e '/var/db/pkg' or !-r '/var/db/pkg' ) {
        print
"1..0 # SKIP this test requires a readable Gentoo Portage database in /var/db/pkg";
        exit;
    }
}

use Test::More;

use Gentoo::VDB;
my $vdb = Gentoo::VDB->new();

my ( $cat, ) = $vdb->categories;
if ( not defined $cat ) {
    plan skip_all => 'This test requires at least one category in /var/db/pkg';
    exit;
}
diag "Testing vs $cat";
for my $pkg ( $vdb->packages( { in => $cat } ) ) {
    like( $pkg, qr{\A\Q$cat\E/[^/]+\z},
        "Package $pkg has one slash and starts with category" );
}

done_testing;
