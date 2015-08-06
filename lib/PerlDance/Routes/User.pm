package PerlDance::Routes::User;

=head1 NAME

PerlDance::Routes::User - user/speaker pages

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;

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

=head2 get /speakers/{id}.*

Individual speaker

=cut

get qr{/speakers/(?<id>\d+).*} => sub {
    my $users_id = captures->{id};
    my $tokens = {};

    var no_title_wrapper => 1;

    $tokens->{user} = rset('User')->find(
        {
            'me.users_id'                         => $users_id,
            'conferences_attended.conferences_id' => setting('conferences_id'),
            'addresses.type'                      => [undef, 'primary'],
        },
        {
            prefetch =>
              [ { addresses => 'country', }, 'photo' ],
            join => 'conferences_attended',
        }
    );

    if ( !$tokens->{user} ) {
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{talks} = $tokens->{user}->search_related(
        'talks_authored',
        {
            conferences_id => setting('conferences_id'),
            accepted       => 1,
            confirmed      => 1,
        }
    );

    $tokens->{has_talks} = 1 if $tokens->{talks}->has_rows;

    my $monger_groups = $tokens->{user}->monger_groups;
    if ( $monger_groups ) {
        $monger_groups =~ s/,/ /g;
        $monger_groups =~ s/(^\s+|\s+$)//g;
        $tokens->{monger_groups} =
          [ map { { name => $_ } } split( /\s+/, $monger_groups ) ];
    }

    $tokens->{title} = $tokens->{user}->name;

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
          split(
            /[,\s]+/,
            join( " ",
                $users->search( { monger_groups => { '!=' => '' } } )
                  ->get_column('monger_groups')->all )
          )
    ];
    unshift @{ $tokens->{monger_groups} },
      { value => undef, label => 'Any' };

    my %values = %{ params() };
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
                {
                    'me.monger_groups' =>
                      { like => '%' . $values{monger_group} . '%' }
                }
            );
        }

        my @users;
        while ( my $user = $users->next ) {
            my $address = $user->addresses->first;
            push @users, {
                uri => $user->uri,
                name => $user->name,
                nickname => $user->nickname,
                city => $address->city,
                country => $address->country->name,
                monger_groups => $user->monger_groups,
                confirmed => $user->conferences_attended->first->confirmed,
            };
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
    map { $groups{$_}++ } split(
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

    $tokens->{title} = "User Stastics";

    template 'users/stats', $tokens;
};

=head2 get /users/:name

=cut

get '/users/:name' => sub {
    my $name = param('name');
    my $user = rset('User')->find({ nickname => $name });
    $name = $user->id if $user;
    forward "/speakers/$name";
};

=head1 METHODS

=head2 add_speakers_tokens

=cut

sub add_speakers_tokens {
    my $tokens = shift;

    my @speakers = rset('User')->search(
        {
            'addresses.type'                      => 'primary',
            'conferences_attended.conferences_id' => setting('conferences_id'),
            -or                                   => {
                'talks_authored.accepted'  => 1,
                'talks_authored.confirmed' => 1,
                -and                       => {
                    'attribute.name' => 'speaker',
                    'attribute.type' => 'boolean',
                },
            },
        },
        {
            prefetch => [ { addresses => 'country', }, 'photo' ],
            join     => [
                'conferences_attended', 'talks_authored',
                { user_attributes => 'attribute' }
            ],
        }
    )->all;

    my @grid;
    while ( my @row = splice( @speakers, 0, 4 ) ) {
        push @grid, +{ row => \@row };
    }

    $tokens->{speakers} = \@grid;
}

=head2 add_validator_error_tokens( $validator, $tokens )

Given a transposed L<Data::Transpose::Validator> object and template
C<$tokens> hash references as args adds C<errors> token to C<$tokens>.

=cut

sub add_validator_errors_token {
    my ( $validator, $tokens ) = @_;

    my %errors;
    my $v_hash = $validator->errors_hash;
    while ( my ( $key, $value ) = each %$v_hash ) {
        my $error = $value->[0]->{value};

        # in case we're doing EmailValid the mxcheck error is not clear
        $error = "invalid email address" if $error eq "mxcheck";

        $errors{$key} = $error;

        # flag the field with error using has-error class
        $errors{ $key . '_input' } = 'has-error';
    }
    $tokens->{errors} = \%errors;
}

=head2 send_email( $args_hash );

The following keys are required:

=over 4

=item template

=item tokens

=item to

=item subject

=back

=cut

sub send_email {
    my %args = @_;

    my $template = delete $args{template};
    die "template not supplied to send_email" unless $template;

    my $tokens = delete $args{tokens};
    die "tokens hashref not supplied to send_email"
      unless ref($tokens) eq 'HASH';

    $tokens->{"conference-logo"} =
      uri_for( rset('Media')->search( { label => "email-logo" } )->first->uri );

    my $html = template $template, $tokens, { layout => 'email' };

    my $f    = HTML::FormatText::WithLinks->new;
    my $text = $f->parse($html);

    email {
        %args,
        body => $text,
        type => 'text',
        attach => {
            Data     => $html,
            Encoding => "quoted-printable",
            Type     => "text/html"
        },
        multipart => 'alternative',
    };
}

true;
