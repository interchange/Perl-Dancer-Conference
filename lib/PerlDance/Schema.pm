package PerlDance::Schema;

use Interchange6::Schema::Result::User;
package Interchange6::Schema::Result::User;
use URI::Escape;

=head1 L<Interchange6::Schema::Result::User>

=head2 ACCESSORS

=head3 bio

Biography. Defaults to empty string.

=head3 media_id

FK on  L<Interchange6::Schema::Result::Media/media_id>.

Is nullable.

=head3 pause_id

PAUSE id. Defaults to empty string.

=cut

__PACKAGE__->add_columns(
    bio => { data_type => "varchar", size => 2048, default_value => '' },
    media_id =>
      { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    pause_id => { data_type => "varchar", size => 128, default_value => '' },
);

=head2 METHODS

=head3 uri

uri component for user constructed from users_id and lower case name. We 
don't need this but it makes for seo-friendly uris.

=cut

sub uri {
    my $self = shift;
    my $name = lc($self->name);
    $name =~ s/^\s+|\s+$//g;
    $name =~ s/\s+/-/g;
    return join('-', $self->id, uri_escape($name));
}

=head2 RELATIONS

=head3 talks_authored

User can be author/speaker at many talks.

Type: has_many

Related object: L<PerlDance::Schema::Result::Talk>

=cut

__PACKAGE__->has_many(
    'talks_authored' => 'PerlDance::Schema::Result::Talk',
    { 'foreign.author_id' => 'self.users_id' }
);

=head3 attendee_talks

Link table to L<PerlDance::Schema::Result::Talk>.

Type: has_many

Related object: L<PerlDance::Schema::Result::AttendeeTalk>

=cut

__PACKAGE__->has_many(
    'attendee_talks' => 'PerlDance::Schema::Result::AttendeeTalk',
    "users_id"
);

=head3 conferences_attended

Link table to L<PerlDance::Schema::Result::Conference>.

Type: has_many

Related object: L<PerlDance::Schema::Result::ConferenceAttendee>

=cut

__PACKAGE__->has_many(
    'conferences_attended' => 'PerlDance::Schema::Result::ConferenceAttendee',
    "users_id"
);

=head3 conferences

User attends many conferences.

Type: many_to_many with L<PerlDance::Schema::Result::Conference>
via L</conference_attendees>

=cut

__PACKAGE__->many_to_many(
    'conferences' => "conference_attendees",
    "conference"
);

=head3 talks_attended

User attends many talks.

Type: many_to_many with talks via L</attendee_talks>

=cut

__PACKAGE__->many_to_many(
    'talks_attended' => "attendee_talks",
    "talk"
);

=head3 photo

Users's photo

=cut

__PACKAGE__->belongs_to(
    'photo' => 'Interchange6::Schema::Result::Media',
    'media_id',
    { join_type => 'left' },
);

=head1 PerlDance::Schema

Inherit from L<Interchange6::Schema> and set to result_namespace to 
L<Interchange6::Schema::Result> plus L<PerlDance::Schema::Result>.

=cut

package PerlDance::Schema;

use base 'Interchange6::Schema';

Interchange6::Schema->load_namespaces(
    default_resultset_class => 'ResultSet',
    result_namespace        => [ 'Result', '+PerlDance::Schema::Result' ],
);

1;
