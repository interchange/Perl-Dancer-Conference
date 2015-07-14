package PerlDance::Routes::Admin;

=head1 NAME

PerlDance::Routes::Admin - admin routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Interchange6;

=head1 ROUTES 

=head2 get /admin

=cut

get '/admin' => require_role admin => sub {
    my $tokens = {};
    $tokens->{title} = "Admin";
    template 'admin', $tokens;
};

true;
