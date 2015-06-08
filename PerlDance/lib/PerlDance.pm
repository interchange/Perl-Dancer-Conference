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

get '/speakers/:id' => sub {
    my $users_id = param 'id';
    template 'speaker_detail';
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
