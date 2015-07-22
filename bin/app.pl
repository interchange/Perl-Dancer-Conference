#!/usr/bin/env perl
use Plack::Builder;
use Dancer;
use PerlDance;
use lib 'lib';

my $app = sub {
    load_app "PerlDance";
    Dancer::App->set_running_app("PerlDance");
    my $env = shift;
    Dancer::Handler->init_request_headers($env);
    my $req = Dancer::Request->new( env => $env );
    Dancer->dance($req);
};

builder {
    enable 'Session';
    enable 'XSRFBlock',
      cookie_name    => 'PerlDance-XSRF-Token',
      meta_tag       => 'xsrf-meta',
      cookie_options => { httponly => 1, };
    enable 'XForwardedFor',
      trust => [qw( 10.0.0.0/8 172.16.0.0/20 192.168.0.0/16 )];
    $app;
}
