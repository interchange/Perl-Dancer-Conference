#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Builder;
 
use PerlDance;
my $app = PerlDance->to_app;

use Dancer2::Debugger;
my $debugger = Dancer2::Debugger->new;

builder {
    enable 'Session';
    enable 'XSRFBlock',
      cookie_name    => 'PerlDance-XSRF-Token',
      meta_tag       => 'xsrf-meta',
      cookie_options => { httponly => 1, };

    $debugger->mount;

    mount '/' => builder {
        $debugger->enable;
        $app;
    }
};
