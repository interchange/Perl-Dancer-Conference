use utf8;

package PerlDance::Schema::Result::ConferenceTicket;

=head1 NAME

PerlDance::Schema::Result::ConferenceTicket - links Conference to Tickets

=cut

use Interchange6::Schema::Candy;


=head1 ACCESSORS

=head2 conferences_id

Foreign constraint on L<PerlDance::Schema::Result::Conference/conferences_id>
for relation L</conference>.

=cut

column conferences_id => { data_type => "integer", is_foreign_key => 1 };

=head2 users_id

Foreign constraint on L<Interchange6::Schema::Result::Product/sku>
for relation L</ticket>.

=cut

column sku => { data_type => "varchar", size => 64, is_foreign_key => 1 };

=head1 PRIMARY KEY

=over 4

=item * L</conferences_id>

=item * L</sku>

=back

=cut

primary_key "conferences_id", "sku";

=head1 RELATIONS

=head2 conference

Type: belongs_to

Related object: L<PerlDance::Schema::Result::Conference>

=cut

belongs_to
  conference => 'PerlDance::Schema::Result::Conference',
  "conferences_id";

=head2 ticket

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to ticket => 'Interchange6::Schema::Result::Product', "sku";

1;
