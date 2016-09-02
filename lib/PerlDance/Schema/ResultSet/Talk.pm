package PerlDance::Schema::ResultSet::Talk;

=head1 NAME

PerlDance::Schema::ResultSet::Talk

=cut

use strict;
use warnings;

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 with_attendee_count

Adds 'attendee_count' to result set.

=cut

sub with_attendee_count {
    my $self = shift;

    $self->search(
        undef,
        {
            '+columns' => {
                attendee_count =>
                  $self->correlate('attendee_talks')->count_rs->as_query
            }
        }
    );
}

=head2 with_attendee_status( $users_id )

Adds 'attendee_status' true/false (1/0) to result set for provided $users_id.
Throws an exception if no defined argument is supplied.

=cut

sub with_attendee_status {
    my ( $self, $users_id ) = @_;

    $self->throw_exception("with_attendee_status required arg users_id missing")
      unless defined $users_id;

    $self->search(
        undef,
        {
            '+columns' => {
                attendee_status => $self->correlate('attendee_talks')->search(
                    {
                        users_id => $users_id
                    }
                )->count_rs->as_query
            }
        }
    );
}

=head2 scheduled_for

Limits resultset to talks scheduled for a given date.

=cut

sub scheduled_for {
    my ( $self, $dt_date ) = @_;

    $self->throw_exception("scheduled_for required arg dt_date missing")
        unless defined $dt_date;

    my $schema = $self->result_source->schema;

    $self->search(
        {
            start_time     => {
                '!=' => undef,
                '>=' => $schema->format_datetime($dt_date),
                '<=' =>
                    $schema->format_datetime( $dt_date->clone->add( days => 1 ) )
                },
        }
    );
}

1;
