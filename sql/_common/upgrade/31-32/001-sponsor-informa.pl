#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::SponsorInforma;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::SponsorInforma->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
