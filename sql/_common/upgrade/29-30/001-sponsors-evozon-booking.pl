#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::SponsorsBookingEvozon;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::SponsorsBookingEvozon->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
