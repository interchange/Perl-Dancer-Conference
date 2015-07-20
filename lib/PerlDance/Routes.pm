package PerlDance::Routes;

=head1 NAME

PerlDance::Routes - routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Routes;
use Try::Tiny;

use PerlDance::Routes::Account;
use PerlDance::Routes::Admin;
use PerlDance::Routes::Talk;

=head1 ROUTES

See also: L<PerlDance::Routes::Account>, L<PerlDance::Routes::Talk>

=head2 get /

Home page

=cut

get '/' => sub {
    my $tokens = {};

    add_speakers_tokens($tokens);

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

    add_javascript( $tokens, "//maps.google.com/maps/api/js?sensor=false",
        "/js/index.js" );

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

=head2 get /speakers

Speaker list

=cut

get '/speakers' => sub {
    my $tokens = {};

    add_navigation_tokens( $tokens );
    add_speakers_tokens($tokens);

    $tokens->{title} = "Speakers";

    template 'speakers', $tokens;
};

=head2 get /speakers/{id}.*

Individual speaker

=cut

get qr{/speakers/(?<id>\d+).*} => sub {
    my $users_id = captures->{id};
    my $tokens = {};

    var no_title_wrapper => 1;

    $tokens->{user} = shop_user->search(
        {
            'me.users_id'                         => $users_id,
            'conferences_attended.conferences_id' => setting('conferences_id'),
            'addresses.type'                      => 'primary',
        },
        {
            prefetch =>
              [ { addresses => 'country', }, 'photo' ],
            join => 'conferences_attended',
            rows => 1,
        }
    )->first;

    if ( !$tokens->{user} ) {
        $tokens->{title} = "Speaker Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{talks} = $tokens->{user}->search_related(
        'talks_authored',
        {
            conferences_id => setting('conferences_id'),
            accepted       => 1,
            confirmed      => 1,
        }
    );

    $tokens->{has_talks} = 1 if $tokens->{talks}->has_rows;

    $tokens->{title} = $tokens->{user}->name;

    template 'speaker', $tokens;
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

=head2 add_speakers_tokens($tokens);

Add tokens needed by speakers fragment

=cut

sub add_speakers_tokens {
    my $tokens = shift;

    my @speakers = shop_user->search(
        {
            'addresses.type'                      => 'primary',
            'conferences_attended.conferences_id' => setting('conferences_id'),
            -or                                   => {
                'talks_authored.accepted'  => 1,
                'talks_authored.confirmed' => 1,
                -and                       => {
                    'attribute.name' => 'speaker',
                    'attribute.type' => 'boolean',
                },
            },
        },
        {
            prefetch => [ { addresses => 'country', }, 'photo' ],
            join     => [
                'conferences_attended', 'talks_authored',
                { user_attributes => 'attribute' }
            ],
        }
    )->all;

    my @grid;
    while ( my @row = splice( @speakers, 0, 4 ) ) {
        push @grid, +{ row => \@row };
    }

    $tokens->{speakers} = \@grid;
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

true;
