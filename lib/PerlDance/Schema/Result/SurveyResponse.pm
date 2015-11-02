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

=head2 survey_question_option_id

FK on
L<PerlDance::Schema::Result::SurveyQuestionOption/survey_question_option_id>

=cut

column survey_question_option_id => { data_type => "integer" };

=head2 value

Value is used for questions of type 'grid'.

=cut

column value => { data_type => "integer", is_nullable => 1 };

=head1 RELATIONS

=head2 user_survey

Type: belongs_to

Related object: L<PerlDance::Schema::Result::UserSurvey>

=cut

belongs_to
  user_survey => 'PerlDance::Schema::Result::UserSurvey',
  'user_survey_id';

=head2 survey_question_option

Type: belongs_to

Related object: L<PerlDance::Schema::Result::SurveyQuestionOption>

=cut

belongs_to
  survey_question_option => 'PerlDance::Schema::Result::SurveyQuestionOption',
  'survey_question_option_id';

1;
