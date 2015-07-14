use utf8;

package PerlDance::Schema::Result::Conference;

=head1 NAME

PerlDance::Schema::Result::Conference

=cut

use Interchange6::Schema::Candy -components => [qw(InflateColumn::DateTime)];

=head1 ACCESSORS

=head2 conferences_id

Primary key.

=cut

primary_column conferences_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 name

Name of conference such as "Perl Dancer Conference 2015"

Unique constraint.

=cut

unique_column name => {
    data_type => "varchar",
    size      => 128,
};

=head2 start_date

Start date of conference

=cut

column start_date => {
    data_type => "date",
    is_nullable => 1,
};

=head1 RELATIONS

=head2 attendees

Type: many_to_many

Composing rels: L</conference_attendees> -> user

=cut

many_to_many attendees => "conference_attendees", "user";

=head2 conference_attendees

Type: has_many

Related object: L<PerlDance::Schema::Result::ConferenceAttendee>

=cut

has_many
  conferences_attendees => 'PerlDance::Schema::Result::ConferenceAttendee',
  "conferences_id";

=head2 talks

Type: has_many

Related object: L<PerlDance::Schema::Result::Talk>

=cut

has_many talks => 'PerlDance::Schema::Result::Talk', "conferences_id";

1;
