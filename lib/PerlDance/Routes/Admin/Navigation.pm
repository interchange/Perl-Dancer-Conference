package PerlDance::Routes::Admin::Navigation;

=head1 NAME

PerlDance::Routes::Admin::Navigation - admin routes for navigation

=cut

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::TemplateFlute;
use Try::Tiny;

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
    my $source = route_parameters->get('source');
    my $target = route_parameters->get('target');
    my $response = 0;

    my $parent = rset('Navigation')->find($target);
    my $child = rset('Navigation')->find($source);
    if ( $parent && $child ) {
        $response = $parent->attach_child($child);
    }
    content_type('application/json');
    return to_json({ response => $response });
};

=head2 post /admin/navigation/create

=cut

post '/admin/navigation/create' => require_role admin => sub {

    try {
        rset('Navigation')->create(
            {
                uri         => body_parameters->get('uri')         || undef,
                type        => body_parameters->get('type')        || '',
                scope       => body_parameters->get('scope')       || '',
                name        => body_parameters->get('name')        || '',
                description => body_parameters->get('description') || '',
                alias       => body_parameters->get('alias')       || undef,
                parent_id   => body_parameters->get('parent_id')   || undef,
                priority    => body_parameters->get('priority')    || 0,
                active      => defined body_parameters->get('active')
                               ? body_parameters->get('active')
                               : 1,
            }
        );
    }
    catch {
        warning "Create nav failed: ", $_;
    };
    redirect '/admin/navigation';
};

=head2 get /admin/navigation/delete/:id

=cut

get '/admin/navigation/delete/:id' => require_role admin => sub {
    my $id = route_parameters->get('id');
    my $nav = rset('Navigation')->find($id);
    $nav->delete if $nav;
    redirect '/admin/navigation';
};

=head2 post /admin/navigation/edit

=cut

post '/admin/navigation/edit' => require_role admin => sub {
    my $nav = rset('Navigation')->find( body_parameters->get('navigation_id') );
    if ($nav) {
        try {
            $nav->update(
                {
                    uri         => body_parameters->get('uri')         || undef,
                    type        => body_parameters->get('type')        || '',
                    scope       => body_parameters->get('scope')       || '',
                    name        => body_parameters->get('name')        || '',
                    description => body_parameters->get('description') || '',
                    alias       => body_parameters->get('alias')       || undef,
                    parent_id   => body_parameters->get('parent_id')   || undef,
                    priority    => body_parameters->get('priority')    || 0,
                    active      => defined body_parameters->get('active')
                                   ? body_parameters->get('active')
                                   : 1,
                }
            );
        }
        catch {
            warning "Update nav failed: ", $_;
        };
    }
    redirect '/admin/navigation';
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
