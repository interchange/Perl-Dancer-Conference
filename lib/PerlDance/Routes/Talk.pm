package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Data::Transpose::Validator;
use HTML::FormatText::WithLinks;
use HTML::TagCloud;
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

    my $talks_accepted = $talks->search( { accepted => 1, confirmed => 1 } );
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

    my $conditions = {};

    if (! user_has_role('admin')) {
        $conditions = {
            'me.accepted'  => 1,
            'me.confirmed' => 1,
        },
    }

    $talks = $talks->search(
        $conditions,
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
        $talks = $talks->search(
            {
                'attendee_talks.users_id' =>  [ undef, $user->id ],
            },
            {
                prefetch => 'attendee_talks',
            }
        );
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
    my $json = { result => "fail" };

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
            accepted => 1,
            confirmed => 1,
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

    PerlDance::Routes::add_navigation_tokens($tokens);

    my $talks = rset('Talk')->search(
        {
            accepted       => 1,
            confirmed      => 1,
            conferences_id => setting('conferences_id'),
            start_time     => { '!=' => undef },
        },
        {
            order_by => 'start_time',
            prefetch => 'author',
        }
    );
    my %days;
    while ( my $talk = $talks->next ) {
        my $day_zero = 18;
        my $day_number = 0;
        $day_number = $talk->start_time->day - $day_zero;
        push @{ $days{$day_number} }, $talk;
    };
    foreach my $day ( sort keys %days ) {
        my $value = $days{$day};
        my $date  = $value->[0]->start_time;
        push @{ $tokens->{talks} },
          {
            day   => "Day $day",
            date  => $date,
            talks => $value,
          };
    }

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
            confirmed      => 1,
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
        $tokens->{picked} = rset('AttendeeTalk')
          ->find( { users_id => $user->id, talks_id => $talks_id } );
    }

    template 'talk', $tokens;
};

true;
