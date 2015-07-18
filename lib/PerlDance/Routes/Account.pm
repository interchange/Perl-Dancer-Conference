package PerlDance::Routes::Account;

=head1 NAME

PerlDance::Routes::Account - account routes such as login, edit profile, ...

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::Form;
use Dancer::Plugin::Interchange6;
use Data::Transpose::Validator;
use File::Copy;
use File::Spec;
use File::Type;
use Geo::IP;
use HTML::FormatText::WithLinks;
use Imager;
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

=head2 get /profile

Profile update top-level page showing available options.

=cut

get '/profile' => require_login sub {
    my $nav = shop_navigation( { uri => 'profile' } );

    my $talks = [
        logged_in_user->talks_authored->search(
            { conferences_id => setting('conferences_id') }
        )->hri->all
    ];

    # *** HACK *** - temporarily remove photo update until working correctly
    my $tokens = {
        title       => 'Profile',
        description => 'Update profile',
        profile_nav =>
          [ $nav->active_children->search({'me.uri' => { '!=' => 'profile/photo' }})->order_by('!priority')->hri->all ],
        talks => $talks,
    };

    template 'profile', $tokens;
};

=head2 get /profile/edit

=cut

get '/profile/edit' => require_login sub {
    my $tokens = { title => "Update Profile" };

    # countries dropdown
    $tokens->{countries} = [
        shop_country->search( undef,
            { columns => [ 'country_iso_code', 'name' ], order_by => 'name' } )
          ->hri->all
    ];

    my $user = logged_in_user;
    my %values = (
        first_name    => $user->first_name,
        last_name     => $user->last_name,
        nickname      => $user->nickname,
        monger_groups => $user->monger_groups,
        pause_id      => $user->pause_id,
        bio           => $user->bio,
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
        $values{company} = $address->company;
        $values{city}    = $address->city;
        $values{country} = $address->country_iso_code;
        $values{company} = $address->company;
    }
    else {

        # try to get city + country via GeoIP

        if ( my $geoipdb = setting('geoip_database' ) ) {
            my $ipaddress = request->address;

            debug "geoip lookup for address ", $ipaddress;

            if ( $ipaddress =~ /^\d+\.\d+\.\d+\.\d+$/ ) {

                # ipv4

                if ( my $g = Geo::IP->open( $geoipdb->{city} ) ) {
                    my $record = $g->record_by_addr($ipaddress);
                    if ( $record ) {
                        $values{city}    = $record->city;
                        $values{country} = $record->country_code;
                    }
                }
                elsif ( $g = Geo::IP->open( $geoipdb->{country4} ) ) {
                    $values{country} = $g->country_code_by_addr($ipaddress);
                }
            }
            else {

                # ipv6

                if ( my $g = Geo::IP->open( $geoipdb->{country6} ) ) {
                    $values{country} = $g->country_code_by_addr_v6($ipaddress);
                }
            }
        }

        if ( !$values{country} ) {
            # no country found to add 'Select Country' option to countries
            unshift @{ $tokens->{countries} },
              { country_iso_code => undef, name => "Select Country" };
        }
    }

    debug \%values;

    # fill the form
    my $form = form('edit_profile');
    $form->reset;
    $form->fill( \%values );
    $tokens->{form} = $form;

    template 'profile/edit', $tokens;
};

=head2 post /profile/edit

=cut

post '/profile/edit' => require_login sub {
    my $tokens = {};

    my $form   = form('edit_profile');
    my %values = %{ $form->values };
    $values{bio} =~ s/\r\n/\n/g;

    my $user = logged_in_user;
    foreach
      my $field (qw/first_name last_name nickname monger_groups pause_id bio/)
    {
        $values{$field} ||= '';
        $user->$field($values{$field});
    }
    $user->update;

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

    if ( $address ) {
        $address->update(
            {
                company => $values{company} || '',
                city    => $values{city}    || '',
                country_iso_code => $values{country},
            }
        );
    }
    else {
        if ( $values{country} ) {
            $user->create_related(
                'addresses',
                {
                    type             => 'primary',
                    company          => $values{company} || '',
                    city             => $values{city} || '',
                    country_iso_code => $values{country},
                }
            );
        }
    }

    # FIXME: flash 'done'?
    $form->reset;
    redirect '/profile';
};

=head2 get /profile/password

=cut

get '/profile/password' => require_login sub {
    template 'profile/password', { title => 'Change Password' };
};

=head2 post /profile/password

=cut

post '/profile/password' => require_login sub {

    my %params = params('body');

    my $validator = Data::Transpose::Validator->new;
    $validator->prepare(
        old_password => {
            required => 1,
            validator => sub {
                if ( logged_in_user->check_password($_[0]) ) {
                    return $_[0];
                }
                else {
                    return (undef, "Password incorrect");
                }
            },
        },
        password => {
            required  => 1,
            validator => {
                class   => 'PasswordPolicy',
                options => {
                    username      => logged_in_user->username,
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

    if ( $valid ) {
        logged_in_user->update({ password => $valid->{password} });
        # FIXME: flash success message?
        redirect '/profile';
    }
    else {
        my %errors;
        my $v_hash = $validator->errors_hash;
        while ( my ( $key, $value ) = each %$v_hash ) {
            $errors{$key} = $value->[0]->{value};
            $errors{ $key . '_input' } = 'has-error';
        }
        template 'profile/password', { %errors, title => "Change Password " };
    }
};

=head2 get /profile/photo

Profile photo display/update

=cut

get '/profile/photo' => require_login sub {
    my $tokens = {};

    PerlDance::Routes::add_javascript( $tokens, '/js/profile-photo.js' );

    template 'profile/photo', $tokens;
};

post '/profile/photo/upload' => require_login sub {
    if ( request->is_ajax ) {
        # FIXME: upload dir from config
        my $file = upload('photo');
        my $upload_dir = path( setting('public'), 'img', 'uploads' );
        my ( undef, undef, $tempname ) = File::Spec->splitpath( $file->tempname );
        my $target = path( $upload_dir, $tempname );
        session new_photo => $target;
        $file->copy_to($target); 
        content_type('application/json');
        to_json( { src => path( '/', 'img', 'uploads', $tempname ) } );
    }
    else {
        # TODO: handle non-ajax post
    }
};
post '/profile/photo/crop' => require_login sub {
    use Imager;
    my $file = session('new_photo');

    my $ft = File::Type->new;
    my $mime_type = $ft->checktype_filename($file);

    die "Not an image" unless $mime_type =~ /^image\//;

    ( my $type = $mime_type ) =~ s/^.+?\///;

    my $img = Imager->new;
    $img->read( file => $file ) or die "Cannot read photo $file: ", $img->errstr;

    debug "cropping photo";

    $img = $img->crop(
        left   => param('x'),
        top    => param('y'),
        width  => param('w'),
        height => param('h')
    ) or die "image crop failure: ", $img->errstr;

    debug "scaling image";

    $img = $img->scale( xpixels => 300, ypixels => 300 )
      or die "image scale failure: ", $img->errstr;

    my %options = ( file => $file, type => $type );

    $options{jpegquality} = 90 if $type eq 'jpeg';

    debug "saving image";

    $img->write( %options ) or die "image write failed";

    my $user = logged_in_user;
    my $photo = $user->photo;
    if ( !$photo ) {

        debug "creating new photo record";

        my $media_type_image = rset('MediaTyp')->find( { type => 'image' } );

        ( my $file_ext = $file ) =~ s/^.+?\.//;

        my $target = lc($user->name);
        $target =~ s/(^\s+|\s+$)//g;
        $target =~ s/\s+/-/g;
        $target = "img/people/$target.$file_ext";

        $user->create_related(
            'photo',
            {
                file           => $target,
                uri            => "/$target",
                mime_type      => $mime_type,
                media_types_id => $media_type_image->id,
            }
        ) or die "failed to create photo record in database";
    }

    my $target = path( setting('public'), $photo->file );

    debug "moving temp file to: $target";

    move( $file, $target );

    redirect '/profile/photo';
};

=head2 get /profile/talk/create

create new talk

=cut

get '/profile/talk/create' => require_login sub {
    my $tokens = {
        title => "New Talk",
    };

    $tokens->{form} = form('create_update_talk');
    $tokens->{form}->reset;
    $tokens->{form}->fill( duration => 40 );

    add_durations_token($tokens);

    template 'profile/create_update_talk', $tokens;
};

=head2 post /profile/talk/create

=cut

post '/profile/talk/create' => require_login sub {
    my $tokens = {};

    my $form   = form('create_update_talk');

    my ( $validator, $valid ) = validate_talk($form);

    if ($valid) {

        debug "valid values: ", $valid;

        my $tags = defined $valid->{tags} ? $valid->{tags} : '';
        $tags =~ s/,/ /g;
        $tags =~ s/\s+/ /g;

        ( my $abstract = $valid->{abstract} ) =~ s/\r\n/\n/;

        try {
            my $talk = shop_schema->resultset('Talk')->create(
                {
                    author_id      => logged_in_user->id,
                    conferences_id => setting('conferences_id'),
                    title          => $valid->{talk_title},
                    abstract       => $abstract,
                    tags           => $tags,
                    duration       => $valid->{duration},
                    url            => $valid->{url} || '',
                    comments       => $valid->{comments} || '',
                }
            );

            debug "new talk submitted";

            my $html = template '/email/talk_submitted',
              {
                %$valid,
                logged_in_user    => logged_in_user,
                talk              => $talk,
                "conference-logo" => uri_for(
                    shop_schema->resultset('Media')
                      ->search( { label => "email-logo" } )->first->uri
                ),
              },
              { layout => 'email' };

            my $f    = HTML::FormatText::WithLinks->new;
            my $text = $f->parse($html);

            email {
                subject => setting("conference_name") . " talk submitted",
                body    => $text,
                type    => 'text',
                attach  => {
                    Data     => $html,
                    Encoding => "quoted-printable",
                    Type     => "text/html"
                },
                multipart => 'alternative',
            };

            debug "sent email/talk_submitted";

            $form->reset;

            return redirect '/profile';
        }
        catch {
            # FIXME: handle errors
            error "Talk submission error: $_";
        };
    }
    else {
        my %errors;
        my $v_hash = $validator->errors_hash;
        while ( my ( $key, $value ) = each %$v_hash ) {
            $errors{$key} = $value->[0]->{value};
            $errors{ $key . '_input' } = 'has-error';
        }
        $tokens->{errors} = \%errors;
    }

    $tokens->{form} = $form;

    add_durations_token($tokens);

    template 'profile/create_update_talk', $tokens;
};

=head2 get /profile/talk/:id

=cut

get '/profile/talk/:id' => require_login sub {
    my $tokens = {};

    my $form = form('create_update_talk');
    $form->reset;

    my $talk = shop_schema->resultset('Talk')->find(param('id'));

    # check we have a talk for this conference owned by this user
    if (   $talk
        && $talk->conferences_id == setting('conferences_id')
        && $talk->author->id == logged_in_user->id )
    {
        # all good

        $form->fill(
            talk_title => $talk->title,
            abstract   => $talk->abstract,
            tags       => $talk->tags,
            duration   => $talk->duration,
            url        => $talk->url,
            comments   => $talk->comments,
            confirmed  => $talk->confirmed,
        );
        $tokens->{form}     = $form;
        $tokens->{accepted} = $talk->accepted;
        $tokens->{title}    = "Edit Talk",

        add_durations_token($tokens);

        template 'profile/create_update_talk', $tokens;
    }
    else {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        template '404', $tokens;
    }
};

=head2 post /profile/talk/:id

=cut

post '/profile/talk/:id' => require_login sub {
    my $tokens = {};

    my $talk = shop_schema->resultset('Talk')->find( param('id') );

    # check we have a talk for this conference owned by this user
    if (   $talk
        && $talk->conferences_id == setting('conferences_id')
        && $talk->author->id == logged_in_user->id )
    {
        # all good so validate

        my $form = form('create_update_talk');

        my ( $validator, $valid ) = validate_talk($form);

        if ($valid) {

            debug "valid values: ", $valid;

            my $tags = defined $valid->{tags} ? $valid->{tags} : '';
            $tags =~ s/,/ /g;
            $tags =~ s/\s+/ /g;

            ( my $abstract = $valid->{abstract} ) =~ s/\r\n/\n/;

            try {
                $talk->update(
                    {
                        title     => $valid->{talk_title},
                        abstract  => $abstract,
                        tags      => $tags,
                        duration  => $valid->{duration},
                        url       => $valid->{url} || '',
                        comments  => $valid->{comments} || '',
                        confirmed => $valid->{confirmed} ? 1 : 0,
                    }
                );

                debug "talk updated with id: ", $talk->id;

                my $html = template '/email/talk_submitted',
                  {
                    %$valid,
                    logged_in_user    => logged_in_user,
                    talk              => $talk,
                    "conference-logo" => uri_for(
                        shop_schema->resultset('Media')
                          ->search( { label => "email-logo" } )->first->uri
                    ),
                  },
                  { layout => 'email' };

                my $f    = HTML::FormatText::WithLinks->new;
                my $text = $f->parse($html);

                email {
                    subject => setting("conference_name") . " talk updated",
                    body    => $text,
                    type    => 'text',
                    attach  => {
                        Data     => $html,
                        Encoding => "quoted-printable",
                        Type     => "text/html"
                    },
                    multipart => 'alternative',
                };

                $form->reset;

                return redirect '/profile';
            }
            catch {
                # FIXME: handle errors
                error "Talk submission error: $_";
            };
        }
        else {
            my %errors;
            my $v_hash = $validator->errors_hash;
            while ( my ( $key, $value ) = each %$v_hash ) {
                $errors{$key} = $value->[0]->{value};
                $errors{ $key . '_input' } = 'has-error';
            }
            $tokens->{errors} = \%errors;
        }

        $tokens->{form}     = $form;
        $tokens->{accepted} = $talk->accepted;
        $tokens->{title}    = "Edit Talk",

        add_durations_token($tokens);

        template 'profile/create_update_talk', $tokens;
    }
    else {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        template '404', $tokens;
    }
};

=head2 get /register

=cut

get '/register' => sub {
    my $tokens = {
        title       => "Register",
        description => "Please complete the registration process",
        action      => "/register",
        action_name => "Registration",
        text =>
"Please enter your email address and hit submit to begin the registration process.",
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
        text =>
"Please enter your email address and hit submit to begin the password reset process.",
    };
    return template "register_reset", $tokens;
};

=head2 post /(register|reset_password)

Register of request password reset.

=cut

post qr{ /(?<action> register | reset_password )$ }x => sub {
    my $email = param('username') || param('register');
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

        # new registration
        try {
            $user = shop_user->create(
                { username => $username, email => $email } );
        }
        catch {
            error "create user failed in $action: $_";

            # TODO: send email to admins as well?
        }
    }

    if ($user) {
        my $token = $user->reset_token_generate;

        my $reason = $action eq 'register' ? 'register' : 'reset your password';
        my $action_name =
          $action eq 'register' ? 'registration' : 'password reset';

        my $html = template "email/generic",
          {
            "conference-logo" => uri_for(
                shop_schema->resultset('Media')
                  ->search( { label => "email-logo" } )->first->uri
            ),
            preamble =>
"You are receiving this email because your email address was used to $reason for the "
              . setting("conference_name")
              . ".\n\nIf you received this email in error please accept our apologies and delete this email. No further action is required on your part.\n\nTo continue with $action_name please click on the following link:",
            link => uri_for( path( request->uri, $token ) ),
          },
          { layout => 'email' };

        my $f    = HTML::FormatText::WithLinks->new;
        my $text = $f->parse($html);
        try {
            email {
                to      => $user->email,
                subject => "\u$action_name for the "
                  . setting("conference_name"),
                body   => $text,
                type   => 'text',
                attach => {
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
      {
        title       => "Thankyou",
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
            passwords        => {
                validator => 'Group',
                fields    => [ "password", "confirm_password" ],
            },
        );

        my $valid = $validator->transpose( \%params );

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

        if ($user) {

            if ( !$user->reset_token_verify($reset_token) ) {
                $tokens = {
                    title       => "Sorry",
                    description => "This $name link is no longer valid",
                    action      => "/$action",
                    action_name => $name,
                    text =>
"I am sorry but the $name link you entered is invalid.\n\nMaybe the link has expired - please retry $name.",
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
                session logged_in_user       => $user->username;
                session logged_in_user_id    => $user->id;
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
            $user = shop_user->find_user_with_reset_token($reset_token);
        };

        if ($user) {

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
                text =>
"I am sorry but the $name link you entered is invalid.\n\nMaybe the link has expired or it was copied incorrectly from the email.",
            };
            return template "register_reset", $tokens;
        }
    }
};

=head1 METHODS

=head2 add_durations_token( $tokens )

=cut

sub add_durations_token {
    my $tokens = shift;
    $tokens->{durations} = [
        {
            value => 20,
            label => "20 minutes",
        },
        {
            value => 40,
            label => "40 minutes",
        },
    ];
}

=head2 validate_talk( $form )

Returns ( $validator, $valid )

=cut

sub validate_talk {
    my $form = shift;

    my $values = $form->values;

    my $validator = Data::Transpose::Validator->new(
        stripwhite => 1,
    );

    $validator->prepare(
        talk_title => {
            validator => "String",
            required => 1,
        },
        abstract   => {
            validator => "String",
            required => 1,
        },
        tags => {
            validator => "String",
            required => 0,
        },
        duration   => {
            validator => {
                class   => "NumericRange",
                options => {
                    integer => 1,
                    min     => 20,
                    max     => 40,
                }
            },
            required => 1,
        },
        url => {
            validator => "String",
            required => 0,
        },
        comments => {
            validator => "String",
            required => 0,
        },
        confirmed => {
            required => 0,
        },
    );

    return ( $validator, $validator->transpose($values) );
}

true;
