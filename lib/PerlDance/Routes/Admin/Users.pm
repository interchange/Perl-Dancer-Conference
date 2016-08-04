package PerlDance::Routes::Admin::User;

=head1 NAME

PerlDance::Routes::Admin::User - admin routes for users

=cut

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::TemplateFlute;
use Try::Tiny;

=head1 ROUTES

=cut

get '/admin/users' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Users Admin";

    $tokens->{users} = [ rset('User')->search(
        {
            'conferences_attended.conferences_id' =>
              [ undef, setting('conferences_id') ],
        },
        {
            prefetch => [ 'conferences_attended', { user_roles => 'role' } ],
            order_by => [ 'me.created', 'role.label' ],
        }
    )->all ];

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

    template 'admin/users', $tokens;
};

get '/admin/users/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create Users";

    # countries dropdown
    $tokens->{countries} = [
        rset('Country')->search( undef,
            { columns => [ 'country_iso_code', 'name' ], order_by => 'name' } )
          ->hri->all
    ];
    unshift @{ $tokens->{countries} },
      { country_iso_code => undef, name => "Select Country" };

    my $form = form('update_create_users');
    $form->reset;
    $tokens->{form} = $form;

    PerlDance::Routes::add_tshirt_sizes( $tokens );

    PerlDance::Routes::add_javascript( $tokens, '/data/states.js',
        '/js/profile-edit.js' );

    template 'admin/users/create_update', $tokens;
};

post '/admin/users/create' => require_role admin => sub {
    my $tokens = {};

    my $form   = form('update_create_users');
    my %values = %{ $form->values };

    $values{bio} =~ s/\r\n/\n/g;
    $values{nickname} = undef unless $values{nickname} =~ /\S/;

    # TODO: validate values and if OK then try create
    my $user = rset('User')->create(
        {
            username      => lc( $values{email} ),
            email         => $values{email},
            first_name    => $values{first_name} || '',
            last_name     => $values{last_name} || '',
            nickname      => $values{nickname} || '',
            monger_groups => $values{monger_groups} || '',
            pause_id      => $values{pause_id} || '',
            bio           => $values{bio} || '',
            guru_level    => $values{guru_level} || 0,
            t_shirt_size  => $values{t_shirt_size} || undef,
            conferences_attended => [
                {
                    conferences_id => setting('conferences_id'),
                }
            ],
        }
    );

    my $country =
      rset('Country')->find( { country_iso_code => uc( $values{country} ) } );

    if ($country) {

        $values{state} = undef unless $country->show_states;

        $user->create_related(
            'addresses',
            {
                type             => 'primary',
                company          => $values{company} || '',
                city             => $values{city} || '',
                states_id        => $values{state},
                country_iso_code => $values{country},
                latitude         => $values{latitude} || undef,
                longitude        => $values{longitude} || undef,
            }
        );

    }

    # clear form before redirect
    $form->reset;
    return redirect '/admin/users';
};

get '/admin/users/delete/:id' => require_role admin => sub {
    try {
        rset('User')->find( route_parameters->get('id') )->delete;
    };
    redirect '/admin/users';
};

get '/admin/users/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $user = rset('User')->find( route_parameters->get('id') );

    send_error( "User not found", 404 ) if !$user;

    # countries dropdown
    $tokens->{countries} = [
        rset('Country')->search( undef,
            { columns => [ 'country_iso_code', 'name' ], order_by => 'name' } )
          ->hri->all
    ];

    my %values = (
        users_id      => $user->users_id,
        email         => $user->username,
        first_name    => $user->first_name,
        last_name     => $user->last_name,
        nickname      => $user->nickname,
        monger_groups => $user->monger_groups,
        pause_id      => $user->pause_id,
        guru_level    => $user->guru_level,
        bio           => $user->bio,
        t_shirt_size  => $user->t_shirt_size,
    );

    my $address = $user->search_related(
        'addresses',
        {
            'me.type' => 'primary',
        },
        {
            prefetch => 'country',
            rows     => 1,
        }
    )->first;

    if ($address) {
        $values{company}   = $address->company;
        $values{city}      = $address->city;
        $values{country}   = $address->country_iso_code;
        $values{state}     = $address->states_id;
        $values{company}   = $address->company;
        $values{latitude}  = $address->latitude;
        $values{longitude} = $address->longitude;
    }
    else {
        # no address so add 'Select Country' option to countries
        unshift @{ $tokens->{countries} },
          { country_iso_code => undef, name => "Select Country" };
    }

    my $form = form('update_create_users');
    $form->reset;
    $form->fill( \%values );
    $tokens->{form}    = $form;

    # if state is defined then we pass this to template where it gets inserted
    # as data into state select so that on page load profile-edit.js can
    # set the appropriate state as "selected"
    $tokens->{state} = $values{state} if $values{state};

    PerlDance::Routes::add_tshirt_sizes( $tokens, $values{t_shirt_size} );

    PerlDance::Routes::add_javascript( $tokens, '/data/states.js',
        '/js/profile-edit.js' );

    $tokens->{title}   = "Edit Users";

    template 'admin/users/create_update', $tokens;
};

post '/admin/users/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $user = rset('User')->find( route_parameters->get('id') );

    send_error( "User not found", 404 ) if !$user;

    my $form   = form('update_create_users');
    my %values = %{ $form->values };

    $values{bio} =~ s/\r\n/\n/g;
    $values{nickname} = undef unless $values{nickname} =~ /\S/;

    # TODO: validate values and if OK then try update
    $user->update(
        {
            username      => lc( $values{email} ),
            email         => $values{email},
            first_name    => $values{first_name} || '',
            last_name     => $values{last_name} || '',
            nickname      => $values{nickname},
            monger_groups => $values{monger_groups} || '',
            pause_id      => $values{pause_id} || '',
            guru_level    => $values{guru_level} || 0,
            bio           => $values{bio} || '',
            t_shirt_size  => $values{t_shirt_size} || undef,
        }
    );

    my $address = $user->search_related(
        'addresses',
        {
            'me.type' => 'primary',
        },
        {
            prefetch => 'country',
            rows     => 1,
        }
    )->first;

    my $country =
      rset('Country')->find( { country_iso_code => uc( $values{country} ) } );

    #FIXME: if we have $values{country} but $country is undef then ??

    if ($country) {

        $values{state} = undef unless $country->show_states;

        if ($address) {
            $address->update(
                {
                    company => $values{company} || '',
                    city    => $values{city}    || '',
                    states_id        => $values{state},
                    country_iso_code => $values{country},
                    latitude         => $values{latitude} || undef,
                    longitude        => $values{longitude} || undef,
                }
            );
        }
        else {
            $user->create_related(
                'addresses',
                {
                    type             => 'primary',
                    company          => $values{company} || '',
                    city             => $values{city} || '',
                    states_id        => $values{state},
                    country_iso_code => $values{country},
                    latitude         => $values{latitude} || undef,
                    longitude        => $values{longitude} || undef,
                }
            );
        }
    }

    $form->reset;
    return redirect '/admin/users';
};

true;
