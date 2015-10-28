package PerlDance::Schema::Result::Survey;

=head1 NAME

PerlDance::Schema::Result::Survey

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 ACCESSORS

=head2 survey_id

PK

=cut

primary_column survey_id => { data_type => "integer", is_auto_increment => 1 };

=head2 title

Survey title.

=cut

column title => { data_type => "varchar", size => 255 };

=head2 conferences_id

Foreign constraint on L<PerlDance::Schema::Result::Conference/conferences_id>
for relation L</conference>.

=cut

column conferences_id => { data_type => "integer" };

=head2 author_id

Foreign constraint on L<Interchange6::Schema::Result::User/users_id>
for relation L</user>.

=cut

column author_id => { data_type => "integer" };

=head2 public

Boolean whether survey is public (questions or results).

Defaults to false.

=cut

column public => { data_type => "boolean", default_value => 0 };

=head2 closed

Boolean whether survey is closed: if true then questions are no longer
available but results are visible instead.

Defaults to false.

=cut

column closed => { data_type => "boolean", default_value => 0 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => { data_type => "datetime", set_on_create => 1 };

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified =>
  { data_type => "datetime", set_on_create => 1, set_on_update => 1 };

=head1 UNIQUE CONSTRAINTS

=head2 surveys_conferences_id_title

Each conference must have unique survey titles.

=cut

unique_constraint surveys_conferences_id_title => [qw/conferences_id title/];

=head1 RELATIONS

=head2 conference

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Conference>

=cut

belongs_to
  conference => 'PerlDance::Schema::Result::Conference',
  "conferences_id";

=head2 user

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to author => 'Interchange6::Schema::Result::User', "author_id";

=head2 sections

Type: has_many

Related object: L<PerlDance::Schema::Result::SurveySection>

=cut

has_many
  sections => 'PerlDance::Schema::Result::SurveySection',
  "survey_id";

1;
