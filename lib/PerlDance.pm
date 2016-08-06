package PerlDance;

=head1 NAME

PerlDance - Perl Dancer 2016 conference site

=cut

use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Debugger;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Routes;

use PerlDance::Routes;

our $VERSION = '0.1';

set conferences_id => shop_schema->resultset('Conference')
  ->find( { name => setting 'conference_name' } )->id;

=head1 INSTALLATION

=head2 LIBRARIES

Before you start with the installation, you need to install
a number of development packages for libraries to get the
full functionality of this application.

=head3 IMAGER

In order to support all common image formats, you need to
install the development packages before installing L<Imager>.

On Debian, you can install them as follows:

   apt-get install libjpeg-dev libpng-dev libgif-dev libtiff-dev libfreetype6-dev

=head3 GEO-IP

On Debian, install as follows:

   apt-get install geoip-bin libgeoip-dev geoip-database-contrib

=head1 HOOKS

=head2 before_cart_display

Add quantity_iterator token.

For ajax requests the cart table fragment is returned.

For non-ajax requests add the cart-specific js file and return.

=cut

hook 'before_cart_display' => sub {
    my $tokens = shift;

    $tokens->{quantity_iterator} =
      [ map { +{ value => $_ } } ( 1 .. 9, '10+' ) ];

    if ( request->is_ajax ) {

        my $html = template( "/fragments/cart", $tokens, { layout => undef } );
        $html =~ s/^.*?body>//;
        $html =~ s/<\/body.*?$//;

        send_as JSON => +{ html => $html };
    }
    elsif ( request->is_post ) {

        # Posts to cart should generally result in redirect.
        # FIXME: This should be addressed in DPIC6 and not here
        return redirect '/cart';
    }
    else {
        PerlDance::Routes::add_javascript( $tokens, "/js/cart.js" );
        $tokens->{title} = "Cart";

        if (config->{paypal}->{maintenance}) {
            $tokens->{'paypal-action'} = 'maintenance';
        }
        else {
            $tokens->{'paypal-action'} = 'setrequest';
        }
    }
};

=head2 before_error_init

On error set the var 'hide_sidebar' to truthy value. This can then be checked
in L</before_layout_render> hook to make sure the sidebar is not displayed.

=cut

hook before_error_init => sub {
    var hide_sidebar => 1;
};

=head2 before_template_render

=cut

hook 'before_template_render' => sub {
    my $tokens = shift;

    if ( my $user = logged_in_user ) {
        # D2PAE::Provider::DBIC returns a hashref not a row obj so to save
        # us having to change code elsewhere get ourselves an object
        $tokens->{logged_in_user} = schema->current_user;
    }

    $tokens->{conference_name} = setting('conference_name');
};

=head2 before_layout_render

Add navigation (menus).

=cut

hook 'before_layout_render' => sub {
    my $tokens = shift;

    my $nav = shop_navigation->search(
        {
            'me.active'       => 1,
            'me.type'         => 'nav',
            'me.parent_id'    => undef,
            'children.active' => [ undef, 1 ],
        },
        { prefetch => 'children', }
      )->order_by('!me.priority,me.name,!children.priority,children.name');

    # ugly hack so issue raised:
    # https://github.com/interchange/interchange6-schema/issues/186
    if ( !logged_in_user ) {
        $nav = $nav->search(
            { 'children.uri' => [ undef, { '!=' => 'myschedule' } ] },
        );
    }

    my @nav = $nav->hri->all;

    # add class to highlight current page in menu
    foreach my $record (@nav) {
        my $path = request->path;
        $path =~ s/^\///;
        if ( $record->{uri} && $path eq $record->{uri} ) {
            $record->{class} = "active";
        }
        push @{ $tokens->{ 'nav-' . $record->{scope} } }, $record;
    }

    # maybe add admin menu
    if ( logged_in_user && user_has_role('admin') ) {
        $tokens->{is_admin} = 1;
    }

    $tokens->{"head-title"} =
      setting('conference_name') . " | " . ( $tokens->{title} || '' );
    $tokens->{"meta-description"} =
      setting('conference_name') . ". " . ( $tokens->{description} || '' );
    $tokens->{title_wrapper} = 1 unless var('no_title_wrapper');

    # display sidebar?
    if ( !var('hide_sidebar')
        && request->path =~ m{^/($|events|speakers|talks|tickets|users/)} )
    {
        $tokens->{show_sidebar} = 1;

        # add sponsor tokens
        $tokens->{levels} = [schema->resultset('Navigation')->find({uri => 'sponsors'})->children->active->order_by({-desc => 'me.priority'})->prefetch({'navigation_messages' => {'message' => {'media_messages' => 'media'}}})->all ];
    }
};

=head1 ROUTES

See L<PerlDance::Routes>

=cut

true;
