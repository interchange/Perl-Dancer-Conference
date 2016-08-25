use utf8;

package PerlDance::Schema::Result::Talk;

=head1 NAME

PerlDance::Schema::Result::Talk - conference talks

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];
use URI::Escape;

=head1 ACCESSORS

=head2 talks_id

Primary key.

=cut

primary_column talks_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 author_id

Author of talk.

FK on L<Interchange6::Schema::Result::User/users_id> for relation L</author>.

Is nullable.

=cut

column author_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
};

=head2 conferences_id

Conference.

FK on L<PerlDance::Schema::Result::Conference/conferencess_id> for
relation L</conference>.

=cut

column conferences_id => {
    data_type      => "integer",
    is_foreign_key => 1,
};

=head2 duration

Duration of the talk in minutes.

=cut

column duration => { data_type => "smallint", };

=head2 title

Title of talk.

=cut

column title => {
    data_type => "varchar",
    size      => 255,
};

=head2 tags

Tags such as "dancer" or "security".

=cut

column tags => {
    data_type => "varchar",
    size      => 255,
};

=head2 abstract

Abstract of the talk.

=cut

column abstract => {
    data_type     => "varchar",
    size          => 2048,
    default_value => '',
};

=head2 url

Talk URL.

=cut

column url => {
    data_type     => "varchar",
    size          => 255,
    default_value => '',
};

=head2 video_url

Video URL.

=cut

column video_url => {
    data_type     => "varchar",
    size          => 255,
    default_value => '',
};

=head2 comments

Comments to be communicated to the organisers.

=cut

column comments => {
    data_type     => "varchar",
    size          => 1024,
    default_value => '',
};

=head2 organiser_notes

Notes from the organisers for the attendees.

=cut

column organiser_notes => {
    data_type     => "varchar",
    size          => 2048,
    default_value => '',
};

=head2 accepted

Whether talk has been accepted.

=cut

column accepted => {
    data_type     => "boolean",
    default_value => 0,
};

=head2 confirmed

Whether author has confirmed acceptance of talk.

=cut

column confirmed => {
    data_type     => "boolean",
    default_value => 0,
};

=head2 lightning

Whether this is a lightning talk.

=cut

column lightning => {
    data_type     => "boolean",
    default_value => 0,
};

=head2 scheduled

Whether or not talk time/date should be displayed in public schedules.

=cut

column scheduled => {
    data_type     => "boolean",
    default_value => 0,
};

=head2 start_time

L<DateTime> object representing start time of talk.

Is nullable.

=cut

column start_time => {
    data_type => "datetime",
    is_nullable => 1,
};

=head2 room

The room/location for this talk.

=cut

column room => {
    data_type     => "varchar",
    size          => 128,
    default_value => "",
};

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type         => "datetime",
    set_on_create     => 1,
};

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type         => "datetime",
    set_on_create     => 1,
    set_on_update     => 1,
};

=head2 survey_id

Nullable FK on L<PerlDance::Schema::Result::Survey/survey_id>

=cut

column survey_id => { data_type => "integer", is_nullable => 1 };

=head1 METHODS

=head2 attendee_count

Returns the attendee count for this talk.

If the query was constructed using
L<PerlDance::Schema::ResultSet::Talk/with_attendee_count> then the cached
value will be used rather than running a new query.

=cut

sub attendee_count {
    my $self = shift;

    if ( $self->has_column_loaded('attendee_count') ) {
        return $self->get_column('attendee_count');
    }
    else {
        return $self->attendee_talks->count;
    }
}

=head2 attendee_status( $users_id )

Returns the attendee status (1/0) for this talk.

If the query was constructed using
L<PerlDance::Schema::ResultSet::Talk/with_attendee_status> then the cached
value will be used rather than running a new query any argument is ignored.

If no cached value exists and $users_id is not defined then return 0;

=cut

sub attendee_status {
    my ( $self, $users_id ) = @_;

    if ( $self->has_column_loaded('attendee_status') ) {
        return $self->get_column('attendee_status');
    }
    else {
        return 0 unless $users_id;
        return $self->attendee_talks->search(
            {
                users_id => $users_id
            }
        )->count;
    }
}

=head2 duration_display

If L</start_time> is defined returns a string with start and end times such as:

  09:00 - 13:00

Otherwise returns a duration string such as:

  40 minutes

=cut

sub duration_display {
    my $self = shift;
    if ( defined $self->start_time ) {
        return join( " - ",
            $self->start_time->strftime("%R"),
            $self->end_time->strftime("%R") );
    }
    else {
        return join(" ", $self->duration, "minutes");
    }
}

=head2 end_time

L<DateTime> object representing end time of talk calculated from L</start_time>
and L</duration>.

=cut

sub end_time {
    my $self = shift;
    return undef unless defined $self->start_time;
    return $self->start_time->clone->add( minutes => $self->duration );
}

=head2 seo_uri

Returns a short uri comprised of L</talks_id> and L</title> such as:

    45-web-development-using-dancer

=cut

sub seo_uri {
    my $self  = shift;
    my $title = lc( $self->title );
    $title =~ s/^\s+|\s+$//g;
    $title =~ s/\s+/-/g;
    $title =~ s/::/-/g;
    return join( '-', $self->id, uri_escape_utf8($title) );
}

=head2 short_abstract

Returns a shortened (<= 200 char) version of L</abstract>.

=cut

sub short_abstract {
    my $self = shift;
    my $abstract = $self->abstract;
    return $abstract if length($abstract) <= 200;
    $abstract = substr($abstract, 0, 200);
    $abstract =~ s/\s+\S*$//;
    $abstract .= '...';
    return $abstract;
}

=head2 structured_data_hash

Returns hash used to produce structured data for the website.

=cut

sub structured_data_hash {
    my ($self, $settings) = @_;

    my $image_path = $self->author->photo_uri;
    $image_path =~ s%/%%;

    my %sd_hash = (
        uri => $self->seo_uri,
        type => 'Article',
        author => $self->author->name_with_nickname,
        headline => $self->title,
        image_uri => $self->conference->uri . $image_path,
        image_path => join('/', $settings->{'public_dir'}, $image_path),
        logo_uri => $self->conference->uri . $self->conference->logo,
        logo_path => join('/', $settings->{'public_dir'}, $self->conference->logo),
        date_published => $self->created,
        date_modified => $self->last_modified,
        publisher => 'Perl Dancer Conference',
    );

    return \%sd_hash;
}

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

LEFT JOIN due to FK being nullable.

=cut

belongs_to
  author => 'Interchange6::Schema::Result::User',
  { 'foreign.users_id' => 'self.author_id' },
  { join_type => 'left' };

=head2 attendee_talks

Type: has_many

Related object: L<PerlDance::Schema::Result::AttendeeTalk>

Link table between talks and users.

=cut

has_many
  attendee_talks => 'PerlDance::Schema::Result::AttendeeTalk',
  "talks_id";

=head2 attendees

Type: many_to_many

Composing rels: L</attendee_talks> -> user

=cut

many_to_many attendees => "attendee_talks", "user";

=head2 conference

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Conference>

=cut

belongs_to
  conference => 'PerlDance::Schema::Result::Conference', "conferences_id";

=head2 survey

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Survey>

=cut

belongs_to
  survey => 'PerlDance::Schema::Result::Survey',
  "survey_id", { join_type => 'left', on_delete => 'SET NULL' };

1;
