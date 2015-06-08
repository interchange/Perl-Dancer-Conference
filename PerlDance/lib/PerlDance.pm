package PerlDance;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/speakers' => sub {
    template 'speakers';
};

get '/speakers/:speaker' => sub {
    my $speaker = param 'speaker';
    template 'speaker_detail';
};

true;
