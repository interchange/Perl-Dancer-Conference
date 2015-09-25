package PerlDance::Routes::Admin;

=head1 NAME

PerlDance::Routes::Admin - admin routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use Try::Tiny;

use PerlDance::Routes::Admin::Events;
use PerlDance::Routes::Admin::Navigation;
use PerlDance::Routes::Admin::Talks;
use PerlDance::Routes::Admin::Users;

=head1 ROUTES 

See also:

L<PerlDance::Routes::Admin::Events>,
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

get '/admin/tickets' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Tickets Sold";
    
    my $orders = rset('Order');

    $tokens->{orders} = $orders->search(
        {
            payment_status => 'paid',
        },
        {
            prefetch => 'user',
            order_by => 'orders_id',
        }
    )->with_status;

    template 'admin/tickets', $tokens;
};

get '/admin/t-shirts' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "T-shirts required";
    $tokens->{description} = "Confirmed users only";
    
    my $users = rset('User')->search(
        {
            'conferences_attended.conferences_id' => setting('conferences_id'),
            'conferences_attended.confirmed'      => 1,
        },
        {
            columns => [
                'users_id', 'username', 'first_name', 'last_name',
                't_shirt_size',
            ],
            join => 'conferences_attended',
            order_by => [qw/first_name last_name/],
        }
    );

    my $i = 0;
    my %t_shirt_sizes =
      map { $_ => $i++ } ( @{ setting('t_shirt_sizes') }, 'Unknown' );

    $tokens->{total_shirts} = 0;

    my %shirts;
    while ( my $user = $users->next ) {

        my $name = $user->name =~ /\S/ ? $user->name : $user->username;

        my $size = $user->t_shirt_size || 'Unknown';
        $shirts{$size}{count}++;

        $tokens->{total_shirts}++;

        push @{ $shirts{$size}{users} }, { name => $name, id => $user->id };
    }

    $tokens->{shirts} = [
        map {
            {
                size  => $_,
                %{$shirts{$_}},
            }
        } sort { $t_shirt_sizes{$a} <=> $t_shirt_sizes{$b} } keys %shirts
    ];

    template 'admin/tshirts', $tokens;
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
