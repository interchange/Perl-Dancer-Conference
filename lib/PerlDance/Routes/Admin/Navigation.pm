package PerlDance::Routes::Admin::Navigation;

=head1 NAME

PerlDance::Routes::Admin::Navigation - admin routes for navigation

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;

=head1 ROUTES

=cut

get '/admin/navigation' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Navigation Admin";

    my $rset = rset('Navigation')->search(
        {
            "me.parent_id" => undef,
        },
        {
            order_by => [ "type", "scope", { -desc => "priority" } ],
        }
    );

    my $navs = [];

    while ( my $result = $rset->next ) {
        add_nav( $result, $navs );
    }

    $tokens->{navigation_list} = $navs;

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

    template 'admin/navigation', $tokens;
};

sub add_nav {
    my ( $result, $navs ) = @_;
    push @$navs, $result;
    my $children = $result->children->order_by('!priority');
    while ( my $child = $children->next ) {
        add_nav( $child, $navs );
    }
}

true;
