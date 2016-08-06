#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::Sponsors;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::Sponsors->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
