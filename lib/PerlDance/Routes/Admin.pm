package PerlDance::Routes::Admin;

=head1 NAME

PerlDance::Routes::Admin - admin routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Interchange6;

=head1 ROUTES 

=head2 get /admin

=cut

get '/admin' => require_role admin => sub {
    my $tokens = {};
    $tokens->{title} = "Admin";
    template 'admin', $tokens;
};

get '/admin/news' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "News Admin";

    $tokens->{news} = rset('Message')->search(
        {
            "message_type.name" => "news_item",
        },
        {
            join     => "message_type",
            order_by => "created",
        }
    );
    template 'admin/news', $tokens;
};

get '/admin/news/create' => require_role admin => sub {
    my $tokens = {};
    $tokens->{title} = "Create News";
    $tokens->{news}->{public} = 1;
    template 'admin/news/create_update', $tokens;
};

post '/admin/news/create' => require_role admin => sub {
    my $tokens = {};
    template 'admin/news/create_update', $tokens;
};

true;
