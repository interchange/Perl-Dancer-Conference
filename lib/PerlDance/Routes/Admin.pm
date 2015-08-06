package PerlDance::Routes::Admin;

=head1 NAME

PerlDance::Routes::Admin - admin routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use Try::Tiny;

use PerlDance::Routes::Admin::Navigation;
use PerlDance::Routes::Admin::Talks;
use PerlDance::Routes::Admin::Users;

=head1 ROUTES 

See also:

L<PerlDance::Routes::Admin::Navigation>, L<PerlDance::Routes::Admin::Talks>,
L<PerlDance::Routes::Admin::Users>

=head2 get /admin

=cut

get '/admin' => require_role admin => sub {
    my $tokens = {};

    my $nav = rset('Navigation')->find( { uri => 'admin' } );

    $tokens->{title} = $nav->description;

    $tokens->{nav} = $nav->children->search( { active => 1 },
        { order_by => [ { -desc => 'priority' }, 'name' ] } );

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

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

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

    my $form   = form('update_create_news');
    my %values = %{ $form->values };
    $values{content} =~ s/\r\n/\n/g;
    $values{type}            = "news_item";
    $values{author_users_id} = logged_in_user->id;
    $values{public} ||= 0;

    # TODO: validate values and if OK then try create
    rset('Message')->create(
        {
            type            => "news_item",
            author_users_id => logged_in_user->id,
            public          => $values{public} || 0,
            title           => $values{title},
            uri             => $values{uri} || undef,
            content         => $values{content},
        }
    );
    return redirect '/admin/news';
};

get '/admin/news/delete/:id' => require_role admin => sub {
    try {
        rset('Message')->find( param('id') )->delete;
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

    my $form = form('update_create_news');
    $form->reset;

    $form->fill(
        {
            messages_id => $news->messages_id,
            title       => $news->title,
            public      => $news->public,
            uri         => $news->uri,
            content     => $news->content,
        }
    );

    $tokens->{form}    = $form;
    $tokens->{title}   = "Edit News";

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

    my $form   = form('update_create_news');
    my %values = %{ $form->values };
    $values{content} =~ s/\r\n/\n/g;

    # TODO: validate values and if OK then try update
    $news->update(
        {
            author_users_id => logged_in_user->id,
            public          => $values{public} || 0,
            title           => $values{title},
            uri             => $values{uri} || undef,
            content         => $values{content},
        }
    );
    return redirect '/admin/news';
};

true;
