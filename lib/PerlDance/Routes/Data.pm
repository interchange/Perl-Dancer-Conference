package PerlDance::Routes::Data;

=head1 NAME

PerlDance::Routes::Data - Data routes under prefix /data

=cut

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::DBIC;

=head1 PREFIX

All routes in this class are prefixed with '/data'

=cut

prefix '/data';

=head1 ROUTES

=head2 get /states.js

returns javascript with var C<countryStates> which is JSON form of

  { country_iso_code => [ { states_id => "name" }, ... } ] }

for all states in States class and also generates var C<statesById> on client
side as an associative array of C<< states_id => name >>.

=cut

get '/states.js' => sub {
    content_type('application/javascript');
    my $json = to_json(
        {
            map { $_->{country_iso_code} => $_->{states} }
              rset('Country')->search(
                {
                    'me.active'     => 1,
                    'states.active' => 1,
                },
                {
                    join       => 'states',
                    columns    => ['me.country_iso_code'],
                    '+columns' => [ 'states.states_id', 'states.name' ],
                    collapse   => 1,
                    order_by   => 'states.name',
                }
              )->hri->all
        },
        {
            pretty => 0,
        }
    );
    return<<EOF
var countryStates = $json;
var statesById = {};
\$.each(countryStates, function( c, s ) {
  \$.each(s, function( i, v ) {
    statesById[v.states_id] = v.name;
  });
});
EOF
};

# reset prefix at end
prefix undef;
true;
