package PerlDance::Routes::Admin::User;

=head1 NAME

PerlDance::Routes::Admin::User - admin routes for users

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use Try::Tiny;

=head1 ROUTES

=cut

get '/admin/users' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Users Admin";

    $tokens->{users} = rset('User')->search(
        {
         },
        {
            order_by => "created",
        }
    );

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

    template 'admin/users', $tokens;
};

get '/admin/users/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create Users";

    my $form = form('update_create_users');
    $form->reset;
    $form->fill( { public => 1 } );
    $tokens->{form} = $form;

    template 'admin/users/create_update', $tokens;
};

post '/admin/users/create' => require_role admin => sub {
    my $tokens = {};

    my $form   = form('update_create_users');
    my %values = %{ $form->values };
    $values{bio} =~ s/\r\n/\n/g;

    if ($values{nickname} !~ /\S/) {
        $values{nickname} = undef;
    }

    # TODO: validate values and if OK then try create
    rset('User')->create(
        {
            username      => $values{email},
            email         => $values{email},
            first_name    => $values{first_name},
            last_name     => $values{last_name},
            nickname      => $values{nickname} || undef,
            monger_groups => $values{monger_groups},
            pause_id      => $values{pause_id},
            bio           => $values{bio},
        }
    );
    return redirect '/admin/users';
};

get '/admin/users/delete/:id' => require_role admin => sub {
    try {
        rset('User')->find( param('id') )->delete;
    };
    redirect '/admin/users';
};

get '/admin/users/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $user = rset('User')->find( param('id') );

    if ( !$user ) {
        $tokens->{title} = "Users Item Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('update_create_users');
    $form->reset;

    $form->fill({
        users_id      => $user->users_id,
        email         => $user->email,
        first_name    => $user->first_name,
        last_name     => $user->last_name,
        nickname      => $user->nickname,
        monger_groups => $user->monger_groups,
        pause_id      => $user->pause_id,
        bio           => $user->bio,
    });

    $tokens->{form}    = $form;
    $tokens->{title}   = "Edit Users";

    template 'admin/users/create_update', $tokens;
};

post '/admin/users/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $user = rset('User')->find( param('id') );

    if ( !$user ) {
        $tokens->{title} = "User Item Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form   = form('update_create_users');
    my %values = %{ $form->values };
    $values{bio} =~ s/\r\n/\n/g;

    if ($values{nickname} !~ /\S/) {
        $values{nickname} = undef;
    }

    # TODO: validate values and if OK then try update
    $user->update(
        {
            username => lc($values{email}),
            email => $values{email},
            first_name => $values{first_name},
            last_name => $values{last_name},
            nickname => $values{nickname},
            monger_groups => $values{monger_groups},
            pause_id => $values{pause_id},
            bio => $values{bio},
        }
    );
    return redirect '/admin/users';
};

true;
