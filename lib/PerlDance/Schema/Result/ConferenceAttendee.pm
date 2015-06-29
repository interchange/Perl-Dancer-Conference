use utf8;

package PerlDance::Schema::Result::ConferenceAttendee;

=head1 NAME

PerlDance::Schema::Result::ConferenceAttendee - links Conference to User

=cut

use Interchange6::Schema::Candy;


=head1 ACCESSORS

=head2 conferences_id

Foreign constraint on L<PerlDance::Schema::Result::Conference/conferences_id>
for relation L</conference>.

=cut

column conferences_id => { data_type => "integer", is_foreign_key => 1 };

=head2 users_id

Foreign constraint on L<Interchange6::Schema::Result::User/users_id>
for relation L</user>.

=cut

column users_id => { data_type => "integer", is_foreign_key => 1 };

=head2 confirmed

Whether user is confirmed to attend. This can be use to track payment or
actual attendance.

Defaults to false.

=cut

column confirmed => { data_type => "boolean", default_value => 0 };

=head1 PRIMARY KEY

=over 4

=item * L</conferences_id>

=item * L</users_id>

=back

=cut

primary_key "conferences_id", "users_id";

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

belongs_to user => 'Interchange6::Schema::Result::User', "users_id";

1;
