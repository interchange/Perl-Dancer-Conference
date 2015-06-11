package PerlDance;

=head1 NAME

PerlDance - Perl Dancer 2015 conference site

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Routes;

our $VERSION = '0.1';

set session => 'DBIC';
set session_options => { schema => schema };

=head1 HOOKS

=head2 before_layout_render

Add navigation (menus).

=cut

hook 'before_layout_render' => sub {
    my $tokens = shift;

    my @nav = shop_navigation->search(
        {
            'me.active'    => 1,
            'me.type'      => 'nav',
            'me.parent_id' => undef,
        },
        {
            order_by => [ { -desc => 'me.priority' }, 'me.name', ],
        }
    )->hri->all;

    # add class to highlight current page in menu
    foreach my $record (@nav) {
        my $path = request->path;
        $path =~ s/^\///;
        if ( $path eq $record->{uri} ) {
            $record->{class} = "active";
        }
        push @{ $tokens->{ 'nav-' . $record->{scope} } }, $record;
    }
    if ( logged_in_user ) {
        delete $tokens->{"nav-top-login"};
    }
    else {
        delete $tokens->{"nav-top-logout"};
    }
};

=head1 ROUTES

=head2 get /

Home page

=cut

get '/' => sub {
    my $tokens = {};

    add_speakers_tokens($tokens);

    $tokens->{body_class} = "home page";
    $tokens->{title} = "Vienna Austria October 2015";

    add_javascript( $tokens, "//maps.google.com/maps/api/js?sensor=false",
        "/js/index.js" );

    template 'index', $tokens;
};

=head2 get /speakers

Speaker list

=cut

get '/speakers' => sub {
    my $tokens = {};

    my $nav = shop_navigation->find( { uri => 'speakers' } );
    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;

    add_speakers_tokens($tokens);

    $tokens->{body_class} = "page";
    $tokens->{title} = "Speakers";

    template 'speakers', $tokens;
};

=head2 get /speakers/{id}.*

Individual speaker

=cut

get qr{/speakers/(?<id>\d+).*} => sub {
    my $users_id = captures->{id};
    my $tokens = {};

    $tokens->{user} = shop_user->search(
        {
            'me.users_id'    => $users_id,
            'addresses.type' => 'primary',
        },
        {
            prefetch =>
              [ { addresses => 'country', }, 'photo', 'talks_authored' ],
        }
    )->first;

    if ( !$tokens->{user} ) {
        status 'not_found';
        return "Speaker not found";
    }

    $tokens->{has_talks} = 1 if $tokens->{user}->talks_authored->has_rows;

    $tokens->{body_class} = "single single-speaker";
    $tokens->{title} = $tokens->{user}->name;

    template 'speaker', $tokens;
};

=head2 get /talks

Talks list

=cut

get '/talks' => sub {
    my $tokens = {};

    my $talks = shop_schema->resultset('Talk')->search(
        {
            accepted => 1,
        },
        {
            order_by => 'start_time',
            prefetch => 'author',
        }
    );
    my %days;
    while ( my $talk = $talks->next ) {
        my $day_zero = 18;
        my $day_number = 0;
        if ( defined $talk->start_time ) {
            $day_number = $talk->start_time->day - $day_zero;
        }
        push @{ $days{$day_number} }, $talk;
    };
    my $unscheduled;
    foreach my $day ( sort keys %days ) {
        my $value = $days{$day};
        my $date = $value->[0]->start_time;
        if ( $day > 0 ) {
            push @{ $tokens->{talks} },
              {
                day   => "Day $day",
                date  => $date,
                talks => $value,
              };
        }
        else {
            $unscheduled = {
                day   => 'Unscheduled',
                date  => undef,
                talks => $value,
            };
        }
    }
    push @{ $tokens->{talks} }, $unscheduled if $unscheduled;

    $tokens->{body_class} = "page";
    $tokens->{title} = "Schedule";

    template 'talks', $tokens;
};

=head2 get /talks/submit

CFP

=cut

get '/talks/submit' => sub {
    my $tokens = {};

    $tokens->{body_class} = "page";
    $tokens->{title} = "Call For Papers";

    template 'cfp', $tokens;
};

=head2 get /talks/{id}.*

Individual talk

=cut

get qr{/talks/(?<id>\d+).*} => sub {
    my $talks_id = captures->{id};
    my $tokens = {};

    $tokens->{talk} = shop_schema->resultset('Talk')->search(
        {
            'me.talks_id' => $talks_id,
        },
        {
            prefetch => [ 'author', { attendee_talks => 'user' } ],
        }
    )->first;

    $tokens->{body_class} = "single single-session";
    $tokens->{title} = $tokens->{talk}->title;

    template 'talk', $tokens;
};

=head2 get /tickets

Conference tickets

=cut

get '/tickets' => sub {
    my $tokens = {};

    $tokens->{body_class} = "page";
    $tokens->{title} = "Tickets";

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

    $tokens->{body_class} = "single single-ticket";
    $tokens->{title} = "Not Found";

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

=head2 add_speakers_tokens($tokens);

Add tokens needed by speakers fragment

=cut

sub add_speakers_tokens {
    my $tokens = shift;

    my @speakers = shop_user->search(
        {
            'addresses.type' => 'primary',
        },
        {
            prefetch => [ { addresses => 'country', }, 'photo' ],
        }
    )->all;

    my @grid;
    while ( my @row = splice( @speakers, 0, 4 ) ) {
        push @grid, +{ row => \@row };
    }

    $tokens->{speakers} = \@grid;
}

true;
