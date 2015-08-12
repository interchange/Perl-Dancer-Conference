package PerlDance::Routes::Account;

=head1 NAME

PerlDance::Routes::Account - account routes such as login, register, reset pwd

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashNote;
use Dancer::Plugin::Form;
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

    # DPIC6 uses session return_url in post /login
    if ( param('return_url') ) {
        session return_url =>  param('return_url');
    }

    if ( var 'login_failed' ) {

        # var added by DPAE's post /login route
        $tokens->{login_input} = "has-error";
        $tokens->{login_error} = "Username or password incorrect";
    }
    template 'login', $tokens;
};

=head2 get /register

=cut

get '/register' => sub {
    my $form = form('register-email');
    my $errors = $form->errors;

    my $tokens = {
        title       => "Register",
        description => "Please complete the registration process",
        action      => "/register",
        action_name => "Registration",
        form => $form,
        text =>
"Please enter your email address and hit submit to begin the registration process.",
    };

    for my $err (@$errors) {
        $tokens->{$err->{name}} = $err->{label};
    }

    # prevent stale errors
    $form->reset;

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
        text =>
"Please enter your email address and hit submit to begin the password reset process.",
    };
    return template "register_reset", $tokens;
};

=head2 post /(register|reset_password)

Register of request password reset.

=cut

post qr{ /(?<action> register | reset_password )$ }x => sub {
    my $email = param('username');
    my $captures = captures;
    my $action   = $$captures{action};
    my $username = lc($email);

    # TODO: validate

    debug "$action for username: $username";

    my $user = shop_user( { username => $username } );
    if ($user) {

        # password reset
    }
    else {
        my %params = params('body');
        my %errors;
        my $form = form('register-email');

        my $validator = Data::Transpose::Validator->new;
        $validator->prepare(
            username => {
                required  => 1,
                validator => 'EmailValid'
            },
        );

        my $valid = $validator->transpose( \%params );

        if ( !$valid ) {
            my $tokens = {};

            PerlDance::Routes::add_validator_errors_token( $validator,
                $tokens );

            my $saved = $form->errors( $tokens->{errors} );
            $form->to_session;

            return redirect uri_for($action);
        }

        # new registration
        try {

            my $media_id = shop_schema->resultset('Media')
              ->find( { file => 'img/people/unknown.jpg' } )->id;
            $user = shop_user->create(
                {
                    username => $username,
                    email    => $email,
                    media_id => $media_id,
                }
            );

        }
        catch {
            error "create user failed in $action: $_";

            # TODO: send email to admins as well?
        }
        # TODO: check that we have a user and do something sane if we don't
        # since otherwise no email gets sent by later code
    }

    if ($user) {

        my $token = $user->reset_token_generate;

        my $reason = $action eq 'register' ? 'register' : 'reset your password';
        my $action_name =
          $action eq 'register' ? 'registration' : 'password reset';

        PerlDance::Routes::send_email(
                template => "email/generic",
                tokens   => {
                    preamble => "You are receiving this email because your "
                      . "email address was used to $reason for the "
                      . setting("conference_name")
                      . ".\n\nIf you received this email in error please accept our apologies and delete this email. No further action is required on your part.\n\nTo continue with $action_name please click on the following link:",
                    link => uri_for( path( request->uri, $token ) ),
                },
                to      => $user->email,
                subject => "\u$action_name for the "
                  . setting("conference_name"),
            );
    }

    template 'email_sent',
      {
        title       => "Thank you",
        description => "Email on its way",
        username    => $email
      };
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

    try {
        $user = shop_user->find_user_with_reset_token($reset_token);
    };

    if ( !$user ) {
        $tokens = {
            title       => "Sorry",
            description => "This $name link is not valid",
            action      => "/$action",
            action_name => $name,
            text =>
"I am sorry but the $name link you entered is invalid.\n\nMaybe the link has expired or it was copied incorrectly from the email.",
        };
        return template "register_reset", $tokens;
    }

    if ( request->is_post ) {

        my %params = params('body');
        my %errors;

        my $validator = Data::Transpose::Validator->new;
        $validator->prepare(
            password => {
                required  => 1,
                validator => {
                    class   => 'PasswordPolicy',
                    options => {
                        username      => $user->username,
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
            passwords        => {
                validator => 'Group',
                fields    => [ "password", "confirm_password" ],
            },
        );

        my $valid = $validator->transpose( \%params );

        if ($valid) {

            # all good so set password, add to attendees, login and
            # redirect to /profile

            $user->update( { password => $params{password} } );

            $user->find_or_create_related( 'conferences_attended',
                { conferences_id => setting('conferences_id') } );

            my ( undef, $realm ) =
              authenticate_user( $user->username, $params{password} );
            session logged_in_user       => $user->username;
            session logged_in_user_id    => $user->id;
            session logged_in_user_realm => $realm;

            if ( $action eq 'register' ) {
                flash success => "Welcome to the " . setting('conference_name');
            }
            else {
                flash success => "Password changed";
            }

            return redirect '/profile';
        }

        PerlDance::Routes::add_validator_errors_token( $validator, $tokens );

        $tokens->{text} =
          "There appears to have been a problem.\n\nPlease try again.",
    }

    $name = 'registration' if $name eq 'register';

    $tokens->{title}       = "\u$name";
    $tokens->{description} = "Please complete the $name process";
    $tokens->{action_name} = "Complete \u$name";

    return template "password_reset", $tokens;
};
