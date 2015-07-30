package PerlDance::Routes::User;

=head1 NAME

PerlDance::Routes::User - user/speaker pages

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Interchange6;

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

    $tokens->{user} = shop_user->find(
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

=head2 get /users/*

=cut

get '/users/:name' => sub {
    my $name = param('name');
    my $user = shop_user->find({ nickname => $name });
    $name = $user->id if $user;
    forward "/speakers/$name";
};

sub add_speakers_tokens {
    my $tokens = shift;

    my @speakers = shop_user->search(
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
      uri_for(
        shop_schema->resultset('Media')->search( { label => "email-logo" } )
          ->first->uri );

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
