use utf8;

package PerlDance::Schema::Result::Talk;

=head1 NAME

PerlDance::Schema::Result::Talk - conference/event talks

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

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
    data_type     => "text",
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
    data_type     => "text",
    default_value => '',
};

=head2 accepted

Whether talk has been accepted.

=cut

column accepted => {
    data_type => "boolean",
    size      => 0,
};

=head2 start_time

L<DateTime> object representing start time of talk.

Is nullable.

=cut

column start_time => {
    data_type => "datetime",
    is_nullable => 1,
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

1;
