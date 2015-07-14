package PerlDance::Routes::Admin;

=head1 NAME

PerlDance::Routes::Admin - admin routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use Try::Tiny;

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
            join     => [ "message_type", "author" ],
            order_by => "created",
        }
    );
    template 'admin/news', $tokens;
};

get '/admin/news/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create News";

    my $form = form('update_create_news');
    $form->reset;
    $form->fill( { public => 1 } );
    $tokens->{form} = $form;

    template 'admin/news/create_update', $tokens;
};

post '/admin/news/create' => require_role admin => sub {
    my $tokens = {};

    my $form = form('update_create_news');
    my %values = %{$form->values};
    $values{type} = "news_item";
    $values{author_users_id} = logged_in_user->id;

    # TODO: validate
    rset('Message')->create(\%values);
    return redirect '/admin/news';
};

get '/admin/news/delete/:id' => require_role admin => sub {
    try {
        rset('Message')->find(param('id'))->delete;
    };
    redirect '/admin/news';
};

get '/admin/news/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $news = rset('Message')->find( param('id') );

    if ( !$news ) {
        $tokens->{title} = "News Item Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{title} = "Edit News";

    my $form = form('update_create_news');
    $form->reset;
    $form->fill(
        {
            messages_id => $news->messages_id,
            title       => $news->title,
            public      => $news->public,
            content     => $news->content
        }
    );
    $tokens->{form} = $form;

    template 'admin/news/create_update', $tokens;
};

post '/admin/news/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $news = rset('Message')->find( param('id') );

    if ( !$news ) {
        $tokens->{title} = "News Item Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('update_create_news');
    my %values = %{$form->values};
    $values{author_users_id} = logged_in_user->id;

    # TODO: validate
    rset('Message')->update(\%values);
    return redirect '/admin/news';
};

true;
