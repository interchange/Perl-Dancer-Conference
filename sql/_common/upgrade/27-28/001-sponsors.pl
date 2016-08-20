#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::SponsorsIvouch;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::SponsorsIvouch->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
