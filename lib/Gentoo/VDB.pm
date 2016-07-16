use 5.006;    # our
use strict;
use warnings;

package Gentoo::VDB;

our $VERSION = '0.001000';

# ABSTRACT: Simple API for querying VDB Implementations

# AUTHORITY

# Note: VDB format is not well defined, and its an implementation
# detail of Portage itself, which fortunately is mostly similar to
# the implementations in other Portage clients.
#
# However, there's no requirement that the VDB definition be any
# specific way, as the only PMS requirement is that every PMS
# implementation *should* have a VDB of some description, but
# the definition is up to the implementer.
#
# Hence, all this design is to make that doable.
our $BACKENDS = {
    'portage' => sub {
        require Gentoo::VDB::Portage;
        return 'Gentoo::VDB::Portage';
    },
};

sub new {
    my ( $self, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    my $backend_name = delete $config->{backend} || 'portage';
    die "Unknown backend $backend_name"
      unless exists $BACKENDS->{$backend_name};
    my $backend_module = $BACKENDS->{$backend}->();
    my $backend        = $backend_module->new($config);
    return bless { backend => $backend, config => $config }, $self;
}

# ->categories() -> list of CAT
sub categories { $_[0]->{backend}->categories( @_[ 1 .. $#_ ] ) }

# ->packages()            -> list of CAT/PN-V
# ->packages({ in => 'dev-perl' })  -> list of CAT/PN-V in dev-perl/
sub packages { $_[0]->{backend}->packages( @_[ 1 .. $#_ ] ) }

# ->properties({ for => 'cat/pn-v' })  -> list of KEY
sub properties { $_[0]->{backend}->properties( @_[ 1 .. $#_ ] ) }

# ->get_property({ for => 'cat/pn-v', property => 'propname' }) -> HASH
sub get_property { $_[0]->{backend}->get_property( @_[ 1 .. $#_ ] ) }

1;

=head1 NAME

Gentoo::VDB - Simple API for querying Gentoo's installed-package database

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut 
