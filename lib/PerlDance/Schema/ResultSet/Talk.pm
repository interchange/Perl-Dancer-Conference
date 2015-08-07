package PerlDance::Schema::ResultSet::Talk;

=head1 NAME

PerlDance::Schema::ResultSet::Talk

=cut

use strict;
use warnings;

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 with_attendee_count

Returns the attendee count for this
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

1;
