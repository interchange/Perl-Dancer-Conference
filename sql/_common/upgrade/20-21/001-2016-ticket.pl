#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::2016::Tickets;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::2016::Tickets->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
