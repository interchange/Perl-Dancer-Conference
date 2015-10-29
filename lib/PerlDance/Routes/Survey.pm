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

    if ( my $user = logged_in_user ) {

        # conference attendee?
        my $result = rset('ConferenceAttendee')->find(
            {
                conferences_id => setting('conferences_id'),
                users_id       => $user->id
            }
        );
        if ( !$result ) {

            # not marked as an attendee so closed surveys only
            $surveys_rs = $surveys_rs->search( { -bool => 'me.closed' } );
        }
    }
    else {

        # not logged in so closed surveys only
        $surveys_rs = $surveys_rs->search( { -bool => 'me.closed' } );
    }

    # if we got here and have an open survey then user is both logged in
    # and a conference attendee

    if ( !$surveys_rs->count ) {

        # no survey found
        status 'not_found';
        return template '404';
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

post '/surveys' => require_login sub {
    my $params = params('body');

    my $survey = rset('Survey')->find( delete $params->{survey_id} );
    my $user   = logged_in_user;

    # conference attendee?
    my $attendee = rset('ConferenceAttendee')->find(
        {
            conferences_id => setting('conferences_id'),
            users_id       => $user->id
        }
    );

    if ( !$survey || !$attendee ) {
        status 'not_found';
        return template '404';
    }

    # TODO: make sure user has not already submitted the survey

    # clean up params
    delete $params->{xsrf_token};
    map { /^other_/ && $params->{$_} eq '' && delete $params->{$_} }
      keys %$params;

    print STDERR to_dumper($params);
    #

};

true;
