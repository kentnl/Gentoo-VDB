use 5.006;    # our
use strict;
use warnings;

package Gentoo::VDB::Portage;

our $VERSION = '0.001000';

# ABSTRACT: VDB Query Implementation for Portage/Emerge

# AUTHORITY

sub new {
    my ( $class, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    return bless $config, $class;
}

sub _path {
    return ( $_[0]->{path} ||= '/var/db/pkg' );
}

sub __dir_iterator {
    my ($path) = @_;
    my $handle;
    ( -d $path and opendir $handle, $path ) or return sub { return undef };
    return sub {
        while (1) {
            my $dir = readdir $handle;
            return undef unless defined $dir;
            next if $dir eq '.' or $dir eq '..';    # skip hidden entries
            return $dir;
        }
    };
}

sub _category_iterator {
    my ($self) = @_;
    my $root = $self->_path;
    return sub { return undef }
      unless -d $root;
    my $_cat_iterator = __dir_iterator($root);
    return sub {
        while (1) {

            # Category possible
            my $category = $_cat_iterator->();
            return undef if not defined $category;

            # Skip hidden categories
            next if $category =~ /\A[.]/x;

            # Validate category to have at least one package with a file
            my $_pkg_iterator = __dir_iterator( $root . '/' . $category );
            while ( my $package = $_pkg_iterator->() ) {
                next if $package =~ /\A[.]/x;
                my $_file_iterator =
                  __dir_iterator( $root . '/' . $category . '/' . $package );
                while ( my $file = $_file_iterator->() ) {
                    next if $file =~ /\A[.]/x;
                    ## Found one package with one file, category is valid
                    return $category;
                }
            }
        }
    };
}

sub categories {
    my ($self) = @_;
    my $it = $self->_category_iterator;
    my @cats;
    while ( my $entry = $it->() ) {
        push @cats, $entry;
    }
    return @cats;
}

sub _package_iterator {
    my ( $self, $config ) = @_;
    my $root = $self->_path;
    if ( $config->{in} ) {
        return sub { return undef }
          unless -d $root . '/' . $config->{in};
        my $_pkg_iterator = __dir_iterator( $root . '/' . $config->{in} );
        return sub {
            while (1) {
                my $package = $_pkg_iterator->();
                return undef if not defined $package;
                next if $package =~ /\A[.]/x;
                my $_file_iterator = __dir_iterator(
                    $root . '/' . $config->{in} . '/' . $package );
                while ( my $file = $_file_iterator->() ) {
                    next if $file =~ /\A[.]/x;
                    ## Found one package with one file, package is valid
                    return $config->{in} . '/' . $package;
                }
            }
        };
    }

    return sub { return undef }
      unless -d $root;

    my $_cat_iterator = __dir_iterator($root);
    my $category      = $_cat_iterator->();

    return sub { return undef }
      unless defined $category;

    my $_pkg_iterator = __dir_iterator( $root . '/' . $category );

    return sub {
        while (1) {
            return undef if not defined $category;
            my $package = $_pkg_iterator->();
            if ( not defined $package ) {
                $category = $_cat_iterator->();
                return undef if not defined $category;
                if ( defined $category ) {
                    $_pkg_iterator = __dir_iterator( $root . '/' . $category );
                    next;
                }
                next;
            }
            next if $package =~ /\A[.]/x;
            my $_file_iterator =
              __dir_iterator( $root . '/' . $category . '/' . $package );
            while ( my $file = $_file_iterator->() ) {
                next if $file =~ /\A[.]/x;
                ## Found one package with one file, package is valid
                return $category . '/' . $package;
            }
        }
    };
}

sub packages {
    my ( $self, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    my $iterator = $self->_package_iterator($config);
    my (@packages);
    while ( my $result = $iterator->() ) {
        push @packages, $result;
    }
    return @packages;
}

1;

=head1 NAME

Gentoo::VDB::Portage - VDB Query Implementation for Portage/Emerge

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
