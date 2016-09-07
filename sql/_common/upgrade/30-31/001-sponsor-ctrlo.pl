#!perl

use strict;
use warnings;

use PerlDance::Schema::Upgrades::SponsorCtrlO;

sub {
    my $schema = shift;
    my $upgrade = PerlDance::Schema::Upgrades::SponsorCtrlO->new(
        schema => $schema
    );

    $upgrade->upgrade;
};
