package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk/Event routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use DateTime;
use HTML::FormatText::WithLinks;
use HTML::TagCloud;
use Safe::Isa;
use Try::Tiny;

=head1 ROUTES

=head2 get /events/{id}.*

Individual event

=cut

get qr{/events/(?<id>\d+).*} => sub {
    my $id     = captures->{id};
    my $tokens = {};

    my $event = rset('Event')->find(
        {
            events_id      => $id,
            conferences_id => setting('conferences_id'),
        },
    );

    if ( !$event ) {
        $tokens->{title} = "Event Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{event} = $event;
    $tokens->{title} = $event->title;

    template 'event', $tokens;
};

=head2 get /talks

Talks list by speaker

=cut

get '/talks' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    my $talks = rset('Talk')->search(
        {
            'me.conferences_id' => setting('conferences_id'),
        },
    );
    $tokens->{talks_submitted} = $talks->count;

    my $talks_accepted = $talks->search( { accepted => 1 } );
    $tokens->{talks_accepted} = $talks_accepted->count;

    my %tags;
    map { $tags{$_}++ } map { s/,/ /g; split( /\s+/, $_ ) }
      $talks_accepted->get_column('tags')->all;
    my $cloud = HTML::TagCloud->new;
    foreach my $tag ( sort keys %tags ) {

        # add space to tag to force wrapping since TF removes the line breaks
        # added by HTML::TagCloud
        $cloud->add( "$tag ", "/talks/tag/$tag", $tags{$tag} );
    }
    $tokens->{cloud} = $cloud->html;

    if ( !user_has_role('admin') ) {
        $talks = $talks_accepted;
    }

    $talks = $talks->search(
        { "conferences_attended.conferences_id" => setting('conferences_id') },
        {
            order_by => [ 'author.first_name', 'author.last_name' ],
            prefetch => 'author',
            join => { author => 'conferences_attended' },
        }
    );

    if ( my $tag = var('tag') ) {
        my $tagged_talks = $talks->search(
            {
                "me.tags" => { like => '%' . $tag . '%' }
            }
        );
        if ( $tagged_talks->has_rows ) {
            $talks = $tagged_talks;
            $tokens->{tag} = $tag;
            $tokens->{title} .= " | " . $tag;
        }
    }

    if ( my $user = logged_in_user ) {
        $talks = $talks->with_attendee_status( $user->id );
    }

    $tokens->{talks} = [ $talks->all ];

    template 'talks', $tokens;
};

=head2 get /talks/schedule

Talks schedule

=cut

get '/myschedule' => require_login sub {
    var uri => '/myschedule';
    forward '/talks/schedule';
};

get '/talks/schedule' => sub {
    my $tokens     = {};
    my $conference = rset('Conference')->find( setting('conferences_id') );
    my $uri = var('uri') || '/talks/schedule';

    # paranoia checks on conference
    if (   !$conference
        || !$conference->start_date
        || !$conference->end_date
        || $conference->end_date < $conference->start_date )
    {
        warning "Conference record missing or start/end dates missing/broken";
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $dt    = $conference->start_date->clone;
    my $today = DateTime->today();

    if ( $today >= $conference->start_date && $today <= $conference->end_date )
    {
        redirect path( $uri, $today->ymd );
    }
    else {
        redirect path( $uri, $conference->start_date->ymd );
    }
};

get '/myschedule/:date' => require_login sub {
    var myschedule => 1;
    forward path( '/talks/schedule', param('date') );
};

get '/talks/schedule/:date' => sub {
    my $tokens = {};

    my $date = param 'date';
    if ( $date !~ m/^(\d+)-(\d+)-(\d+)$/ ) {
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $dt_date = DateTime->new( year => $1, month => $2, day => $3 );
    my $conference = rset('Conference')->find( setting('conferences_id') );

    if (   $dt_date < $conference->start_date
        || $dt_date > $conference->end_date )
    {
        redirect '/talks/schedule/' . $conference->start_date->ymd;
    }

    # paranoia checks on conference
    if (   !$conference
        || !$conference->start_date
        || !$conference->end_date
        || $conference->end_date < $conference->start_date )
    {
        warning "Conference record missing or start/end dates missing/broken";
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    # days token
    my $base_uri = var('myschedule') ? '/myschedule' : '/talks/schedule';
    for (
        my $i = $conference->start_date->clone ;
        $i <= $conference->end_date ;
        $i->add( days => 1 )
      )
    {
        my $data = {
            uri   => path($base_uri, $i->ymd),
            label => $i->day_name
        };
        $data->{class} = "active" if $i == $dt_date;
        push @{ $tokens->{days} }, $data;
    }

    my $schema = schema;

    # base Event and Talk searches
    my $events = rset('Event')->search(
        {
            conferences_id => setting('conferences_id'),
            room           => { '!=' => '' },
            start_time     => {
                '!=' => undef,
                '>=' => $schema->format_datetime($dt_date),
                '<=' =>
                  $schema->format_datetime( $dt_date->clone->add( days => 1 ) )
            },
        },
        {
            order_by => 'start_time',
        }
    );

    my $talks = rset('Talk')->search(
        {
            accepted       => 1,
            conferences_id => setting('conferences_id'),
            room           => { '!=' => '' },
            start_time     => {
                '!=' => undef,
                '>=' => $schema->format_datetime($dt_date),
                '<=' =>
                  $schema->format_datetime( $dt_date->clone->add( days => 1 ) )
            },
        },
        {
            order_by => 'start_time',
            prefetch => 'author',
        }
    )->with_attendee_count;

    if ( my $user = logged_in_user ) {

        $talks = $talks->with_attendee_status( $user->id );

        if ( var('myschedule') ) {

            # personal schedule (forwarded from /myschedule/:date)
            $talks = $talks->search(
                {
                    'attendee_talks.users_id' => logged_in_user->id,
                },
                {
                    join => 'attendee_talks',
                }
            );
        }
    }

    if ( user_has_role('admin') ) {

        # admins are also shown accepted talks and events which have
        # no start_time or no room defined

        my @events = rset('Event')->search(
            {
                conferences_id => setting('conferences_id'),
                -or            => {
                    room       => '',
                    start_time => undef,
                },
            },
            {
                order_by => 'start_time',
            }
        )->all;

        $tokens->{unscheduled_events} = \@events if @events;

        my @talks = rset('Talk')->search(
            {
                accepted       => 1,
                conferences_id => setting('conferences_id'),
                -or            => {
                    room       => '',
                    start_time => undef,
                },
            },
            {
                order_by => 'start_time',
                prefetch => 'author',
            }
        )->all;

        $tokens->{unscheduled_talks} = \@talks if @talks;

    }
    else {

        # non-Admins can only see things that are 'scheduled'
        $events = $events->search( { scheduled => 1 } );
        $talks = $talks->search( { scheduled => 1 } );
    }

    # css classes for event cells (just a little colouring)
    my %classes = (
        1 => "success",
        2 => "danger",
        3 => "info",
        0 => "warning",
    );

    my @all =
      sort { $a->start_time cmp $b->start_time } ( $events->all, $talks->all );

    # unique room names
    my %rooms = map { $_->room => 1 } @all;
    my @rooms = sort keys %rooms;
    $tokens->{rooms} = [ map { { name => $_ } } @rooms ];

    # track overlapped cells due to rowspans
    my %emptycell;

    if (@all) {

        # we have some talks/events

        # we need a unique set of all start and end times
        my %times =
          map { $_->strftime("%H:%M") => $_ }
          map { $_->start_time, $_->end_time } @all;

        my $i = 0;
        %times =
          map { $_ => { row => ++$i, datetime => $times{$_} } }
          sort keys %times;

        # spin through all collected times - we will have one row for each
        my @rows;
        foreach my $time ( sort keys %times ) {

            my $val = $times{$time};
            my $dt  = $val->{datetime};
            my $row = $val->{row};

            my @slots;
            my $col = 0;

            # add room columns
          ROOM: foreach my $room (@rooms) {

                my $data = {};
                $col++;

                next ROOM if ( $emptycell{"$row:$col"} );

                my @found =
                  grep { $_->start_time == $dt && $_->room eq $room } @all;

                if (@found) {
                    if ( @found > 1 ) {

                        # more than one talk at this time in this room
                        # this is ** BAD **
                        $data =
                          {     title => "WARNING: "
                              . ( scalar @found )
                              . "talks clash: "
                              . join( " | ", map { $_->title } @found ) };

                    }
                    else {

                        # a Talk or an Event
                        my $e = $found[0];
                        $data = {
                            class    => $classes{ $col % 4 },
                            title    => $e->title,
                            duration => $e->duration,
                            uri      => $e->seo_uri,
                        };

                        my $last_row =
                          $times{ $e->end_time->strftime("%H:%M") }->{row};

                        if ( $last_row > $row ) {
                            $data->{rowspan} = $last_row - $row;
                            foreach my $i ( $row .. --$last_row ) {
                                $emptycell{"$i:$col"} = 1;
                            }
                        }

                        if ( $e->$_can("talks_id") ) {

                            # a Talk so add more stuff
                            $data->{is_talk}         = 1;
                            $data->{author_name}     = $e->author->name;
                            $data->{author_nickname} = $e->author->nickname;
                            $data->{author_uri}      = $e->author->uri;
                            $data->{stars}           = $e->attendee_count;
                            $data->{id}              = $e->id;
                            if (logged_in_user) {
                                $data->{attendee_status} = $e->attendee_status;
                            }
                        }
                        else {
                            $data->{is_event} = 1;
                        }
                    }
                }
                else {
                    $data = { is_empty => 1 };
                }
                push @slots, $data;
            }
            push @rows, { time => $time, slots => \@slots };
        }

        $tokens->{rows} = \@rows;
    }

    if ( var('myschedule') ) {
        $tokens->{title} = "Personal Schedule for $date";
    }
    else {
        $tokens->{title} = "Talks Schedule for $date";
    }
    $tokens->{date} = $dt_date;

    template 'schedule', $tokens;
};

=head2 get /talks/tag/:tag

Tag cloud links in /talks

=cut

get '/talks/tag/:tag' => sub {
    var tag => param('tag');
    forward '/talks';
};

=head2 get /talks/{add|remove}/:id

Add/remove talks from personal schedule

=cut

get '/talks/:action/:id' => require_login sub {

    content_type 'application/json';

    my $action   = param 'action';
    my $talks_id = param 'id';
    my $json     = { result => "fail" };

    if ( $action =~ /^(add|remove)$/ ) {
        if ( my $talk = rset('Talk')->find($talks_id) ) {
            my $users_id = logged_in_user->id;
            if ( $action eq 'add' ) {
                try {
                    $talk->create_related( 'attendee_talks',
                        { users_id => $users_id } );
                    debug "add user $users_id to talk $talks_id";
                    $json = {
                        result => "success",
                        href   => "/talks/remove/$talks_id",
                        src    => "/img/picked.gif",
                        title  => "remove from personal schedule",
                    };
                };
            }
            else {
                try {
                    $talk->delete_related( 'attendee_talks',
                        { users_id => $users_id } );
                    debug "remove user $users_id from talk $talks_id";
                    $json = {
                        result => "success",
                        href   => "/talks/add/$talks_id",
                        src    => "/img/unpicked.gif",
                        title  => "add to personal schedule",
                    };
                };
            }
        }
    }

    return to_json($json);
};

=head2 get /talks/favourite

Talks order by number of attendees

=cut

get '/talks/favourite' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    my $talks = rset('Talk');
    $talks = $talks->search(
        {
            conferences_id => setting('conferences_id'),
            accepted       => 1,
        },
    )->with_attendee_count;

    $tokens->{talks} =
      [ sort { $b->attendee_count <=> $a->attendee_count } $talks->all ];

    template 'talks/favourite', $tokens;
};

=head2 get /talks/submit

CFP

=cut

get '/talks/submit' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    template 'cfp', $tokens;
};

=head2 get /talks/{id}.*

Individual talk

=cut

get qr{/talks/(?<id>\d+).*} => sub {
    my $talks_id = captures->{id};
    my $tokens   = {};

    my $talk = rset('Talk')->find(
        {
            talks_id       => $talks_id,
            accepted       => 1,
            conferences_id => setting('conferences_id'),
        },
        { prefetch => [ 'author', { attendee_talks => 'user' } ], }
    );

    if ( !$talk ) {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{talk}          = $talk;
    $tokens->{title}         = $talk->title;
    $tokens->{has_attendees} = $talk->attendee_talks->count;

    if ( my $user = logged_in_user ) {
        $tokens->{attendee_status} = $talk->attendee_status( $user->id );
    }

    template 'talk', $tokens;
};

true;
