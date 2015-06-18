package PerlDance::Routes::Account;

=head1 NAME

PerlDance::Routes::Account - account routes such as login, edit profile, ...

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Dancer::Plugin::Interchange6;
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
            link => uri_for("/register/confirm/$token")
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

get '/register/confirm/:token' => sub {

    my $tokens = {};
    my $reset_token = param 'token';

    if ( shop_user->reset_token_verify($reset_token) ) {
        template "password_reset", $tokens;
    }
    else {
        $tokens = {
            title       => "Sorry",
            description => "This registration link is not valid",
            action => "/register",
            action_name => "Register",
        };
        template "bad_token", $tokens;
    }
};

true;
