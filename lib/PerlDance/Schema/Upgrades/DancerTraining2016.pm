package PerlDance::Schema::Upgrades::DancerTraining2016;

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
            sku => '2016PERLDANCETRAINING',
            name => 'PerlDancer 2016 Dancer Training Ticket',
            short_description => 'PerlDancer 2016 Dancer Training Ticket',
            description => q{
 * Valid for Dancer training
 * 20th September
 * Includes social event
 * Includes free T-Shirt
},
            price => 100,
            active => 1,
            inventory_exempt => 1,
            combine => 1,
            inventory => 10,
        }
    ]
                 },
);

sub upgrade {
    my $self = shift;
    my $schema = $self->schema;

    my $conference = $schema->resultset('Conference')->find(
        {name => 'Perl Dancer Conference 2016'},
    );

    # change conference date
    $conference->update( { start_date => DateTime->new(
        year => 2016,
        month => 9,
        day => 20,
    ) } );

    # create new product(s)
    my $tickets = $self->tickets;

    for my $t (@$tickets) {
        my $inventory = delete $t->{inventory};
        my $t_prod = $schema->resultset('Product')->create($t);
        my $conf = $schema->resultset('ConferenceTicket')->create(
            {
                sku => $t_prod->sku,
                conferences_id => $conference->id,
            },
        );

        $t_prod->create_related('inventory', {quantity => $inventory});
    };

    # update Dancer Training record
    my $training_rs = $schema->resultset('Talk')->search( {
        conferences_id => $conference->id,
        title => 'Programming the web with Dancer'
    } );

    unless ($training_rs->count == 1) {
        die "Failed to find talk for Dancer Training.";
    }

    $training_rs->first->update({
        accepted => 1,
        confirmed => 1,
        scheduled => 1,
        duration => 480,
        start_time => DateTime->new(
            year => 2016,
            month => 8,
            day => 20,
            hour => 9,
            minute => 30
        ),
        organiser_notes => q{The minimum attendance for this training is 6 persons. You need to buy a [ticket](/tickets) for the training. Please make sure that you have the required materials for the training.},
    } );
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

