package PerlDance::Schema::Result::UserSurvey;

=head1 NAME

PerlDance::Schema::Result::UserSurvey

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 user_survey_id

PK

=cut

primary_column user_survey_id =>
  { data_type => "integer", is_auto_increment => 1 };

=head2 users_id

FK on L<Interchange6::Schema::Result::User/users_id>

=cut

column users_id => { data_type => "integer" };

=head2 survey_id

FK on L<PerlDance::Schema::Result::Survey/survey_id>

=cut

column survey_id => { data_type => "integer" };

=head2 completed

Whether survey has been completed by user.

Defaults to false.

=cut

column completed => { data_type => "boolean", default_value => 0 };

=head1 UNIQUE CONSTRAINT

=head2 users_id_survey_id

=over 4

=item * L</users_id>

=item * L</survey_id>

=back

=cut

unique_constraint users_id_survey_id => [qw/users_id survey_id/];


=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
  user => 'Interchange6::Schema::Result::User',
  'users_id';

=head2 survey

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Survey>

=cut

belongs_to
  survey => 'PerlDance::Schema::Result::Survey',
  'survey_id';

=head2 responses

Type: has_many

Related object: L<PerlDance::Schema::Result::SurveyResponse>

=cut

has_many
  responses => 'PerlDance::Schema::Result::SurveyResponse',
  'user_survey_id';

1;
