package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Interchange6;
use HTML::TagCloud;
use Try::Tiny;

=head1 ROUTES

=head2 get /talks

Talks list by speaker

=cut

get '/talks' => sub {
    my $tokens = {};

    my $nav = shop_navigation->find( { uri => 'talks' } );
    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;

    my $talks = shop_schema->resultset('Talk')->search(
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
        $cloud->add( $tag, "/talks/tag/$tag", $tags{$tag} );
    }
    $tokens->{cloud} = $cloud->html;

    $tokens->{talks} = $talks->search(
        {
            'me.accepted' => 1,
        },
        {
            order_by => [ 'author.first_name', 'author.last_name' ],
            prefetch => 'author',
        }
    );

    template 'talks', $tokens;
};

=head2 get /talks/schedule

Talks schedule

=cut

get '/talks/schedule' => sub {
    my $tokens = {};

    my $nav = shop_navigation->find( { uri => 'talks' } );
    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;

    my $talks = shop_schema->resultset('Talk')->search(
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

    $tokens->{title} = "Call For Papers";

    template 'cfp', $tokens;
};

=head2 get /talks/{id}.*

Individual talk

=cut

get qr{/talks/(?<id>\d+).*} => sub {
    my $talks_id = captures->{id};
    my $tokens = {};

    $tokens->{talk} = shop_schema->resultset('Talk')->find(
        {
            'me.talks_id'       => $talks_id,
            'me.conferences_id' => setting('conferences_id'),
        },
        { prefetch => [ 'author', { attendee_talks => 'user' } ], }
    );

    $tokens->{title} = $tokens->{talk}->title;

    template 'talk', $tokens;
};

true;
