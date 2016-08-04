package PerlDance::Routes::Account;

=head1 NAME

PerlDance::Routes::Account - account routes such as login, register, reset pwd

=cut

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DataTransposeValidator;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::TemplateFlute;
use Dancer2::Plugin::Interchange6;
use HTML::FormatText::WithLinks;
use Try::Tiny;

=head1 ROUTES 

=head2 get /login

post is handled by L<Dancer2::Plugin::Interchange6>

=cut

get '/login' => sub {
    my $nav = shop_navigation->find( { uri => 'login' } );
    my $tokens = {
        title       => $nav->name,
        description => $nav->description,
    };

    # DPIC6 uses session return_url in post /login
    if ( body_parameters->get('return_url') ) {
        session return_url =>  body_parameters->get('return_url');
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
    my $form = form('register-reset');
    $form->reset;

    my $data = session->delete("data_register");
    if ( $data ) {
        $form->fill($data->{values});
    }

    my $tokens = {
        title       => "Register",
        description => "Please complete the registration process",
        action      => "/register",
        action_name => "Registration",
        data => $data,
        form => $form,
        text =>
"Please enter your email address and hit submit to begin the registration process.",
    };

    return template "register_reset", $tokens;
};

=head2 get /reset_password

=cut

get '/reset_password' => sub {
    my $form = form('register-reset');
    $form->reset;

    my $data = session->delete("data_reset_password");
    if ( $data ) {
        $form->fill($data->{values});
    }

    my $tokens = {
        title       => "Reset Password",
        description => "",
        action      => "/reset_password",
        action_name => "Reset Password",
        data => $data,
        form => $form,
        text =>
"Please enter your email address and hit submit to begin the password reset process.",
    };
    return template "register_reset", $tokens;
};

=head2 post /(register|reset_password)

Register of request password reset.

=cut

post qr{ /(?<action> register | reset_password )$ }x => sub {
    my $email    = body_parameters->get('username');
    my $captures = captures;
    my $action   = $$captures{action};
    my $username = lc($email);

    my $form = form('register-reset', source => 'body' );
    # validator currently only supports hashrefs
    my $data = validator( $form->values->as_hashref, 'email-valid' );

    if ( $data->{valid} ) {

        my $user = shop_user( { username => $username } );

        if ( !$user ) {

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
                # make sure defaults get set
                $user->discard_changes;

            }
            catch {
                error "create user failed in $action: $_";

                # send email to site admins about error
                PerlDance::Routes::send_email(
                    template => "email/generic",
                    tokens   => {
                        preamble => "Create new user failed in /$action: $_",
                    },
                    subject => "$action for the "
                      . setting("conference_name")
                      . " failed",
                );
            };

            if ($@) {

                # no point continuing
                return template "/error";
            }
        }

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
            subject => "\u$action_name for the " . setting("conference_name"),
        );

        template 'email_sent',
          {
            title       => "Thank you",
            description => "Email on its way",
            username    => $email
          };
    }
    else {

        # problem in the form
       
        session "data_$action" => $data;
        return redirect uri_for($action);
    }
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

        my $data = validator( body_parameters->as_hashref,
            'password-reset', $user->username );

        if ( $data->{valid} ) {

            # all good so set password, add to attendees, login and
            # redirect to /profile

            $user->update( { password => $data->{values}->{password} } );

            $user->find_or_create_related( 'conferences_attended',
                { conferences_id => setting('conferences_id') } );

            my ( undef, $realm ) = authenticate_user( $user->username,
                $data->{values}->{password} );

            session logged_in_user       => $user->username;
            session logged_in_user_id    => $user->id;
            session logged_in_user_realm => $realm;

            if ( $action eq 'register' ) {
                # send email to organization team
                PerlDance::Routes::send_email(
                    template => "email/generic",
                    tokens   => {
                        preamble => "User ". $user->username . " just registered.",
                        link => uri_for( 'admin/users/edit/' . $user->id ),
                    },
                    to      => setting('conference_email'),
                    subject => "Registration for the " . setting("conference_name"),
                );

                deferred success => "Welcome to the " . setting('conference_name');
            }
            else {
                deferred success => "Password changed";
            }

            return redirect '/profile';
        }

        $tokens->{data} = $data;
        $tokens->{text} =
          "There appears to have been a problem.\n\nPlease try again.",
    }

    $name = 'registration' if $name eq 'register';

    $tokens->{title}       = "\u$name";
    $tokens->{description} = "Please complete the $name process";
    $tokens->{action_name} = "Complete \u$name";

    return template "password_reset", $tokens;
};
