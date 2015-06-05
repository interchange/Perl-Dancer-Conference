use utf8;

package PerlDance::Schema::Result::AttendeeTalk;

=head1 NAME

PerlDance::Schema::Result::AttendeeTalk - conference/event talks

=cut

use Interchange6::Schema::Candy;


=head1 ACCESSORS

=head2 users_id

Foreign constraint on L<Interchange6::Schema::Result::User/users_id>
for relation L</user>.

=cut

column users_id =>
  { data_type => "integer", is_foreign_key => 1 };

=head2 talks_id

Foreign constraint on L<PerlDance::Schema::Result::Talk/talks_id>
for relation L</talk>.

=cut

column talks_id =>
  { data_type => "integer", is_foreign_key => 1 };

=head1 PRIMARY KEY

=over 4

=item * L</users_id>

=item * L</talks_id>

=back

=cut

primary_key "users_id", "talks_id";

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to user => 'Interchange6::Schema::Result::User', "users_id";

=head2 talk

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Talk>

=cut

belongs_to talk => 'PerlDance::Schema::Result::Talk', "talks_id";

1;
