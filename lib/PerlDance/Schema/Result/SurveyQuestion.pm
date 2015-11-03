package PerlDance::Schema::Result::SurveyQuestion;

=head1 NAME

PerlDance::Schema::Result::SurveyQuestion

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 survey_question_id

PK

=cut

primary_column survey_question_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 title

Section title.

=cut

column title => { data_type => "varchar", size => 255 };

=head2 description

Section description.

Defaults to empty string;

=cut

column description =>
  { data_type => "varchar", size => 2048, default_value => "" };

=head2 other

Text to be displayed before a textarea if 'Other' is a possible option, e.g.:

'please enter your professional job role or title'

Defaults to empty string.

=cut

column other => { data_type => "varchar", size => 255, default_value => "" };

=head2 type

radio or checkbox

=cut

column type => { data_type => "varchar", size => 16 };

=head2 priority

Section priority, high to low.

=cut

column priority => { data_type => "integer" };

=head2 survey_section_id

FK on L<PerlDance::Schema::Result::SurveySection/survey_section_id>

=cut

column survey_section_id => { data_type => "integer" };

=head1 RELATIONS

=head2 section

Type: belongs_to

Related object: L<PerlDance::Schema::Result::SurveySection>

=cut

belongs_to
  section => 'PerlDance::Schema::Result::SurveySection',
  'survey_section_id';

=head2 options

Type: has_many

Related object: L<PerlDance::Schema::Result::SurveyQuestionOption>

=cut

has_many
  options => 'PerlDance::Schema::Result::SurveyQuestionOption',
  'survey_question_id';

=head2 responses

Type: has_many

Related object: L<PerlDance::Schema::Result::SurveyResponse>

=cut

has_many
  responses => 'PerlDance::Schema::Result::SurveyResponse',
  'survey_question_id';

1;
