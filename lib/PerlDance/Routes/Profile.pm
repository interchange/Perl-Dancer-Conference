package PerlDance::Routes::Profile;

=head1 NAME

PerlDance::Routes::Profile - account routes such as login, edit profile, ...

=cut

use Dancer2 appname => 'PerlDance';
use Carp;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DataTransposeValidator;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Email;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::TemplateFlute;
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

    my $user = schema->current_user;
    my $talks = [
        $user->talks_authored->search(
            { conferences_id => setting('conferences_id') }
        )->hri->all
    ];

    # check whether user ordered a ticket
    my $order_rs = $user->orders;
    my $order_number = conference_ticket($order_rs);
    my $unregister_link = user_can_unregister($user, $order_rs, $talks);

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
    my $registered = user_is_registered($user);
    if ($registered && $unregister_link) {
        push @{$tokens->{profile_nav}}, {
                                         name => 'Unregister from the conference',
                                         uri => $unregister_link,
                                        };
    }
    elsif (!$registered) {
        push @{$tokens->{profile_nav}}, {
                                         name => 'Register to the conference',
                                         uri => 'profile/register',
                                        };
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

    my $user = schema->current_user;
    my %values = (
        first_name    => $user->first_name,
        last_name     => $user->last_name,
        nickname      => $user->nickname,
        monger_groups => $user->monger_groups,
        pause_id      => $user->pause_id,
        bio           => $user->bio,
        t_shirt_size  => $user->t_shirt_size,
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
        $values{state}     = $address->states_id;
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
                        $values{country}   = uc($record->country_code);
                        $values{latitude}  = $record->latitude;
                        $values{longitude} = $record->longitude;

                        my $country = rset('Country')
                          ->find( { country_iso_code => $values{country} } );

                        if ( $country && $country->show_states ) {
                            my $state = $country->states->search(
                                { state_iso_code => uc( $record->region ) } );
                            if ($state->rows == 1) {
                                $values{state} = $state->first->id;
                            }
                            else {
                                warning "State not found for country $values{country}, region ", $record->region, " from ip $ipaddress.";
                            }
                        }
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

    # if state is defined then we pass this to template where it gets inserted
    # as data into state select so that on page load profile-edit.js can
    # set the appropriate state as "selected"
    $tokens->{state} = $values{state} if $values{state};

    PerlDance::Routes::add_tshirt_sizes( $tokens, $values{t_shirt_size} );

    PerlDance::Routes::add_javascript( $tokens, '/data/states.js',
        '/js/profile-edit.js' );

    template 'profile/edit', $tokens;
};

=head2 post /edit

=cut

post '/edit' => sub {
    my $tokens = {};

    my $form   = form('edit_profile');
    my %values = %{ $form->values };

    $values{bio} =~ s/\r\n/\n/g;
    $values{nickname} = undef unless $values{nickname} =~ /\S/;

    my $user = schema->current_user;

    # TODO: validate values and if OK then try update
    $user->update(
        {
            first_name    => $values{first_name}    || '',
            last_name     => $values{last_name}     || '',
            nickname      => $values{nickname},
            monger_groups => $values{monger_groups} || '',
            pause_id      => $values{pause_id}      || '',
            bio           => $values{bio}           || '',
            t_shirt_size  => $values{t_shirt_size}  || undef,
        }
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

    my $country =
      rset('Country')->find( { country_iso_code => uc( $values{country} ) } );

    #FIXME: if we have $values{country} but $country is undef then ??

    if ($country) {

        $values{state} = undef unless $country->show_states;

        if ($address) {
            $address->update(
                {
                    company => $values{company} || '',
                    city    => $values{city}    || '',
                    states_id        => $values{state},
                    country_iso_code => $values{country},
                    latitude         => $values{latitude} || undef,
                    longitude        => $values{longitude} || undef,
                }
            );
        }
        else {
            $user->create_related(
                'addresses',
                {
                    type             => 'primary',
                    company          => $values{company} || '',
                    city             => $values{city} || '',
                    states_id        => $values{state},
                    country_iso_code => $values{country},
                    latitude         => $values{latitude} || undef,
                    longitude        => $values{longitude} || undef,
                }
            );
        }
    }

    deferred success => "Profile updated.";
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
    my $form = form('change-password');
    $form->reset;
    template 'profile/password', { title => 'Change Password' };
};

=head2 post /password

=cut

post '/password' => sub {

    my $form = form('change-password');
    my $user = schema->current_user;
    my $data = validator( $form->values, 'change-password', $user );

    # we don't want form data to leak into the session
    $form->reset;

    if ( $data->{valid} ) {
        $user->update( { password => $data->{values}->{password} } );
        deferred success => "Password changed.";
        redirect '/profile';
    }
    else {
        my $tokens =
          { title => "Change Password", form => $form, data => $data };
        template 'profile/password', $tokens;
    }
};

=head2 get /photo

Profile photo display/update

=cut

get '/photo' => sub {
    my $tokens = {};

    PerlDance::Routes::add_javascript( $tokens, '/js/profile-photo.js' );

    my $user = schema->current_user;
    my $photo = $user->photo;

    debug "User already has photo with id: ", $photo->id if $photo;

    if ( !$photo ) {
        $photo = rset('Media')->find(
            {
                file => 'img/people/unknown.jpg',
            }
        );

        if ( $photo ) {
            debug "Got anon user photo with id: ", $photo->id if $photo;
        }
        else {
            debug "Anon user photo not found";
        }

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
    my $user = schema->current_user;

    my $ft = File::Type->new;
    my $mime_type = $ft->checktype_filename($file);

    croak "Not an image" unless $mime_type =~ /^image\//;

    ( my $type = $mime_type ) =~ s/^.+?\///;
    $type = 'png' if lc($type) eq 'x-png';

    my $img = Imager->new;
    $img->read( file => $file )
      or croak "Cannot read photo $file: ", $img->errstr;

    debug "cropping photo";

    $img = $img->crop(
        left   => param('x'),
        top    => param('y'),
        width  => param('w'),
        height => param('h')
    ) or croak "image crop failure: ", $img->errstr;

    debug "scaling image";

    $img = $img->scale( xpixels => 300, ypixels => 300 )
      or croak "image scale failure: ", $img->errstr;

    my %options = ( file => $file, type => $type );

    $options{jpegquality} = 90 if $type eq 'jpeg';

    debug "saving image";

    $img->write( %options ) or croak "image write failed: ", $img->errstr;

    ( my $file_ext = $file ) =~ s/^.+\.//;

    my $target = lc( $user->name );
    $target =~ s/(^\s+|\s+$)//g;
    $target =~ s/\s+/-/g;
    $target = "img/uploads/user-" . $user->id . "-$target.$file_ext";

    my $photo = $user->photo;

    if ( $photo && $photo->file ne 'img/people/unknown.jpg' ) {
        debug "updating existing photo record";
        $photo->update(
            {
                file           => $target,
                uri            => "/$target",
                mime_type      => $mime_type,
            }
        ) or croak "failed to update photo record in database";
    }
    else {

        debug "creating new photo record";

        my $media_type_image = rset('MediaType')->find( { type => 'image' } );
        my $photo = rset('Media')->create(
            {
                file           => $target,
                uri            => "/$target",
                mime_type      => $mime_type,
                media_types_id => $media_type_image->id,
            }
        ) or croak "failed to create photo record in database";
        $user->update({ media_id => $photo->id });
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

    $tokens->{form} = form('create-update-talk');
    $tokens->{form}->reset;
    $tokens->{form}->fill( duration => 40 );

    add_durations_token($tokens);

    template 'profile/create_update_talk', $tokens;
};

=head2 post /talk/create

=cut

post '/talk/create' => sub {
    my $tokens = {};

    my $form = form('create-update-talk');
    my $data = validator( $form->values, 'create-update-talk' );
    my $user = schema->current_user;

    if ($data->{valid}) {

        debug "valid values: ", $data->{values};

        my $tags =
          defined $data->{values}->{tags} ? $data->{values}->{tags} : '';
        $tags =~ s/,/ /g;
        $tags =~ s/\s+/ /g;

        ( my $abstract = $data->{values}->{abstract} ) =~ s/\r\n/\n/;

        my $success;

        try {
            my $talk = shop_schema->resultset('Talk')->create(
                {
                    author_id      => $user->id,
                    conferences_id => setting('conferences_id'),
                    title          => $data->{values}->{title},
                    abstract       => $abstract,
                    tags           => $tags,
                    duration       => $data->{values}->{duration},
                    url            => $data->{values}->{url} || '',
                    comments       => $data->{values}->{comments} || '',
                }
            );

            debug "new talk submitted";

            PerlDance::Routes::send_email(
                template => '/email/talk_submitted',
                tokens   => {
                    %{ $data->{values} },
                    logged_in_user => $user,
                    talk           => $talk,
                },
                subject => setting("conference_name") . " talk submitted",
            );

            debug "sent email/talk_submitted";

            $form->reset;
            deferred success => "Thank you for submitting your talk. We will be in contact soon";
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

    debug "talk submission errors: ", $data->{errors};

    $tokens->{data} = $data;
    $tokens->{form} = $form;

    add_durations_token($tokens);

    template 'profile/create_update_talk', $tokens;
};

=head2 get /talk/:id

=cut

get '/talk/:id' => sub {
    my $tokens = {};

    my $form = form('create-update-talk');
    $form->reset;

    my $talk = shop_schema->resultset('Talk')->find(param('id'));
    my $user = schema->current_user;

    # check we have a talk for this conference owned by this user
    if (   $talk
        && $talk->conferences_id == setting('conferences_id')
        && $talk->author->id == $user->id )
    {
        # all good

        $form->fill(
            title      => $talk->title,
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
        send_error( "Talk not found.", 404 );
    }
};

=head2 post /talk/:id

=cut

post '/talk/:id' => sub {
    my $tokens = {};

    my $talk = shop_schema->resultset('Talk')->find( param('id') );
    my $user = schema->current_user;

    # check we have a talk for this conference owned by this user
    if (   $talk
        && $talk->conferences_id == setting('conferences_id')
        && $talk->author->id == $user->id )
    {
        # all good so validate

        my $form = form('create-update-talk');
        my $data = validator( $form->values, 'create-update-talk' );

        if ($data->{valid}) {

            debug "valid values: ", $data->{values};

            my $tags =
              defined $data->{values}->{tags} ? $data->{values}->{tags} : '';
            $tags =~ s/,/ /g;
            $tags =~ s/\s+/ /g;

            ( my $abstract = $data->{values}->{abstract} ) =~ s/\r\n/\n/;

            try {
                $talk->update(
                    {
                        title     => $data->{values}->{title},
                        abstract  => $abstract,
                        tags      => $tags,
                        duration  => $data->{values}->{duration},
                        url       => $data->{values}->{url} || '',
                        comments  => $data->{values}->{comments} || '',
                        confirmed => $data->{values}->{confirmed} || 0,
                    }
                );

                debug "talk updated with id: ", $talk->id;

                PerlDance::Routes::send_email(
                    template => '/email/talk_submitted',
                    tokens   => {
                        %{ $data->{values} },
                        logged_in_user => $user,
                        talk           => $talk,
                    },
                    subject => setting("conference_name") . " talk updated",
                );
                $form->reset;

                return redirect '/profile';
            }
            catch {
                error "Talk update error: $_";
                deferred error => "Talk update error: $_";
            };
        }
        else {
            debug "errors: ", $data->{errors};
        }

        $tokens->{data}     = $data;
        $tokens->{form}     = $form;
        $tokens->{accepted} = $talk->accepted;
        $tokens->{title}    = "Edit Talk",

        add_durations_token($tokens);

        template 'profile/create_update_talk', $tokens;
    }
    else {
        send_error( "Talk not found.", 404 );
    }
};

=head2 get /orders

=cut

get '/orders' => sub {
    my $user = schema->current_user;
    my $orders = $user->orders->order_by('!order_date');
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
    my $current_user = schema->current_user;

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

=head2 order_receipt( $order )

Send order receipt as email.

=cut

sub order_receipt {
    my $order = shift;

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
    return 1;
}

sub conference_ticket {
    my ($order_rs) = @_;
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
    $order_rs->reset;
    return $order_number;
}

sub user_can_unregister {
    # we don't need arguments, but save queries if passed
    my ($user, $order_rs, $talks) = @_;
    my $conference_id = setting('conferences_id');

    $user ||= schema->current_user;
    return 0 unless $user;
    return 0 unless user_is_registered($user);
    unless ($order_rs) {
        $order_rs = $user->orders;
    }
    if (conference_ticket($order_rs)) {
        return 0;
    }
    $talks ||= [
                $user->talks_authored
                ->search(
                         { conferences_id => $conference_id }
                        )->hri->all
               ];
    if (@$talks) {
        return 0;
    }
    else {
        # nor talks, nor tickets
        return 'profile/unregister';
    }
}

get '/unregister' => sub {
    my $user = schema->current_user;
    my $conference_id = setting('conferences_id');
    if (user_can_unregister($user)) {
        if (my $record = user_is_registered($user)) {
            $record->delete;
            deferred success => "You unregistered from the conference!";
        }
        else {
            # shouldn't happen, though
            deferred error => "You are already unregistered!";
        }
    }
    else {
        deferred error => "You can't unregister!";
    }
    return redirect '/profile';
};

get '/register' => sub {
    my $user = schema->current_user;
    my $conference_id = setting('conferences_id');
    if (user_is_registered($user)) {
        deferred error => "You are already registered!";
    }
    else {
        $user->conferences_attended
          ->update_or_create({ conferences_id => $conference_id });
        deferred success => "You are registered now!";
    }
    return redirect '/profile';
};


sub user_is_registered {
    my $user = shift || schema->current_user;
    return unless $user;
    my $conference_id = setting('conferences_id');
    # debug "Checking " . $user->username . " for $conference_id";
    return $user->conferences_attended->find({ conferences_id => $conference_id });
}

# undef prefix - keep as last line before 'true'
prefix undef;
true;
