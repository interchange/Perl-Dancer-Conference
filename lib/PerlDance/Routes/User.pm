package PerlDance::Routes::User;

=head1 NAME

PerlDance::Routes::User - user/speaker pages

=cut

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::TemplateFlute;
use List::MoreUtils 'uniq';
use Try::Tiny;

=head1 ROUTES

=head2 get /speakers

Speaker list

=cut

get '/speakers' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens( $tokens );
    add_speakers_tokens($tokens);

    $tokens->{title} = "Speakers";

    template 'speakers', $tokens;
};

=head2 get /(speakers|users)/{id}.*

Individual speaker/user

=cut

get qr{/(speakers|users)/(?<id>\d+).*} => sub {
    my $users_id = captures->{id};
    my $tokens = {};

    my $user = rset('User')->find(
        {
            'me.users_id'                         => $users_id,
            'conferences_attended.conferences_id' => setting('conferences_id'),
            'addresses.type'                      => [ undef, 'primary' ],
        },
        {
            prefetch => [ { addresses => 'country', }, 'photo' ],
            join => 'conferences_attended',
        }
    );
    send_error( "Not found.", 404 ) if !$user;

    $tokens->{user} = $user;

    $tokens->{attending} =
      $user->related_resultset('attendee_talks')
      ->search_related( 'talk',
        { 'talk.conferences_id' => setting('conferences_id') } )
      ->order_by('talk.title');

    my $address = $user->addresses->first;

    my $talks = $tokens->{user}->search_related(
        'talks_authored',
        {
            conferences_id => setting('conferences_id'),
            -bool          => 'accepted',
        }
    );

    if ( $talks->has_rows ) {

        if ( my $user = schema->current_user ) {
            $talks = $talks->with_attendee_status( $user->id );
        }

        $tokens->{talks} = $talks;
    }

    $tokens->{previous_talks} = $tokens->{user}->search_related(
        'talks_authored',
        {
            'me.conferences_id' => { '!=', setting('conferences_id') },
            -bool               => 'accepted',
            -bool               => 'scheduled',
            start_time          => [
                -and => { '!=', undef },
                { '<=', schema->format_datetime( DateTime->now ) }
            ],
        },
        {
            columns => [ 'talks_id', 'title' ],
            order_by   => { -desc => 'start_time' },
            '+columns' => ['conference.name'],
            join       => 'conference',
            collapse   => 1,
        }
    );

    $tokens->{title} = $tokens->{user}->name;
    if ( $address ) {
        $tokens->{description} = '';
        $tokens->{description} .= $address->company . ', ' if $address->company;
        $tokens->{description} .= $address->city . ', ' if $address->city;
        $tokens->{description} .= $address->country->name;
    }

    # create structured data object - which might failed because of missing data
    my $sdh;
    my $ld_output;

    try {
        $sdh = $user->structured_data_hash( {
            public_dir => config->{public_dir},
        });

        my $ld = PerlDance::StructuredData->new(%$sdh);

        $ld_output = $ld->out;
    }
    catch {
        error "crashed while creating structured data: $_, data: ", $sdh;
    };

    $tokens->{structured_data} = $ld_output;

    template 'speaker', $tokens;
};

=head2 get /users

=cut

get '/users' => sub {
    my $tokens = {};

    my $users = rset('User')->search(
        {
            'conferences_attended.conferences_id' => setting('conferences_id'),
        },
        {
            join => 'conferences_attended',
        }
    );

    $tokens->{total_users} = $users->count;

    $tokens->{users} = $users->search(
        {
            'addresses.type'      => 'primary',
            'addresses.latitude'  => { '!=' => undef },
            'addresses.longitude' => { '!=' => undef },
        },
        {
            prefetch => [ 'addresses', 'photo' ],
        }
    );

    $tokens->{title} = "User Map";
    $tokens->{mapbox} = config->{mapbox};

    PerlDance::Routes::add_javascript( $tokens, '/js/usermap.js',
        '/js/leaflet.markercluster.js' );

    template 'users', $tokens;

};

=head2 get/post /users/search

=cut

any [ 'get', 'post' ] => '/users/search' => sub {
    my $tokens = {};

    my $form = form('users_search');

    my $users = rset('User')->search(
        {
            'conferences_attended.conferences_id' => setting('conferences_id'),
        },
        {
            join => 'conferences_attended',
        }
    );

    # countries dropdown
    $tokens->{countries} = [
        $users->search_related(
            'addresses',
            {
                type => 'primary',
            },
          )->search_related(
            'country', undef,
            {
                columns  => [ 'country_iso_code', 'name' ],
                distinct => 1,
                order_by => 'country.name',
            }
          )->hri->all
    ];
    unshift @{ $tokens->{countries} },
      { country_iso_code => undef, name => 'Any' };

    # monger_groups dropdown
    $tokens->{monger_groups} = [
        map { { value => $_, label => $_ } }
          uniq map { lc($_) }
          split(
            /[,\s]+/,
            join( " ",
                $users->search( { monger_groups => { '!=' => '' } } )
                  ->get_column('monger_groups')->all )
          )
    ];
    unshift @{ $tokens->{monger_groups} },
      { value => undef, label => 'Any' };

    my %values = %{ request->parameters->as_hashref };
    if ( %values ) {

        $form->fill(\%values);

        $users = $users->search(
            {
                'addresses.type' => 'primary',
            },
            {
                prefetch =>
                  [ 'conferences_attended', { addresses => 'country' } ],
            }
        );

        if ( $values{name} ) {
            $users = $users->search(
                [
                    \[
                        'LOWER(me.first_name) LIKE ?',
                        [
                            { dbic_colname => 'first_name' },
                            '%' . lc( $values{name} ) . '%'
                        ]
                    ],
                    \[
                        'LOWER(me.last_name) LIKE ?',
                        [
                            { dbic_colname => 'last_name' },
                            '%' . lc( $values{name} ) . '%'
                        ]
                    ],
                    \[
                        'LOWER(me.nickname) LIKE ?',
                        [
                            { dbic_colname => 'nickname' },
                            '%' . lc( $values{name} ) . '%'
                        ]
                    ]
                ],
            );
        }

        if ( $values{city} ) {
            $users = $users->search(
                \[
                    'LOWER(addresses.city) LIKE ?',
                    [
                        { dbic_colname => 'addresses.city' },
                        '%' . lc( $values{city} ) . '%'
                    ]
                ]
            );
        }

        if ( $values{country} ) {
            $users = $users->search(
                {
                    'addresses.country_iso_code' => $values{country},
                }
            );
        }

        if ( $values{monger_group} ) {
            $users = $users->search(
                \[
                    'LOWER(me.monger_groups) LIKE ?',
                    [
                        { dbic_colname => 'me.monger_groups' },
                        '%' . lc($values{monger_group}) . '%'
                    ]
                ]
            );
        }

        my @users;
        while ( my $user = $users->next ) {
            my $address = $user->addresses->first;
            my $data = {
                uri => $user->uri,
                name => $user->name,
                nickname => $user->nickname,
                city => $address->city,
                country => $address->country->name,
                monger_groups => $user->monger_groups,
            };
            if ( $user->conferences_attended->first->confirmed ) {
                $data->{confirmed} = 1;
            }
            else {
                $data->{unconfirmed} = 1;
            }
            push @users, $data;
        }
        if ( @users ) {
            $tokens->{users} = \@users;
        }
        else {
            $tokens->{no_results} = 1;
        }
    }
    else {
        # no params so reset form
        $form->reset;
    }

    $tokens->{form} = $form;
    $tokens->{title} = "User Search";

    if ($tokens->{no_results}) {
        # prevent "Soft 404"
        status 404;
    }

    template 'users/search', $tokens;
};

=head2 get /users/statistics

=cut

get '/users/statistics' => sub {
    my $tokens = {};

    my $users = rset('User')->search(
        {
            'conferences_attended.conferences_id' => setting('conferences_id'),
        },
        {
            join => 'conferences_attended',
        }
    );

    $tokens->{countries} = [
        $users->search_related(
            'addresses',
            {
                type => 'primary',
            },
          )->search_related(
            'country',
            undef,
            {
                select => [
                    'country.country_iso_code',
                    'country.name',
                    {
                        count => 'country.country_iso_code',
                        -as   => 'count'
                    },
                ],
                group_by => [ 'country.country_iso_code', 'country.name' ],
                order_by => { -desc => 'count' },
            }
          )->hri->all
    ];

    my ( %groups, @groups );
    map { $groups{lc($_)}++ } split(
        /[,\s]+/,
        join( " ",
            $users->search( { monger_groups => { '!=' => '' } } )
              ->get_column('monger_groups')->all )
    );
    my @keys = sort { $groups{$b} <=> $groups{$a} } keys %groups;
    foreach my $name ( @keys ) {
        push @groups, { name => $name, count => $groups{$name} };
    }
    $tokens->{monger_groups} = \@groups;

    $tokens->{title} = "User Statistics";

    template 'users/stats', $tokens;
};

=head1 METHODS

=head2 add_speakers_tokens

=cut

sub add_speakers_tokens {
    my $tokens = shift;

    my $unknown_user_pic =
      rset('Media')->find( { uri => '/img/people/unknown.jpg' } );

    my @speakers = rset('User')->search(
        {
            'me.media_id'    => { '!=', $unknown_user_pic->id },
            'addresses.type' => 'primary',
            'conferences_attended.conferences_id' => setting('conferences_id'),
            -or                                   => {
                -and => {
                    'talks_authored.conferences_id' =>
                      setting('conferences_id'),
                    -or => {
                        'talks_authored.accepted'  => 1,
                        'talks_authored.confirmed' => 1,
                    },
                },
                'me.guru_level' =>
                  { '>=', setting('guru_min_level_auto_speaker') },
            },
        },
        {
            prefetch => [ { addresses => 'country', }, 'photo' ],
            join     => [
                'conferences_attended', 'talks_authored',
            ],
            order_by => { -desc => 'guru_level' },
        }
    )->all;

    my @grid;
    while ( my @row = splice( @speakers, 0, 4 ) ) {
        push @grid, +{ row => \@row };
    }

    $tokens->{speakers} = \@grid;
}

true;
