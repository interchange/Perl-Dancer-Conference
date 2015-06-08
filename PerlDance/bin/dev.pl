#!/usr/bin/env perl
#use Dancer;
#use DanceShop;
#dance;

use Plack::Builder;
use Plack::Middleware::Debug::DBIC::QueryLog;
use Plack::Middleware::DBIC::QueryLog;
use Dancer;
use Dancer::Plugin::DBIC;
use Dancer::Handler;
use lib 'lib';
use PerlDance;

my $app = sub {
    load_app "PerlDance";
    Dancer::App->set_running_app("PerlDance");
    my $env = shift;
    my $schema = schema->clone;
    my $querylog =
      Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
    $schema->storage->debug(1);
        $schema->storage->debugobj($querylog);
    Dancer::Handler->init_request_headers($env);
    my $req = Dancer::Request->new( env => $env );
    Dancer->dance($req);
};

builder {
    enable 'Debug',
      panels => [
        'Parameters',                'Dancer::Version',
        'Dancer::Settings',          'Dancer::Logger',
        'Dancer::TemplateVariables', 'DBIC::QueryLog',
        'Timer',#                     'Profiler::NYTProf',
      ];
    mount "/" => $app;
};
