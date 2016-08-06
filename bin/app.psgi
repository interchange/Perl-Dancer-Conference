#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Builder;
use PerlDance;
my $app = PerlDance->to_app;

builder {
    enable 'Session';
    enable 'XSRFBlock',
      cookie_name    => 'PerlDance-XSRF-Token',
      meta_tag       => 'xsrf-meta',
      cookie_options => { httponly => 1, };
    enable 'XForwardedFor',
      trust => [qw( 127.0.0.1 10.0.0.0/8 172.16.0.0/20 192.168.0.0/16 )];
    $app;
}
