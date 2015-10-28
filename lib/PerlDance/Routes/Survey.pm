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

#get '/surveys' => require_login sub {
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

    my $survey = rset('Survey')->find(
        {
            'me.conferences_id' => setting('conferences_id'),
            'me.survey_id'      => $id,
            -bool               => 'me.public',
        },
    );

    if ( !$survey ) {

        # not the survey you were looking for
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{title} = $survey->title;

    my $surveys_rs = rset('Survey')->search(
        { 'me.survey_id' => $id },
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

    $tokens->{survey} = $surveys_rs->next;

    template '/survey', $tokens;
};

true;
