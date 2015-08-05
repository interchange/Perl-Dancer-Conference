package PerlDance::Routes;

=head1 NAME

PerlDance::Routes - routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Dancer::Plugin::Form;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Routes;
use HTML::FormatText::WithLinks;
use Try::Tiny;

use PerlDance::Routes::Account;
use PerlDance::Routes::Admin;
use PerlDance::Routes::Data;
use PerlDance::Routes::PayPal;
use PerlDance::Routes::Profile;
use PerlDance::Routes::Talk;
use PerlDance::Routes::User;
use PerlDance::Routes::Wiki;

=head1 ROUTES

See also: L<PerlDance::Routes::Account>, L<PerlDance::Routes::Admin>, 
L<PerlDance::Routes::Data>,
L<PerlDance::Routes::PayPal>, L<PerlDance::Routes::Profile>,
L<PerlDance::Routes::Talk>, L<PerlDance::Routes::User>,
L<PerlDance::Routes::Wiki>

=head2 get /

Home page

=cut

get '/' => sub {
    my $tokens = {};

    my $form = form('register-email');
    $form->reset;

    PerlDance::Routes::User::add_speakers_tokens($tokens);

    $tokens->{title} = "Vienna Austria October 2015";

    $tokens->{news} = shop_schema->resultset('Message')->search(
        {
            'message_type.name' => 'news_item',
            'me.public'         => 1,
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => { -desc => 'me.created' },
        }
    );

    add_javascript( $tokens, "/js/index.js" );

    var no_title_wrapper => 1;

    template 'index', $tokens;
};

=head2 get /news

All news

=cut

get '/news' => sub {
    my $tokens = {};

    my $search = {
        'message_type.name' => 'news_item',
        'me.public'         => 1,
    };

    if ( var('uri') ) {
        $search->{"me.uri"} = var('uri');
    }

    $tokens->{news} = shop_schema->resultset('Message')->search(
        $search,
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => { -desc => 'me.created' },
        }
    );

    if ( $tokens->{news}->has_rows ) {
        if ( var('uri') ) {
            $tokens->{title} = $tokens->{news}->first->title;
            $tokens->{news}->reset;
        }
        else {
            $tokens->{title} = "News";
        }
    }
    else {
        $tokens->{title} = "No news is good news";
    }

    template 'news', $tokens;
};

=head2 get /news/some-uri

Specific news item

=cut

get '/news/:uri' => sub {
    var uri => param('uri');
    forward '/news';
};

=head2 get /sponsors

Sponsor list

=cut

get '/sponsors' => sub {
    my $tokens = {};

    add_navigation_tokens( $tokens );

    template 'sponsors', $tokens;
};

=head2 get /sponsoring

Be a sponsor

=cut

get '/sponsoring' => sub {
    my $tokens = {};

    add_navigation_tokens($tokens);

    template 'sponsoring', $tokens;
};

=head2 get /tickets

Conference tickets

=cut

get '/tickets' => sub {
    my $tokens = {};

    add_navigation_tokens($tokens);

    $tokens->{tickets} =
      [ shop_schema->resultset('Conference')->find( setting('conferences_id') )
          ->tickets->active->hri->all ];

    for my $ticket (@{$tokens->{tickets}}) {
        $ticket->{cart_uri} = uri_for('cart', {sku => $ticket->{sku}});
    }

    template 'tickets', $tokens;
};

=head2 shop_setup_routes

L<Dancer::Plugin::Interchange6::Routes/shop_setup_routes>


=cut

shop_setup_routes;

=head2 not_found

404

=cut

any qr{.*} => sub {
    my $tokens = {};

    $tokens->{title} = "Not Found";
    $tokens->{description} = "404 - Page not Found";

    status 'not_found';
    template '404', $tokens;
};

=head1 METHODS

=head2 add_javascript($tokens, @js_urls);

=cut

sub add_javascript {
    my $tokens = shift;
    foreach my $src ( @_ ) {
        push @{ $tokens->{"extra-js"} }, { src => $src };
    }
}

=head2 add_navigation_tokens

Add title and description tokens;

=cut

sub add_navigation_tokens {
    my $tokens = shift;

    ( my $uri = request->path ) =~ s{^/+}{};
    my $nav = shop_navigation->find( { uri => $uri } );

    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;
}

=head2 add_validator_error_tokens( $validator, $tokens )

Given a transposed L<Data::Transpose::Validator> object and template
C<$tokens> hash references as args adds C<errors> token to C<$tokens>.

=cut

sub add_validator_errors_token {
    my ( $validator, $tokens ) = @_;

    my %errors;
    my $v_hash = $validator->errors_hash;
    while ( my ( $key, $value ) = each %$v_hash ) {
        my $error = $value->[0]->{value};

        # in case we're doing EmailValid the mxcheck error is not clear
        $error = "invalid email address" if $error eq "mxcheck";

        $errors{$key} = $error;

        # flag the field with error using has-error class
        $errors{ $key . '_input' } = 'has-error';
    }
    $tokens->{errors} = \%errors;
}

=head2 send_email( $args_hash );

The following keys are required:

=over 4

=item template

=item tokens

=item to

=item subject

=back

=cut

sub send_email {
    my %args = @_;

    my $template = delete $args{template};
    die "template not supplied to send_email" unless $template;

    my $tokens = delete $args{tokens};
    die "tokens hashref not supplied to send_email"
      unless ref($tokens) eq 'HASH';

    $tokens->{"conference-logo"} =
      uri_for(
        shop_schema->resultset('Media')->search( { label => "email-logo" } )
          ->first->uri );

    my $html = template $template, $tokens, { layout => 'email' };

    my $f    = HTML::FormatText::WithLinks->new;
    my $text = $f->parse($html);

    email {
        %args,
        body => $text,
        type => 'text',
        attach => {
            Data     => $html,
            Encoding => "quoted-printable",
            Type     => "text/html"
        },
        multipart => 'alternative',
    };
}

true;
