package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Interchange6;
use Try::Tiny;

=head1 ROUTES

=head2 get /talks

Talks list

=cut

get '/talks' => sub {
    my $tokens = {};

    my $nav = shop_navigation->find( { uri => 'talks' } );
    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;

    my $talks = shop_schema->resultset('Talk')->search(
        {
            accepted       => 1,
            conferences_id => setting('conferences_id'),
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
        if ( defined $talk->start_time ) {
            $day_number = $talk->start_time->day - $day_zero;
        }
        push @{ $days{$day_number} }, $talk;
    };
    my $unscheduled;
    foreach my $day ( sort keys %days ) {
        my $value = $days{$day};
        my $date = $value->[0]->start_time;
        if ( $day > 0 ) {
            push @{ $tokens->{talks} },
              {
                day   => "Day $day",
                date  => $date,
                talks => $value,
              };
        }
        else {
            $unscheduled = {
                day   => 'Not yet scheduled',
                date  => undef,
                talks => $value,
            };
        }
    }
    push @{ $tokens->{talks} }, $unscheduled if $unscheduled;

    template 'talks', $tokens;
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
