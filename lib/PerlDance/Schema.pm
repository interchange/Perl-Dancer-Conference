package PerlDance::Schema;

our $VERSION = 33;

use Interchange6::Schema::Result::Address;
package Interchange6::Schema::Result::Address;

=head1 L<Interchange6::Schema::Result::User>

=head2 ACCESSORS

=head3 latitude

=head3 longitude

=cut

__PACKAGE__->add_columns(
    latitude  => { data_type => "float", size => 20, is_nullable => 1 },
    longitude => { data_type => "float", size => 30, is_nullable => 1 },
);

use Interchange6::Schema::Result::Message;
package Interchange6::Schema::Result::Message;

__PACKAGE__->add_columns(
    tags => { data_type => "varchar", size => "256", default_value => '' },
);

use Interchange6::Schema::Result::Product;
package Interchange6::Schema::Result::Product;

__PACKAGE__->might_have(
    conference_ticket => "PerlDance::Schema::Result::ConferenceTicket",
    "sku",
);

use Interchange6::Schema::Result::User;
package Interchange6::Schema::Result::User;
use Class::Method::Modifiers;
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
    monger_groups =>
      { data_type => "varchar", size => 256, default_value => '' },
    pause_id => { data_type => "varchar", size => 128, default_value => '' },
    guru_level => { data_type => "integer", default_value => 0 },
    t_shirt_size => { data_type => "varchar", size => 8, is_nullable => 1 },
);

=head2 METHODS

=head3 insert

Overloaded method. Add 'unknown user' image as initial photo.

=cut

around insert => sub {
    my $orig = shift;
    my $self = $orig->(@_);
    if ( !$self->media_id ) {
        my $schema = $self->result_source->schema;
        my $photo = $schema->resultset('Media')->search(
            {
                'me.label'        => 'unknown user',
                'media_type.type' => 'image',
            },
            {
                join => 'media_type',
                rows => 1,
            }
        )->single;
        if ( $photo ) {
            $self->update({ media_id => $photo->id });
        }
    }
    return $self;
};

=head2 METHODS

=head3 photo_uri

Returns the uri of the related L</photo> if it exists or else the uri
for the Media row where C<file> = C<img/people/unknown.jpg>.

=cut

sub photo_uri {
    my $self  = shift;
    my $photo = $self->photo;
    if ( !$photo ) {
        $photo = $self->result_source->schema->resultset('Media')->find(
            {
                file => 'img/people/unknown.jpg'
            }
        );
        return undef unless $photo;
    }
    return $photo->uri;
}

=head3 uri

uri component for user constructed from users_id and lower case name. We 
don't need this but it makes for seo-friendly uris.

=cut

sub uri {
    my $self = shift;
    my $name = lc($self->name);
    $name =~ s/^\s+|\s+$//g;
    $name =~ s/\s+/-/g;
    return join('-', $self->id, uri_escape_utf8($name));
}

=head3 last_conference_attended

Returns the last conference this user has attended or undef.

=cut

sub last_conference_attended {
    my $self = shift;
    my $conference = $self->conferences->search({}, {
        rows => 1,
        order_by => { -desc => 'start_date' },
    })->first;
}

sub name_with_nickname {
    my $self = shift;
    my $long_name = $self->name;
    my $nick_name = $self->nickname;

    if ($nick_name && $nick_name ne $long_name) {
        $long_name .= ' (' . $self->nickname . ')';
    }

    return $long_name;
}

=head2 structured_data_hash

Returns hash used to produce structured data for the website.

=cut

sub structured_data_hash {
    my ($self, $settings) = @_;

    my $image_path = $self->photo_uri;
    $image_path =~ s%/%%;

    # get conference
    my $conference = $self->last_conference_attended;

    my %sd_hash = (
        uri => $self->uri,
        type => 'Article',
        author => $self->name_with_nickname,
        headline => 'User ' . $self->name_with_nickname,
        image_uri => $conference->uri . $image_path,
        image_path => join('/', $settings->{'public_dir'}, $image_path),
        logo_uri => $conference->uri . $conference->logo,
        logo_path => join('/', $settings->{'public_dir'}, $conference->logo),
        date_published => $self->created,
        date_modified => $self->last_modified,
        publisher => 'Perl Dancer Conference',
    );

    return \%sd_hash;
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
via L</conferences_attendeed>

=cut

__PACKAGE__->many_to_many(
    'conferences' => "conferences_attended",
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

__PACKAGE__->load_components( 'Schema::Config' );

Interchange6::Schema->load_namespaces(
    default_resultset_class => 'ResultSet',
    result_namespace        => [ 'Result', '+PerlDance::Schema::Result' ],
    resultset_namespace     => [ 'ResultSet', '+PerlDance::Schema::ResultSet' ],
);

=head1 ATTRIBUTES

=head2 current_conference

This attribute can be used to stash the L<Interchange6::Schema::Result::Conference>
object of the current conference.

=over

=item writer: set_current_conference

=back

=cut

__PACKAGE__->mk_group_ro_accessors(
    inherited => (
        [ 'current_conference' => '_pd_current_conference' ],
    )
);

__PACKAGE__->mk_group_wo_accessors(
    inherited => (
        [ 'set_current_conference' => '_pd_current_conference' ],
    )
);

1;
