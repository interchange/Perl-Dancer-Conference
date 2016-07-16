package PerlDance::Schema::Upgrades::2016::Tickets;

use Moo;
use Types::Standard qw/InstanceOf/;

use DateTime;

has schema => (
    is => 'ro',
    isa => InstanceOf['PerlDance::Schema'],
    required => 1,
);

has tickets => (
    is => 'ro',
    default => sub { return [
        {
            sku => '2016PERLDANCE2DAYSREGULAR',
            name => 'PerlDancer 2016 Conference Ticket',
            short_description => 'PerlDancer 2016 Conference Ticket',
            description => q{
 * Valid for 2 conference days
 * 21st and 22nd September
 * Entrance to all talks
 * Includes social event
 * Includes free T-Shirt
},
            price => 140,
            active => 1,
            inventory_exempt => 1,
            combine => 1,
            inventory => 25,
        }
    ]
                 },
);

sub upgrade {
    my $self = shift;
    my $schema = $self->schema;

    # create new product(s)
    my $tickets = $self->tickets;

    for my $t (@$tickets) {
        my $inventory = delete $t->{inventory};
        my $t_prod = $schema->resultset('Product')->create($t);
        my $conf = $schema->resultset('ConferenceTicket')->create(
            {
                sku => $t_prod->sku,
                conferences_id => 2
            },
        );

        $t_prod->create_related('inventory', {quantity => $inventory});
    };
}

sub clear {
    my $self = shift;
    my $schema = $self->schema;

    # remove products
    my $tickets = $self->tickets;

    for my $t (@$tickets) {
        my $t_prod = $schema->resultset('Product')->find(
            {
                sku => $t->{sku},
            }
        );

        if ($t_prod) {
            $t_prod->delete;
        }
    }
}

1;

