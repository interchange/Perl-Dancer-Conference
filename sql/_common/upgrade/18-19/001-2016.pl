#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::2016;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::2016->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
