#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Builder;

use PerlDance;
use DBICx::Sugar qw/schema/;
use Dancer2::Debugger;
use Plack::Middleware::DBIC::QueryLog;

my $mw = sub {
    my $app = shift;
    sub {
        my $env = shift;
        my $querylog =
          Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
        my $cloned_schema = schema->clone;
        $cloned_schema->storage->debug(1);
        $cloned_schema->storage->debugobj($querylog);
        my $res = $app->($env);
        return $res;
    };
};
my $app = $mw->( PerlDance->to_app );

my $debugger = Dancer2::Debugger->new(
    panels => [
        'Plack::Debugger::Panel::AJAX',
        'Plack::Debugger::Panel::Dancer2::Logger',
        #'Plack::Debugger::Panel::Dancer2::Routes',
        'Plack::Debugger::Panel::Dancer2::Session',
        #'Plack::Debugger::Panel::Dancer2::Settings',
        'Plack::Debugger::Panel::Dancer2::TemplateTimer',
        'Plack::Debugger::Panel::Dancer2::TemplateVariables',
        'Plack::Debugger::Panel::DBIC::QueryLog',
        #'Plack::Debugger::Panel::Environment',
        'Plack::Debugger::Panel::Memory',
        #'Plack::Debugger::Panel::ModuleVersions',
        'Plack::Debugger::Panel::Parameters',
        #'Plack::Debugger::Panel::PerlConfig',
        'Plack::Debugger::Panel::PlackRequest',
        'Plack::Debugger::Panel::PlackResponse',
        'Plack::Debugger::Panel::Timer',
        'Plack::Debugger::Panel::Warnings',
    ]
);

builder {
    enable 'DBIC::QueryLog';
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
