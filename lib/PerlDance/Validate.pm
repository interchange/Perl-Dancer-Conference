package PerlDance::Validate;

=head1 NAME

PerlDance::Validate - Form validaton helpers using L<Data::Transpose>.

=cut

use strict;
use warnings;

use Moo;
use Dancer::Plugin::Auth::Extensible;
use Data::Transpose;

=head2 form

Returns form object

=cut

has form => (
    is => 'ro',
);

=head2 params

Returns post params

=cut

has params => (
    is => 'ro',
);

=head1 METHODS

=head2 talk

Validate talk data
Returns ( $validator, $valid )

=cut

sub talk {
    my $self = shift;
    my $values = $self->form->values;

    my $validator = Data::Transpose::Validator->new(
        stripwhite => 1,
    );

    $validator->prepare(
        talk_title => {
            validator => "String",
            required => 1,
        },
        abstract   => {
            validator => "String",
            required => 1,
        },
        tags => {
            validator => "String",
            required => 0,
        },
        duration   => {
            validator => {
                class   => "NumericRange",
                options => {
                    integer => 1,
                    min     => 20,
                    max     => 40,
                }
            },
            required => 1,
        },
        url => {
            validator => "String",
            required => 0,
        },
        comments => {
            validator => "String",
            required => 0,
        },
        confirmed => {
            required => 0,
        },
        lightning => {
            required => 0,
        },
    );

    return ( $validator, $validator->transpose($values) );
}

=head2 events

Validate event data
Returns ( $validator, $valid )

=cut

sub events {
    my $self = shift;

    my $values = $self->form->values;
    $values->{abstract} =~ s/\r\n/\n/g if defined $values->{abstract};

    my $validator = Data::Transpose::Validator->new( stripwhite => 1, );

    $validator->prepare(
        duration => {
            required  => 1,
            validator => sub {
                my $field = shift;
                if ( $field =~ /^\d+/ && $field > 0 ) {
                    return 1;
                }
                else {
                    return ( undef, "Not a positive integer" );
                }
            },
        },
        title => {
            required  => 1,
            validator => 'String',
        },
        abstract => {
            required  => 1,
            validator => 'String',
        },
        url => {
            validator => 'String',
        },
        scheduled => {
            required  => 1,
            validator => sub {
                my $field = shift;
                if ( $field =~ /^[01]$/ ) {
                    return 1;
                }
                else {
                    return ( undef, "Not a boolean yes/no (1/0)" );
                }
            },
        },
        start_time => {
            validator => 'String',
        },
        room => {
            validator => 'String',
        },
    );

    return ( $validator, $validator->transpose($values) );
}

=head2 password

=cut

sub password {
    my $self = shift;
    my $pwd = $self->params->{old_password};

    my $validator = Data::Transpose::Validator->new;
    $validator->prepare(
        old_password => {
            required => 1,
            validator => sub {
                if ( logged_in_user->check_password( $pwd ) ) {
                    return 1;
                }
                else {
                    return (undef, "Password incorrect");
                }
            },
        },
        password => {
            required  => 1,
            validator => {
                class   => 'PasswordPolicy',
                options => {
                    username      => logged_in_user->username,
                    minlength     => 8,
                    maxlength     => 70,
                    patternlength => 4,
                    mindiffchars  => 5,
                    disabled      => {
                        digits   => 1,
                        mixed    => 1,
                        specials => 1,
                    }
                }
            }
        },
        confirm_password => { required => 1 },
        passwords        => {
            validator => 'Group',
            fields    => [ "password", "confirm_password" ],
        },
    );

    return ( $validator,  $validator->transpose( $self->params ) );
}

1;
