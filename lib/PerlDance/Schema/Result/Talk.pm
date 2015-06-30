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

=cut

column author_id => {
    data_type      => "integer",
    is_foreign_key => 1,
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

=head2 comments

Comments to be communicated to the organisers.

=cut

column comments => {
    data_type     => "varchar",
    size          => 1024,
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

=head2 METHODS

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

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
  author => 'Interchange6::Schema::Result::User',
  { 'foreign.users_id' => 'self.author_id' };

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

1;