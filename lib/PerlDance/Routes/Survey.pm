package PerlDance::Routes::Survey;

=head1 NAME

PerlDance::Routes::Survey

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;

=head1 ROUTES

=head2 get /surveys

=cut

get '/surveys' => sub {
    my $tokens = {};

    $tokens->{title} = "Conference Surveys";

    my $surveys_rs = rset('Survey')->search(
        {
            'me.conferences_id' => setting('conferences_id'),
            -bool               => 'me.public',
        },
    );

    if ( !logged_in_user ) {

        # closed surveys only (see results)
        $surveys_rs = $surveys_rs->search( { -bool => 'me.closed' } );
    }

    $tokens->{survey_count} = $surveys_rs->count;

    $tokens->{surveys} = $surveys_rs;

    template '/surveys', $tokens;
};

get qr{/surveys/(?<id>\d+).*} => sub {
    my $id     = captures->{id};
    my $tokens = {};

    my $surveys_rs = rset('Survey')->search(
        {
            'me.conferences_id' => setting('conferences_id'),
            'me.survey_id'      => $id,
            -bool               => 'me.public',
        },
        {
            prefetch => { sections => { questions => "options" } },
            rows     => 1,
            order_by => {
                -desc => [
                    'sections.priority', 'questions.priority',
                    'options.priority'
                ]
            },
        }
    );

    my $attendee = 0;

    if ( my $user = logged_in_user ) {

        # conference attendee?
        my $result = rset('ConferenceAttendee')->find(
            {
                conferences_id => setting('conferences_id'),
                users_id       => $user->id
            }
        );
        if ($result) {
            $attendee = 1;
        }
        else {

            # not marked as an attendee so closed surveys only
            $surveys_rs = $surveys_rs->search( { -bool => 'me.closed' } );
        }
    }
    else {

        # not logged in so closed surveys only
        $surveys_rs = $surveys_rs->search( { -bool => 'me.closed' } );
    }

    if ( !$surveys_rs->count ) {

        # no survey found
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{survey} = $surveys_rs->hri->next;

    $tokens->{title} = $tokens->{survey}->{title};

    if ( $tokens->{survey}->{closed} ) {

        template '/surveys/results', $tokens;
    }
    else {
        PerlDance::Routes::add_javascript( $tokens, "/js/survey-questions.js" );
        template '/surveys/questions', $tokens;
    }
};

true;
