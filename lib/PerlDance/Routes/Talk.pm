package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Dancer::Plugin::Interchange6;
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

    my $talks = shop_schema->resultset('Talk')->search(
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

    print STDERR $cloud->css;

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

    $tokens->{talks} = $talks;

    template 'talks', $tokens;
};

=head2 get /talks/schedule

Talks schedule

=cut

get '/talks/schedule' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    my $talks = shop_schema->resultset('Talk')->search(
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
    my $tokens = {};

    my $talk = shop_schema->resultset('Talk')->find(
        {
            talks_id       => $talks_id,
            accepted       => 1,
            confirmed      => 1,
            conferences_id => setting('conferences_id'),
        },
        { prefetch => [ 'author', { attendee_talks => 'user' } ], }
    );

    if ($talk) {
        $tokens->{talk}  = $talk;
        $tokens->{title} = $talk->title;
        template 'talk', $tokens;
    }
    else {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        template '404', $tokens;
    }
};

true;
