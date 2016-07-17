use strict;
use warnings;

BEGIN {
  if ( !-e '/var/db/pkg' or !-r '/var/db/pkg' ) {
    print "1..0 # SKIP this test requires a readable Gentoo Portage database in /var/db/pkg";
    exit;
  }
}

use Test::More;

use Gentoo::VDB;
my $vdb = Gentoo::VDB->new();

for my $cat ( $vdb->categories ) {
  my $ok = like( $cat, qr{\A[^/]+\z}, "Category $cat has no slashes" );
  # Note, this will probably fail somewhere, and if it does, its likely this test that needs
  # to be changed. However, category naming rules dont' appear anywhere I can find.
  undef $ok unless like( $cat, qr{\A[a-z0-9-]+\z}, "Category $cat matches restricted set");
  diag "Failed category $cat" unless $ok;
}

done_testing;
