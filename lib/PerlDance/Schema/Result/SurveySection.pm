package PerlDance::Schema::Result::SurveySection;

=head1 NAME

PerlDance::Schema::Result::SurveySection

=cut

use base 'Interchange6::Schema::Base::Attribute';

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 survey_section_id

PK

=cut

primary_column survey_section_id =>
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

=head2 priority

Section priority, high to low.

=cut

column priority => { data_type => "integer" };

=head2 survey_id

FK on L<PerlDance::Schema::Result::Survey/survey_id>

=cut

column survey_id => { data_type => "integer" };

=head1 RELATIONS

=head2 survey

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Survey>

=cut

belongs_to
  survey => 'PerlDance::Schema::Result::Survey',
  'survey_id';

=head2 questions

Type: has_many

Related object: L<PerlDance::Schema::Result::SurveyQuestion>

=cut

has_many
  questions => 'PerlDance::Schema::Result::SurveyQuestion',
  'survey_section_id';

1;
