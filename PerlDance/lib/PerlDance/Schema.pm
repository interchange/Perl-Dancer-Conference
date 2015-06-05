package PerlDance::Schema;

use Interchange6::Schema::Result::User;

package Interchange6::Schema::Result::User;

__PACKAGE__->has_many(
    'talks_authored' => 'PerlDance::Schema::Result::Talk',
    { 'foreign.author_id' => 'self.users_id' }
);

__PACKAGE__->has_many(
    'attendee_talks' => 'PerlDance::Schema::Result::AttendeeTalk',
    "users_id"
);

__PACKAGE__->many_to_many(
    'talks_attended' => "attendee_talks",
    "talk"
);

package PerlDance::Schema;

use base 'Interchange6::Schema';

Interchange6::Schema->load_namespaces(
    default_resultset_class => 'ResultSet',
    result_namespace        => [ 'Result', '+PerlDance::Schema::Result' ],
);

1;
