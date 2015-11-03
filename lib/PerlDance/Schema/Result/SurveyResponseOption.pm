package PerlDance::Schema::Result::SurveyResponseOption;

=head1 NAME

PerlDance::Schema::Result::SurveyResponseOption

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 survey_response_option_id

PK

=cut

primary_column survey_response_option_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 survey_response_id

FK on L<Interchange6::Schema::Result::SurveyResponse/survey_response_id>

=cut

column survey_response_id => { data_type => "integer" };

=head2 survey_question_option_id

FK on
L<Interchange6::Schema::Result::SurveyQuestionOption/survey_question_option_id>

=cut

column survey_question_option_id => { data_type => "integer" };

=head2 value

Value is used for questions of type 'grid'.

=cut

column value => { data_type => "integer", is_nullable => 1 };

=head1 RELATIONS

=head2 response

Type: belongs_to

Related object: L<PerlDance::Schema::Result::SurveyResponse>

=cut

belongs_to
  response => 'PerlDance::Schema::Result::SurveyResponse',
  'survey_response_id';

=head2 question_option

Type: belongs_to

Related object: L<PerlDance::Schema::Result::SurveyQuestionOption>

=cut

belongs_to
  question_option => 'PerlDance::Schema::Result::SurveyQuestionOption',
  'survey_question_option_id';

1;
