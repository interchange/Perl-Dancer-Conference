package PerlDance::Routes::Profile;

=head1 NAME

PerlDance::Routes::Profile - account routes such as login, edit profile, ...

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::FlashNote;
use Dancer::Plugin::Form;
use Dancer::Plugin::Interchange6;
use Data::Transpose::Validator;
use File::Copy;
use File::Spec;
use File::Type;
use Geo::Coder::OSM;
use Geo::IP;
use HTML::FormatText::WithLinks;
use Imager;
use Try::Tiny;

=head1 ROUTES 

All routes in this class are prefixed with '/profile'

=cut

prefix '/profile';

=head2 get ''

Forward to / ( /profile/ )

=cut

get '' => sub {
    forward '/profile/';
};

=head2 any **

Force require_login on all routes under '/profile/**'

=cut

any '**' => require_login sub {
    pass;
};

=head2 get /

Profile update top-level page showing available options.

=cut

get '/' => sub {
    my $nav = shop_navigation( { uri => 'profile' } );

    my $talks = [
        logged_in_user->talks_authored->search(
            { conferences_id => setting('conferences_id') }
        )->hri->all
    ];

    # check whether user ordered a ticket
    my $order_rs = logged_in_user->orders;
    my $order_number;

    while (my $order = $order_rs->next) {
        my $orderline_rs = $order->orderlines;

        while (my $orderline = $orderline_rs->next) {
            my ($ct, $conf);

            if ($ct = $orderline->product->conference_ticket) {
                if (($conf = $ct->conference)
                        && $conf->name eq config->{'conference_name'}) {
                    $order_number = $order->order_number;
                    last;
                }
            }
        }
    }

    my $tokens = {
        title       => 'Profile',
        description => 'Update profile',
        has_talks   => scalar(@$talks),
        profile_nav =>
          [ $nav->active_children->order_by('!priority')->hri->all ],
        talks => $talks,
    };

    # Ticket link
    if ($order_rs->count > 1) {
        push @{$tokens->{profile_nav}}, {
            name => 'View your conference tickets',
            uri => "profile/orders",
        }
    }
    elsif ($order_number) {
        push @{$tokens->{profile_nav}}, {
            name => 'View your conference ticket',
            uri => "profile/orders/$order_number",
        }
    }
    else {
        push @{$tokens->{profile_nav}}, {
            name => 'Buy your conference ticket',
            uri => 'tickets',
        }
    }

    template 'profile', $tokens;
};

=head2 get /edit

=cut

get '/edit' => sub {
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
        $values{company}   = $address->company;
        $values{city}      = $address->city;
        $values{country}   = $address->country_iso_code;
        $values{company}   = $address->company;
        $values{latitude}  = $address->latitude;
        $values{longitude} = $address->longitude;
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
                    if ($record) {
                        $values{city}      = $record->city;
                        $values{country}   = $record->country_code;
                        $values{latitude}  = $record->latitude;
                        $values{longitude} = $record->longitude;
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

    PerlDance::Routes::add_javascript( $tokens, '/js/profile-edit.js' );

    template 'profile/edit', $tokens;
};

=head2 post /edit

=cut

post '/edit' => sub {
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
    $values{nickname} ||= undef;
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
                latitude         => $values{latitude} || undef,
                longitude        => $values{longitude} || undef,
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
                    latitude         => $values{latitude} || undef,
                    longitude        => $values{longitude} || undef,
                }
            );
        }
    }

    flash success => "Profile updated.";
    $form->reset;
    redirect '/profile';
};

=head2 post /geocode

Ajax route to geocode address data

=cut

post '/geocode' => sub {
    my $address = param 'address';

    debug "geocoding $address";

    my ( $latitude, $longitude );
    my $geocoder = Geo::Coder::OSM->new;
    my $location = $geocoder->geocode( location => $address );

    debug to_dumper($location);

    if ($location) {
        $latitude  = $location->{lat};
        $longitude = $location->{lon};
    }

    content_type 'application/json';
    return to_json( { latitude => $latitude, longitude => $longitude } );
};

=head2 get /password

=cut

get '/password' => sub {
    template 'profile/password', { title => 'Change Password' };
};

=head2 post /password

=cut

post '/password' => sub {

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
        flash success => "Password changed.";
        redirect '/profile';
    }
    else {
        my $tokens = { title => "Change Password " };
        PerlDance::Routes::add_validator_errors_token( $validator, $tokens );
        template 'profile/password', $tokens;
    }
};

=head2 get /photo

Profile photo display/update

=cut

get '/photo' => sub {
    my $tokens = {};

    PerlDance::Routes::add_javascript( $tokens, '/js/profile-photo.js' );

    my $photo = logged_in_user->photo;
    if ( !$photo ) {
        $photo = rset('Media')->search(
            {
                'me.label'        => 'unknown user',
                'media_type.type' => 'image',
            },
            {
                join => 'media_type',
                rows => 1,
            }
        )->single;
    }
    $tokens->{photo} = $photo;

    template 'profile/photo', $tokens;
};

post '/photo/upload' => sub {
    if ( request->is_ajax ) {

        # FIXME: upload dir from config
        my $file = upload('photo');

        # copy file to uploads dir
        my $upload_dir = path( setting('public'), 'img', 'uploads' );

        my ( undef, undef, $tempname ) =
          File::Spec->splitpath( $file->tempname );
        $tempname = "temp-$tempname";

        my $target = path( $upload_dir, $tempname );
        $file->copy_to($target);

        # stash path to new file location in session
        session new_photo => $target;

        # return url of image
        my $url = uri_for( path( '/', 'img', 'uploads', $tempname ) );
        debug "image url: $url";

        # force stringification of url since it is a URI object
        content_type('application/json');
        return to_json({ src => "$url" });
    }
    else {
        # TODO: handle non-ajax post
    }
};

post '/photo/crop' => sub {
    use Imager;
    my $file = session('new_photo');
    my $user = logged_in_user;

    my $ft = File::Type->new;
    my $mime_type = $ft->checktype_filename($file);

    die "Not an image" unless $mime_type =~ /^image\//;

    ( my $type = $mime_type ) =~ s/^.+?\///;
    $type = 'png' if lc($type) eq 'x-png';

    my $img = Imager->new;
    $img->read( file => $file )
      or die "Cannot read photo $file: ", $img->errstr;

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

    $img->write( %options ) or die "image write failed: ", $img->errstr;

    ( my $file_ext = $file ) =~ s/^.+\.//;

    my $target = lc( $user->name );
    $target =~ s/(^\s+|\s+$)//g;
    $target =~ s/\s+/-/g;
    $target = "img/uploads/user-" . $user->id . "-$target.$file_ext";

    my $photo = $user->photo;

    if ( $photo ) {
        debug "updating existing photo record";
        $photo->update(
            {
                file           => $target,
                uri            => "/$target",
                mime_type      => $mime_type,
            }
        ) or die "failed to update photo record in database";
    }
    else {

        debug "creating new photo record";

        my $media_type_image = rset('MediaTyp')->find( { type => 'image' } );
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

    my $fullpath = path( setting('public'), $target );

    debug "moving temp file to: $fullpath";

    move( $file, $fullpath );

    redirect '/profile/photo';
};

=head2 get /talk/create

create new talk

=cut

get '/talk/create' => sub {
    my $tokens = {
        title => "New Talk",
    };

    $tokens->{form} = form('create_update_talk');
    $tokens->{form}->reset;
    $tokens->{form}->fill( duration => 40 );

    add_durations_token($tokens);

    template 'profile/create_update_talk', $tokens;
};

=head2 post /talk/create

=cut

post '/talk/create' => sub {
    my $tokens = {};

    my $form   = form('create_update_talk');

    my ( $validator, $valid ) = validate_talk($form);

    if ($valid) {

        debug "valid values: ", $valid;

        my $tags = defined $valid->{tags} ? $valid->{tags} : '';
        $tags =~ s/,/ /g;
        $tags =~ s/\s+/ /g;

        ( my $abstract = $valid->{abstract} ) =~ s/\r\n/\n/;

        my $success;

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
            flash success => "Thankyou for submitting your talk. We will be in contact soon";
            $success = 1;
        }
        catch {
            # FIXME: handle errors
            error "Talk submission error: $_";
        };
        # we can't return inside the try block so we do it based on $success
        if ( $success ) {
            return redirect '/profile';
        }
    }

    debug "talk submission errors: ", $validator->errors_as_hashref_for_humans;

    PerlDance::Routes::add_validator_errors_token( $validator, $tokens );

    $tokens->{form} = $form;

    add_durations_token($tokens);

    template 'profile/create_update_talk', $tokens;
};

=head2 get /talk/:id

=cut

get '/talk/:id' => sub {
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
        $tokens->{form}      = $form;
        $tokens->{accepted}  = $talk->accepted;
        $tokens->{confirmed} = $talk->confirmed;
        $tokens->{title}     = "Edit Talk",

        add_durations_token($tokens);

        template 'profile/create_update_talk', $tokens;
    }
    else {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        template '404', $tokens;
    }
};

=head2 post /talk/:id

=cut

post '/talk/:id' => sub {
    my $tokens = {};

    my $talk = shop_schema->resultset('Talk')->find( param('id') );

    # check we have a talk for this conference owned by this user
    if (   $talk
        && $talk->conferences_id == setting('conferences_id')
        && $talk->author->id == logged_in_user->id )
    {
        # all good so validate

        my $form = form('create_update_talk');
        my $values = $form->values;

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
                        confirmed => $valid->{confirmed},
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
            debug "errors: ", $validator->errors_as_hashref_for_humans;
        }

        PerlDance::Routes::add_validator_errors_token( $validator, $tokens );

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

=head2 get /orders

=cut

get '/orders' => sub {
    my $orders = logged_in_user->orders->order_by('!order_date');
    template '/profile/orders', { title => "Your Orders", orders => $orders };
};

=head2 get /orders/:order_number

display order information

=cut

get '/orders/:order_number' => sub {
    my $profile_url = uri_for('profile');

    # verify if order exists and belongs to current user
    my $order_number = param('order_number');
    my $order = schema->resultset('Order')->find({
        order_number => $order_number,
    });

    if (! $order) {
        return redirect $profile_url;
    }

    my $order_user = $order->user;
    my $current_user = logged_in_user;

    if ($order_user->id != $current_user->id) {
        # order belongs to other customer
        return redirect $profile_url;
    }

    my $tokens = {order => $order};

    # check whether this is a receipt for recent order
    if (defined session->{order_receipt}
            && session->{order_receipt} eq $order_number) {
        $tokens->{receipt} = session->{order_receipt};

        # send email receipt
        order_receipt($order);
    }

    session order_receipt => undef;

    template 'profile/order', $tokens;
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


=head2 order_receipt( $order )

Send order receipt as email.

=cut

sub order_receipt {
    my $order = shift;

    try {
        PerlDance::Routes::send_email(
            template => "email/receipt",
            tokens => {
                order   => $order,
                link => uri_for( path( "/profile/orders", $order->id ) ),
            },
            to      => $order->email,
            bcc     => '2015@perl.dance',
            subject => "Your Ticket for " . setting("conference_name"),
        );
    }
    catch {
        error "Could not send email: $_";
    };

    return 1;
}

# undef prefix - keep as last line before 'true'
prefix undef;
true;
