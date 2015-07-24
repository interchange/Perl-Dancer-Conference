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

    PerlDance::Routes::add_javascript( $tokens, '/js/admin_news.js' );

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

=head2 admin/talks

=cut

get '/admin/talks' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Talk Admin";

    $tokens->{talks} = rset('Talk')->search(
        {
            conferences_id => setting('conferences_id'),
        },
    );

    PerlDance::Routes::add_javascript( $tokens, '/js/admin_news.js' );

    template 'admin/talks', $tokens;
};

get '/admin/talks/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create Talk";

    my $form = form('update_create_talk');
    $form->reset;
    $form->fill(
        {
            accepted   => 1,
            confirmed  => 0,
            lightning  => 0,
            start_time => schema->format_datetime( DateTime->now )
        }
);
    $tokens->{form} = $form;
    $tokens->{author} = [ rset('User')->all];
    template 'admin/talks/create_update', $tokens;
};

post '/admin/talks/create' => require_role admin => sub {
    my $tokens = {};

    my $form   = form('update_create_talk');
    my %values = %{ $form->values };
    debug "values", \%values;
    $values{abstract} =~ s/\r\n/\n/g;

    # TODO: validate values and if OK then try create
    rset('Talk')->create(
        {
            author_id => $values{author},
            conferences_id  => setting('conferences_id'),
            duration        => $values{duration},
            title           => $values{title},
            tags            => $values{tags},
            abstract        => $values{abstract},
            url             => $values{url} || undef,
            comments        => $values{comments},
            accepted        => $values{accepted} || 0,
            confirmed       => $values{confirmed},
            lightning       => $values{lightning} || 0,
            start_time      => $values{start_time},
            room            => $values{room}
        }
    );
    return redirect '/admin/talks';
};

get '/admin/talks/delete/:id' => require_role admin => sub {
    try {
        rset('Talk')->find( param('id') )->delete;
    };
    redirect '/admin/talks';
};

get '/admin/talks/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $talk = rset('Talk')->find( param('id') );

    if ( !$talk ) {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('update_create_talk');
    $form->reset;

    $form->fill(
        {
            author_id       => $talk->author_id,
            duration        => $talk->duration,
            title           => $talk->title,
            tags            => $talk->tags,
            abstract        => $talk->abstract,
            url             => $talk->url,
            comments        => $talk->comments,
            accepted        => $talk->accepted,
            confirmed       => $talk->confirmed,
            lightning       => $talk->lightning,
            start_time      => schema->format_datetime($talk->start_time),
            room            => $talk->room
        }
    );
    $tokens->{author} = [ rset('User')->all];
    $tokens->{form}    = $form;
    $tokens->{title}   = "Edit Talk";

    template 'admin/talks/create_update', $tokens;
};

post '/admin/talks/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $talk = rset('Talk')->find( param('id') );

    if ( !$talk ) {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form   = form('update_create_talk');
    my %values = %{ $form->values };
    $values{abstract} =~ s/\r\n/\n/g;

    # TODO: validate values and if OK then try update
    $talk->update(
        {
            author_id       => $values{author},
            duration        => $values{duration},
            title           => $values{title},
            tags            => $values{tags},
            abstract        => $values{abstract},
            url             => $values{url} || undef,
            comments        => $values{comments},
            accepted        => $values{accepted} || 0,
            confirmed       => $values{confirmed},
            lightning       => $values{lightning} || 0,
            start_time      => $values{start_time},
            room            => $values{room}

        }
    );
    return redirect '/admin/talks';
};

true;
