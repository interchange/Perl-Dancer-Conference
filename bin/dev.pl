#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Builder;

use JSON::MaybeXS;
 
use Plack::Debugger;
use Plack::Debugger::Storage;
 
use Plack::App::Debugger;
 
use Plack::Debugger::Panel::AJAX;
use Plack::Debugger::Panel::Memory;
use Plack::Debugger::Panel::Parameters;
use Plack::Debugger::Panel::PlackRequest;
use Plack::Debugger::Panel::PlackResponse;
use Plack::Debugger::Panel::Timer;
use Plack::Debugger::Panel::Warnings;
 
use PerlDance;
my $app = PerlDance->to_app;
my $json = JSON::MaybeXS->new( convert_blessed => 1 );

my $debugger = Plack::Debugger->new(
    storage => Plack::Debugger::Storage->new(
        data_dir     => '/tmp/debugger_panel',
        serializer   => sub { $json->encode( shift ) },
        deserializer => sub { $json->decode( shift ) },
        filename_fmt => "%s.json",
    ),
    panels => [
        Plack::Debugger::Panel::AJAX->new, 
        Plack::Debugger::Panel::Memory->new,
        Plack::Debugger::Panel::Parameters->new,
        Plack::Debugger::Panel::PlackRequest->new,
        Plack::Debugger::Panel::PlackResponse->new,
        Plack::Debugger::Panel::Timer->new,     
        Plack::Debugger::Panel::Warnings->new   
    ]
);
 
my $debugger_app = Plack::App::Debugger->new( debugger => $debugger );
 
builder {
    enable 'Session';
    enable 'XSRFBlock',
      cookie_name    => 'PerlDance-XSRF-Token',
      meta_tag       => 'xsrf-meta',
      cookie_options => { httponly => 1, };

    mount $debugger_app->base_url => $debugger_app->to_app;

    mount '/' => builder {
        enable $debugger_app->make_injector_middleware;
        enable $debugger->make_collector_middleware;
        $app;
    }
};

#use Plack::Middleware::Debug::DBIC::QueryLog;
#use Plack::Middleware::DBIC::QueryLog;
#use Dancer2;
#use Dancer2::Plugin::DBIC;
#use Dancer::Handler;
#use lib 'lib';
#use PerlDance;

#my $app = sub {
#    load_app "PerlDance";
#    Dancer::App->set_running_app("PerlDance");
#    my $env = shift;
#    my $schema = schema->clone;
#    my $querylog =
#      Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
#    $schema->storage->debug(1);
#        $schema->storage->debugobj($querylog);
#    Dancer::Handler->init_request_headers($env);
#    my $req = Dancer::Request->new( env => $env );
#    Dancer->dance($req);
#};

#builder {
#    enable 'Session';
#    enable 'XSRFBlock',
#      cookie_name => 'PerlDance-XSRF-Token',
#      meta_tag => 'xsrf-meta',
#      cookie_options => {
#          httponly => 1,
#      };
#    enable 'Debug',
#      panels => [
#        'Parameters',                'Dancer::Version',
#        'Dancer::Settings',          'Dancer::Logger',
#        'Dancer::TemplateVariables', 'DBIC::QueryLog',
#        'Timer',#                     'Profiler::NYTProf',
#      ];
#    $app;
#};
