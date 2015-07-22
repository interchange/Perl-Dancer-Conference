package PerlDance;

=head1 NAME

PerlDance - Perl Dancer 2015 conference site

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashNote;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Routes;
use PerlDance::Routes;
use Try::Tiny;

our $VERSION = '0.1';

set session => 'DBIC';
set session_options => { schema => shop_schema };

set conferences_id => shop_schema->resultset('Conference')
  ->find( { name => setting 'conference_name' } )->id;

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

        content_type 'application/json';

        my $html = template( "/fragments/cart", $tokens, { layout => undef } );
        $html =~ s/^.*?body>//;
        $html =~ s/<\/body.*?$//;

        Dancer::Continuation::Route::Templated->new(
            return_value => to_json( { html => $html } ) )->throw;
    }
    elsif ( request->is_post ) {

        # Posts to cart should generally result in redirect.
        # FIXME: This should be addressed in DPIC6 and not here
        return redirect '/cart';
    }
    else {
        PerlDance::Routes::add_javascript( $tokens, "/js/cart.js" );
        $tokens->{title} = "Cart";
    }
};

=head2 before_template_render

=cut

hook 'before_template_render' => sub {
    my $tokens = shift;
    $tokens->{logged_in_user}  = logged_in_user;
    $tokens->{conference_name} = setting('conference_name');
};

=head2 before_layout_render

Add navigation (menus).

=cut

hook 'before_layout_render' => sub {
    my $tokens = shift;

    my @nav = shop_navigation->search(
        {
            'me.active'       => 1,
            'me.type'         => 'nav',
            'me.parent_id'    => undef,
            'children.active' => [ undef, 1 ],
        },
        { prefetch => 'children', }
      )->order_by('!me.priority,me.name,!children.priority,children.name')
      ->hri->all;

    # add class to highlight current page in menu
    foreach my $record (@nav) {
        my $path = request->path;
        $path =~ s/^\///;
        if ( $record->{uri} && $path eq $record->{uri} ) {
            $record->{class} = "active";
        }
        push @{ $tokens->{ 'nav-' . $record->{scope} } }, $record;
    }
    if (logged_in_user) {
        delete $tokens->{"nav-top-login"};
        if ( user_has_role('admin') ) {
            unshift @{ $tokens->{"nav-top-logout"} },
              { name => "Admin", uri => "admin" };
        }
    }
    else {
        delete $tokens->{"nav-top-logout"};
    }

    $tokens->{"head-title"} =
      setting('conference_name') . " | " . ( $tokens->{title} || '' );
    $tokens->{"meta-description"} =
      setting('conference_name') . ". " . ( $tokens->{description} || '' );
    $tokens->{title_wrapper} = 1 unless var('no_title_wrapper');

    # flash alerts
    my $flash = flash_flush;
    foreach my $key ( keys %$flash ) {
        foreach my $message ( @{$flash->{$key}} ) {
            push @{$tokens->{alerts}->{$key}}, { message => $message };
        }
    }
};

hook after_layout_render => sub {
    flash_flush;
};

=head1 ROUTES

See L<PerlDance::Routes>

=cut

true;
