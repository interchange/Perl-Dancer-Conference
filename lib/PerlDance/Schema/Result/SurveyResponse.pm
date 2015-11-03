package PerlDance::Schema::Result::SurveyResponse;

=head1 NAME

PerlDance::Schema::Result::SurveyResponse

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 survey_response_id

PK

=cut

primary_column survey_response_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 user_survey_id

FK on L<Interchange6::Schema::Result::UserSurvey/user_survey_id>

=cut

column user_survey_id => { data_type => "integer" };

=head2 survey_question_id

FK on
L<PerlDance::Schema::Result::SurveyQuestionOption/survey_question_option_id>

=cut

column survey_question_id => { data_type => "integer" };

=head2 other

Text added to 'other' option.

=cut

column other => { data_type => "text", default_value => '' };

=head1 UNIQUE CONSTRAINTS

=head2 user_survey_survey_question

Unique constraint on: L</user_survey_id> and L</survey_question_id>

=cut

unique_constraint user_survey_survey_question =>
  [qw/user_survey_id survey_question_id/];

=head1 RELATIONS

=head2 user_survey

Type: belongs_to

Related object: L<PerlDance::Schema::Result::UserSurvey>

=cut

belongs_to
  user_survey => 'PerlDance::Schema::Result::UserSurvey',
  'user_survey_id';

=head2 question

Type: belongs_to

Related object: L<PerlDance::Schema::Result::SurveyQuestionOption>

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
  'survey_response_id';

1;
