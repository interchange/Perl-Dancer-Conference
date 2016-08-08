package PerlDance::Routes;

=head1 NAME

PerlDance::Routes - routes for PerlDance conference application

=cut

use Dancer2 appname => 'PerlDance';
use Carp;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Email;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Routes;
use Dancer2::Plugin::TemplateFlute;
use DateTime;
use HTML::FormatText::WithLinks;
use Try::Tiny;

use PerlDance::StructuredData;
use PerlDance::Routes::Account;
use PerlDance::Routes::Admin;
use PerlDance::Routes::Data;
use PerlDance::Routes::PayPal;
use PerlDance::Routes::Profile;
use PerlDance::Routes::Survey;
use PerlDance::Routes::Talk;
use PerlDance::Routes::User;
use PerlDance::Routes::Wiki;
use Encode qw/encode/;

=head1 ROUTES

See also:
L<PerlDance::Routes::Account>,
L<PerlDance::Routes::Admin>, 
L<PerlDance::Routes::Data>,
L<PerlDance::Routes::PayPal>,
L<PerlDance::Routes::Profile>,
L<PerlDance::Routes::Survey>, 
L<PerlDance::Routes::Talk>,
L<PerlDance::Routes::User>,
L<PerlDance::Routes::Wiki>

=head2 get /

Home page

=cut

get '/' => sub {
    my $tokens = {};

    my $form = form('register-email');
    $form->reset;

    PerlDance::Routes::User::add_speakers_tokens($tokens);

    $tokens->{title} = "Vienna Austria September 2016";

    # only show 'register now' if we're before 
    my $conference = rset('Conference')->find( setting('conferences_id') );
    if ( DateTime->now < $conference->start_date && !logged_in_user ) {
        $tokens->{show_register_container} = 1;
    }

    my $news = shop_schema->resultset('Message')->search(
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

    my $news_count = $news->count;

    # we want to display at most 2 news items
    my @news = $news->rows(2)->all;

    # but we don't want the second item if it is more than 7 days old
    pop @news
      if ( $news_count > 1
        && $news[1]->created < DateTime->today->subtract( days => 7 ) );

    # and if we have old news we're not displaying then we add a link
    # to news archive
    if ( $news_count > scalar(@news) ) {
        $tokens->{old_news} = 1;
    }

    $tokens->{news} = \@news;

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
            my $news = $tokens->{news}->first;
            my $image_path;

            # check whether we got a picture inside the news
            if ($news->content =~ m%<img src="/(.*)"%) {
                debug "Picture is $1.";
                $image_path = $1;
            }
            else {
                # standard picture
            }

            # create structured data object - which might failed because of missing data
            my %ld_data;
            my $ld_output;

            if ($image_path) {
                try {
                    %ld_data = (
                        uri => var('uri'),
                        author => $news->author->name_with_nickname,
                        headline => $news->title,
                        image_uri => join('/', setting('conference_uri'), $image_path),
                        image_path => join('/', config->{public_dir}, $image_path),
                        logo_uri => join('/', setting('conference_uri'), 'img/perl-dancer-2016-logo.png'),
                        logo_path => join('/', config->{public_dir}, 'img/perl-dancer-2016-logo.png'),
                        date_published => $news->created,
                        date_modified => $news->last_modified,
                        publisher => 'Perl Dancer Conference',
                    );

                    my $ld = PerlDance::StructuredData->new(%ld_data);

                    $ld_output = $ld->out;
                }
                catch {
                    error "crashed while creating structured data: $_, data: ", \%ld_data;
                };
                $tokens->{structured_data} = $ld_output;
            }

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
    var uri => route_parameters->get('uri');
    forward '/news';
};

=head2 get /sponsors

Sponsor list

=cut

get '/sponsors' => sub {
    my $tokens = {};

    add_navigation_tokens( $tokens );

    # get list of sponsors
    my $levels_rs = schema->resultset('Navigation')->find(
        {uri => 'sponsors'})->children->active->order_by({-desc => 'me.priority'})->prefetch({
            'navigation_messages' => {'message' => {'media_messages' => 'media'}}});

    $tokens->{levels} = [$levels_rs->all];

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
          ->tickets->active->prefetch('inventory')->hri->all ];

    $tokens->{count} = @{$tokens->{tickets}};

    for my $ticket (@{$tokens->{tickets}}) {
        $ticket->{cart_uri} = uri_for('cart', {sku => $ticket->{sku}});
        $ticket->{tickets_left} = $ticket->{inventory}->{quantity};
    }

    template 'tickets', $tokens;
};

=head2 shop_setup_routes

L<Dancer::Plugin::Interchange6::Routes/shop_setup_routes>


=cut

shop_setup_routes;

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

    my $uri = var('uri') || request->path;
    $uri =~ s{^/+}{};
    my $nav = shop_navigation->find( { uri => $uri } );

    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;
}

=head2 add_tshirt_sizes( $tokens, $current_value );

Add 'shirts' iterator token with available T-shirt sizes

=cut

sub add_tshirt_sizes {
    my ( $tokens, $value ) = @_;
    my @t_shirt_sizes = @{ setting('t_shirt_sizes') };

    $tokens->{t_shirt_sizes} =
      [ map { { value => $_, label => $_ } } @t_shirt_sizes ];

    if ( !$value || !grep { $_ eq $value } @t_shirt_sizes ) {
        unshift @{ $tokens->{t_shirt_sizes} },
          { value => undef, label => "Select T-shirt size" };
    }
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

    try {
        my $template = delete $args{template};
        croak "template not supplied to send_email" unless $template;

        my $tokens = delete $args{tokens};
        croak "tokens hashref not supplied to send_email"
          unless ref($tokens) eq 'HASH';

        $tokens->{"conference-logo"} =
          uri_for( shop_schema->resultset('Media')
              ->search( { label => "email-logo" } )->first->uri );

        debug "Rendering mail $template";
        my $html = template $template, $tokens, { layout => 'email' };

        my $f    = HTML::FormatText::WithLinks->new;
        my $text = $f->parse($html);

        # the dumper shows \x{20ac}, so html and text are decoded.
        email {
            %args,
              body   => encode( 'UTF-8', $text ),
              type   => 'text',
              attach => {
                Charset  => 'utf-8',
                Data     => encode( 'UTF-8', $html ),
                Encoding => "quoted-printable",
                Type     => "text/html"
              },
              multipart => 'alternative',
        };
    }
    catch { error "Could not send email: $_"; };
}

true;
