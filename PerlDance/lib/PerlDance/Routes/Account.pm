package PerlDance::Routes::Account;

=head1 NAME

PerlDance::Routes::Account - account routes such as login, edit profile, ...

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Dancer::Plugin::Interchange6;
use Data::Transpose::Validator;
use HTML::FormatText::WithLinks;
use Try::Tiny;

=head1 ROUTES 

=head2 get /login

post is handled by L<Dancer::Plugin::Interchange6>

=cut

get '/login' => sub {
    my $nav = shop_navigation->find( { uri => 'login' } );
    my $tokens = {
        title       => $nav->name,
        description => $nav->description,
    };
    $tokens->{title} = "Login";
    template 'login', $tokens;
};

=head2 post /register

Register of request password reset.

=cut

post '/register' => sub {
    my $username = param 'username';
    # TODO: validate

    debug "register/reset for username: $username";

    my $user = shop_user( { username => $username } );
    if ($user) {

        # password reset
    }
    else {

        # new registration
        try {
            $user = shop_user->create(
                { username => $username, email => $username } );
        }
        catch {
            error "registration failed: $_";
            # TODO: send email to admins as well?
        }
    }

    if ( $user ) {
        my $token = $user->reset_token_generate;

        my $html = template "email/generic",
          {
            "conference-logo" => uri_for(
                shop_schema->resultset('Media')
                  ->search( { label => "email-logo" } )->first->uri
            ),
            preamble => "You are receiving this email because your email address was used to register for the Perl Dancer Conference 2015.\n\nIf you received this email in error please accept our apologies and delete this email. No further action is required on your part.\n\nTo continue with registration please click on the following link:",
            link => uri_for("/register/$token")
          },
          { layout => 'email' };

        my $f = HTML::FormatText::WithLinks->new;
        my $text = $f->parse($html);
        try {
            email {
                to      => $user->email,
                subject => "Registration for the Perl Dancer Conference 2015",
                body    => $text,
                type    => 'text',
                attach  => {
                    Data     => $html,
                    Encoding => "quoted-printable",
                    Type     => "text/html"
                },
                multipart => 'alternative',
            };
        }
        catch {
            error "Could not send email: $_";
        }
    }

    template 'email_sent', { username => $username };
};

any ['get', 'post'] => '/register/:token' => sub {

    my $tokens      = {};
    my $reset_token = param 'token';
    my $user;

    if ( request->is_post ) {

        my %params = params('body');
        my %errors;

        my $validator = Data::Transpose::Validator->new;
        $validator->prepare(
            username => {
                required  => 1,
                validator => 'EmailValid'
            },
            password => {
                required  => 1,
                validator => {
                    class   => 'PasswordPolicy',
                    options => {
                        username      => $params{username},
                        minlength     => 8,
                        maxlength     => 70,
                        patternlength => 4,
                        mindiffchars  => 5,
                        disabled      => {
                            digits   => 1,
                            mixed    => 1,
                            specials => 1,
                        }
                    }
                }
            },
            confirm_password => { required => 1 },
            passwords => {
                validator => 'Group',
                fields    => [ "password", "confirm_password" ],
            },
        );

        my $valid = $validator->transpose(\%params);

        if ( !$valid ) {
            my $v_hash = $validator->errors_hash;

            while ( my ( $key, $value ) = each %$v_hash ) {

                my $error = $value->[0]->{value};
                $error = "invalid email address" if $error eq "mxcheck";
                $errors{$key} = $error;

                # flag the field with error using has-error class
                $errors{ $key . '_input' } = 'has-error';
            }
        }

        $user = shop_user( { username => $params{username} } );

        if ( $user ) {

            if ( !$user->reset_token_verify($reset_token) ) {
                $tokens = {
                    title       => "Sorry",
                    description => "This registration link is no longer valid",
                    action      => "/register",
                    action_name => "Register",
                    text => "I am sorry but the registration link you entered is invalid.\n\nMaybe the link has expired - please retry registration.",
                };
                return template "bad_token", $tokens;
            }
            if ( !%errors ) {

                # all good so login user and redirect to /profile
                $user->update( { password => $params{password} } );
                my ( undef, $realm ) =
                  authenticate_user( $params{username}, $params{password} );
                session logged_in_user => $user->username;
                session logged_in_user_id => $user->id;
                session logged_in_user_realm => $realm;

                return redirect '/profile';
            }
        }
        else {
            $errors{username}       = "invalid email address";
            $errors{username_input} = "has-error";
        }

        # go back and try again

            $tokens = {
                username    => $params{username},
                title       => "Register",
                description => "Please complete the registration process",
                action_name => "Complete Registration",
                text =>
                  "There appears to have been a problem.\n\nPlease try again.",
                errors => \%errors,
            };
            return template "password_reset", $tokens;
    }
    else {

        # get /register/...

        $user = shop_user->find_user_with_reset_token( $reset_token );

        if ( $user ) {

            # look good so ask for password

            $tokens = {
                title       => "Register",
                description => "Please complete the registration process",
                action_name => "Complete Registration",
            };
            return template "password_reset", $tokens;
        }
        else {

            # token not found

            $tokens = {
                title       => "Sorry",
                description => "This registration link is not valid",
                action      => "/register",
                action_name => "Register",
                text => "I am sorry but the registration link you entered is invalid.\n\nMaybe the link has expired or it was copied incorrectly from the email.",
            };
            return template "bad_token", $tokens;
        }
    }
};

true;
