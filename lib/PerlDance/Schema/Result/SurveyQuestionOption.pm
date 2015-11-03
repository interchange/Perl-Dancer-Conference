package PerlDance::Schema::Result::SurveyQuestionOption;

=head1 NAME

PerlDance::Schema::Result::SurveyQuestionOption

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 survey_question_option_id

PK

=cut

primary_column survey_question_option_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 title

Section title.

=cut

column title => { data_type => "varchar", size => 255 };

=head2 priority

Section priority, high to low.

=cut

column priority => { data_type => "integer" };

=head2 survey_question_id

FK on L<PerlDance::Schema::Result::SurveyQuestion/survey_question_id>

=cut

column survey_question_id => { data_type => "integer" };

=head1 RELATIONS

=head2 question

Type: belongs_to

Related object: L<PerlDance::Schema::Result::SurveyQuestion>

=cut

belongs_to
  question => 'PerlDance::Schema::Result::SurveyQuestion',
  'survey_question_id';

=head2 response_options

Type: has_many

Related object: L<PerlDance::Schema::Result::SurveyResponseOption>

=cut

has_many
  response_options => 'PerlDance::Schema::Result::SurveyResponseOption',
  'survey_question_option_id';

1;
