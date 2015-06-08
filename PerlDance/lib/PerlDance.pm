package PerlDance;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Interchange6;

our $VERSION = '0.1';

set session => 'DBIC';
set session_options => { schema => schema };

get '/' => sub {
    my $tokens = {};

    add_speakers_tokens($tokens);

    template 'index', $tokens;
};

get '/speakers' => sub {
    my $tokens = {};

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
            join => { photo => 'displays' }
        }
    )->all;

    my @grid;
    while ( my @row = splice( @speakers, 0, 4 ) ) {
        push @grid, +{ row => \@row };
    }

    $tokens->{speakers} = \@grid;
}

true;
