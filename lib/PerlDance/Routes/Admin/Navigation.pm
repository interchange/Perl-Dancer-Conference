package PerlDance::Routes::Admin::Navigation;

=head1 NAME

PerlDance::Routes::Admin::Navigation - admin routes for navigation

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;

=head1 ROUTES

=head2 get /admin/navigation

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

    PerlDance::Routes::add_javascript( $tokens,
        '//code.jquery.com/ui/1.11.4/jquery-ui.min.js',
        '/js/admin.js', '/js/jquery.treetable.js', '/js/admin-navigation.js' );

    template 'admin/navigation', $tokens;
};

=head2 get /admin/navigation/move/:source/:target

Move :source nav to be a child of :target

=cut

get '/admin/navigation/move/:source/:target' => require_role admin => sub {
    my $source = param 'source';
    my $target = param 'target';
    my $response = 0;

    my $parent = rset('Navigation')->find($target);
    my $child = rset('Navigation')->find($source);
    if ( $parent && $child ) {
        $response = $parent->attach_child($child);
    }
    content_type('application/json');
    return to_json({ response => $response });
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
