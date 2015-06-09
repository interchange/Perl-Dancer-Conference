package PerlDance;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Interchange6;

our $VERSION = '0.1';

set session => 'DBIC';
set session_options => { schema => schema };

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
            $record->{class} = "current-page";
        }
        push @{ $tokens->{ 'nav-' . $record->{scope} } }, $record;
    }
};

get '/' => sub {
    my $tokens = {};

    add_speakers_tokens($tokens);

    template 'index', $tokens;
};

get '/speakers' => sub {
    my $tokens = {};

    my $nav = shop_navigation->find( { uri => 'speakers' } );
    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;

    add_speakers_tokens($tokens);

    template 'speakers', $tokens;
};

get qr{/speakers/(?<id>\d+).*} => sub {
    my $users_id = captures->{id};
    my $tokens = {};

    $tokens->{user} = shop_user($users_id);

    if ( !$tokens->{user} ) {
        status 'not_found';
        return "Speaker not found";
    }

    template 'speaker', $tokens;
};

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
    while ( my ( $day, $value ) = each %days ) {
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

    template 'talks', $tokens;
};

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
