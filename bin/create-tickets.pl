#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Dancer qw/:script/;
use Dancer::Plugin::DBIC;
binmode STDOUT, ':encoding(UTF-8)';

my $schema = schema;

my @users = $schema->resultset('Conference')
  ->search({ name => config->{conference_name} })
  ->search_related(conferences_attendees => { confirmed => 1 })
  ->search_related(user => {} => { order_by => 'last_name' })
  ->all;

my $count;
foreach my $user (@users) {
    print join(' ', ++$count, $user->first_name, $user->last_name, $user->nickname || '') . "\n";
}






