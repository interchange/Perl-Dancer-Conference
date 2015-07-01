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
    if ( var 'login_failed' ) {
        # var added by DPAE's post /login route
        $tokens->{login_input} = "has-error";
        $tokens->{login_error} = "Username or password incorrect";
    }
    template 'login', $tokens;
};

=head2 get /profile

Profile update top-level page showing available options.

=cut

get '/profile' => require_login sub {
    my $nav = shop_navigation({ uri => 'profile' });

    my $talks = logged_in_user->talks_authored->search(
        { conferences_id => setting('conferences_id') } );

    my $tokens = {
        title       => 'Profile',
        description => 'Update profile',
        profile_nav =>
          [ $nav->active_children->order_by('!priority')->hri->all ],
        talks => $talks,
    };

    template 'profile', $tokens;
};

=head2 get /profile/photo

Profile photo display/update

=cut

get '/profile/photo' => require_login sub {
    my $tokens = {};

    # could also add extra js locales here if wanted
    PerlDance::Routes::add_javascript( $tokens, '/js/fileinput.min.js', '/js/profile-photo.js' );

    template 'profile/photo', $tokens;
};

post '/profile/photo' => require_login sub {
    content_type('application/json');
    to_json({ data => 'foo' });
};

=head2 get /register

=cut

get '/register' => sub {
    my $tokens = {
        title       => "Register",
        description => "Please complete the registration process",
        action      => "/register",
        action_name => "Registration",
        text => "Please enter your email address and hit submit to begin the registration process.",
    };
    return template "register_reset", $tokens;
};

=head2 get /reset_password

=cut

get '/reset_password' => sub {
    my $tokens = {
        title       => "Reset Password",
        description => "",
        action      => "/reset_password",
        action_name => "Reset Password",
        text => "Please enter your email address and hit submit to begin the password reset process.",
    };
    return template "register_reset", $tokens;
};

=head2 post /(register|reset_password)

Register of request password reset.

=cut

post qr{ /(?<action> register | reset_password )$ }x => sub {
    my $username = param('username') || param('register');
    my $captures = captures;
    my $action   = $$captures{action};
    # TODO: validate

    debug "$action for username: $username";

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
            error "create user failed in $action: $_";
            # TODO: send email to admins as well?
        }
    }

    if ( $user ) {
        my $token = $user->reset_token_generate;

        my $reason = $action eq 'register' ? 'register' : 'reset your password';
        my $action_name =
          $action eq 'register' ? 'registration' : 'password reset';

        my $html = template "email/generic", {
            "conference-logo" => uri_for(
                shop_schema->resultset('Media')
                  ->search( { label => "email-logo" } )->first->uri
            ),
            preamble => "You are receiving this email because your email address was used to $reason for the " . setting("conference_name") . ".\n\nIf you received this email in error please accept our apologies and delete this email. No further action is required on your part.\n\nTo continue with $action_name please click on the following link:",
            link => uri_for( path( request->uri, $token ) ),
          },
          { layout => 'email' };

        my $f = HTML::FormatText::WithLinks->new;
        my $text = $f->parse($html);
        try {
            email {
                to      => $user->email,
                subject => "\u$action_name for the " . setting("conference_name"),
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

    template 'email_sent',
      { title => "Thankyou", "Email on its way", username => $username };
};

=head2 get/post /(register|reset_password)/:token

=cut

any [ 'get', 'post' ] => qr{
    / (?<action> register | reset_password )
    / (?<token> \w+ )
    }x => sub {

    my $tokens      = {};
    my $captures    = captures;
    my $action      = $$captures{action};
    my $reset_token = $$captures{token};
    my $name        = $action eq 'register' ? 'register' : 'reset password';
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
                    description => "This $name link is no longer valid",
                    action      => "/$action",
                    action_name => $name,
                    text => "I am sorry but the $name link you entered is invalid.\n\nMaybe the link has expired - please retry $name.",
                };
                return template "register_reset", $tokens;
            }
            if ( !%errors ) {

                # all good so set password, add to attendees, login and
                # redirect to /profile
                $user->update( { password => $params{password} } );

                $user->find_or_create_related( 'conferences_attended',
                    { conferences_id => setting('conferences_id') } );

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
            title       => $name,
            description => "Please complete the $name process",
            action_name => "Complete \u$name",
            text =>
              "There appears to have been a problem.\n\nPlease try again.",
            errors => \%errors,
        };
        return template "password_reset", $tokens;
    }
    else {

        # get /register/:token

        try {
            $user = shop_user->find_user_with_reset_token( $reset_token );
        };

        if ( $user ) {

            # look good so ask for password

            $name = 'registration' if $name eq 'register';

            $tokens = {
                title       => "\u$name",
                description => "Please complete the $name process",
                action_name => "Complete \u$name",
            };
            return template "password_reset", $tokens;
        }
        else {

            # token not found

            $tokens = {
                title       => "Sorry",
                description => "This $name link is not valid",
                action      => "/$action",
                action_name => $name,
                text => "I am sorry but the $name link you entered is invalid.\n\nMaybe the link has expired or it was copied incorrectly from the email.",
            };
            return template "register_reset", $tokens;
        }
    }
};

true;
