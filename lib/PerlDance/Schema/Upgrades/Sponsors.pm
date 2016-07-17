package PerlDance::Schema::Upgrades::Sponsors;

use Moo;
use Types::Standard qw/InstanceOf/;

use DateTime;

has schema => (
    is => 'ro',
    isa => InstanceOf['PerlDance::Schema'],
    required => 1,
);

has sponsor_levels => (
    is => 'ro',
    default => sub {
        return [
            {
                name => 'Diamond Sponsor',
                uri => 'sponsors/diamond',
                priority => 50,
            },
            {
                name => 'Gold Sponsor',
                uri => 'sponsors/gold',
                priority => 40,
            },
            {
                name => 'Silver Sponsor',
                uri => 'sponsors/silver',
                priority => 30,
            },
            {
                name => 'Bronze Sponsor',
                uri => 'sponsors/bronze',
                priority => 20,
            },
            {
                name => 'Special Sponsor',
                uri => 'sponsors/special',
                priority => 10,
            }
        ];
    }
);

sub upgrade {
    my $self = shift;
    my $schema = $self->schema;

    # add navigation entries for the different sponsor types
    my $sponsor_nav = $schema->resultset('Navigation')->find({uri => 'sponsors'});

    for my $level (@{$self->sponsor_levels}) {
        $schema->resultset('Navigation')->create({
            parent_id => $sponsor_nav->id,
            name => $level->{name},
            uri => $level->{uri},
            priority => $level->{priority},
        });
    }
}

sub clear {
    my $self = shift;
    my $schema = $self->schema;

    # delete all descendants of sponsors navigation entry
    $schema->resultset('Navigation')->find({uri => 'sponsors'})->children->delete;
}

1;

