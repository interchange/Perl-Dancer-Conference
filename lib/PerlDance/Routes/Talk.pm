package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Data::Transpose::Validator;
use DateTime;
use DateTime::Span;
use DateTime::SpanSet;
use HTML::FormatText::WithLinks;
use HTML::TagCloud;
use Safe::Isa;
use Try::Tiny;

=head1 ROUTES

=head2 get /talks

Talks list by speaker

=cut

get '/talks' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    my $talks = rset('Talk')->search(
        {
            conferences_id => setting('conferences_id'),
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
        undef,
        {
            order_by => [ 'author.first_name', 'author.last_name' ],
            prefetch => 'author',
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

=head2 get /talks/schedule

Talks schedule

=cut

get '/talks/schedule' => sub {
    my $tokens = {};

    my $conference = rset('Conference')->find( setting('conferences_id') );

    # paranoia checks on conference
    if (   !$conference
        || !$conference->start_date
        || !$conference->end_date
        || $conference->end_date < $conference->start_date )
    {
        warning "Conference record missing or start/end dates missing/broken";
        $tokens->{title} = "Not found";
        status 'not_found';
        template '404', $tokens;
    }

    PerlDance::Routes::add_javascript( $tokens, '/js/schedule.js' );
    PerlDance::Routes::add_navigation_tokens($tokens);

    my $dt    = $conference->start_date->clone;
    my $today = DateTime->today();

    # one tab for each day of the conference
    my @days;
    while ( $dt <= $conference->end_date ) {
        my $data = {
            datetime => $dt->clone,
            id       => lc( $dt->day_name ),
            label    => $dt->day_name
        };
        if (   $today >= $conference->start_date
            && $today <= $conference->start_date )
        {
            # during conference set active day to today
            $data->{class} = "active" if $dt == $today;
        }
        elsif ( $dt == $conference->start_date ) {

            # otherwise first day is active
            $data->{class} = "active";
        }
        push @days, $data;
        $dt->add( days => 1 );
    }

    $tokens->{days} = \@days;

    # base Event and Talk searches
    my $events = rset('Event')->search(
        {
            conferences_id => setting('conferences_id'),
            start_time     => { '!=' => undef },
        },
        {
            order_by => 'start_time',
        }
    );

    my $talks = rset('Talk')->search(
        {
            accepted       => 1,
            conferences_id => setting('conferences_id'),
            start_time     => { '!=' => undef },
        },
        {
            order_by => 'start_time',
            prefetch => 'author',
        }
    );

    if ( !user_has_role('admin') ) {

        # non-Admins can only see things that are 'scheduled'
        $events = $events->search( { scheduled => 1 } );
        $talks = $talks->search( { scheduled => 1 } );
    }

    my @events = $events->all;
    my @talks  = $talks->all;

    my @tabs;

    # process talks/evenst one day at a time
  DAY: foreach my $day (@days) {
        my $tab = { id => $day->{id}, date => $day->{datetime} };

        # find all talks and events for this day and group them
        # together in array @all
        my $next_day = $day->{datetime}->clone->add( days => 1 );
        my @talks = grep {
                 $_->start_time >= $day->{datetime}
              && $_->start_time < $next_day
        } @talks;
        my @events = grep {
                 $_->start_time >= $day->{datetime}
              && $_->start_time < $next_day
        } @events;

        my @all =
          sort { $a->start_time cmp $b->start_time } ( @talks, @events );

        # unique room names
        my %rooms = map { $_->room => 1 } @all;
        if ( $rooms{''} ) {
            $rooms{"room not defined"} = delete $rooms{''};
        }
        my @rooms = sort keys %rooms;
        $tab->{rooms} = [ map { { name => $_ } } @rooms ];

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

                    my $room_match = $room eq 'room not defined' ? '' : $room;

                    my @found =
                      grep { $_->start_time == $dt && $_->room eq $room_match }
                      @all;

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
                                class => $col % 2 ? 'bg-info' : 'bg-danger',
                                title => $e->title,
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

            $tab->{rows} = \@rows;
        }

        push @tabs, $tab;
    }

    $tokens->{tabs} = \@tabs;

    template 'schedule', $tokens;
};

=head2 get /talks/submit

CFP

=cut

get '/talks/submit' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    template 'cfp', $tokens;
};

=head2 get /talks/tag/:tag

Tag cloud links in /talks

=cut

get '/talks/tag/:tag' => sub {
    var tag => param('tag');
    forward '/talks';
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
        template '404', $tokens;
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
