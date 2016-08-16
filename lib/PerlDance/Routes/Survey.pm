package PerlDance::Routes::Survey;

=head1 NAME

PerlDance::Routes::Survey

=cut

use Dancer2 appname => 'PerlDance';
use Carp;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::TemplateFlute;
use Try::Tiny;

=head1 ROUTES

=head2 get /surveys

=cut

get qr {^/surveys/?$} => require_login sub {

    my $surveys_rs = rset('UserSurvey')->search(
        {
            'survey.conferences_id' => setting('conferences_id'),
            -bool                   => 'survey.public',
            -not_bool               => 'me.completed',
            'me.users_id'           => schema->current_user->id,
        },
        {
            join => 'survey',
        }
    )->related_resultset('survey')->order_by('!survey.priority,survey.title');

    my $tokens = {
        title        => "Conference Surveys",
        survey_count => $surveys_rs->count,
        surveys      => $surveys_rs,
    };

    template '/surveys', $tokens;
};

post '/surveys' => require_login sub {
    my $params = body_parameters->as_hashref;

    my $survey_id = delete $params->{survey_id};
    my $user      = schema->current_user;

    my $survey = rset('Survey')->search(
        {
            'me.conferences_id'     => setting('conferences_id'),
            'me.survey_id'          => $survey_id,
            -bool                   => 'me.public',
            'user_surveys.users_id' => $user->id,
            -not_bool               => 'user_surveys.completed',
        },
        {
            join     => 'user_surveys',
            prefetch => { sections => 'questions' },
            rows     => 1,
        }
    )->next;

    send_error( "Survey not found.", 404 ) if !$survey;

    # clean up params
    delete $params->{xsrf_token};

    # collect all question ids
    my @questions;
    my $sections = $survey->sections;
    while ( my $section = $sections->next ) {
        push @questions,
          $section->questions->get_column('survey_question_id')->all;
    }

    try {
        schema->txn_do(
            sub {

                # this user has completed this survey
                my $user_survey = rset('UserSurvey')->find(
                    {
                        users_id  => $user->id,
                        survey_id => $survey->id,
                    }
                );
                $user_survey->update( { completed => 1 } );

                foreach my $param ( keys %$params ) {
                    next unless $param =~ /^(q|other)_(\d+)/;

                    my $question = $2;

                    if ( !grep { $_ == $question } @questions ) {
                        croak "Question $question not valid";
                    }

                    my $response = rset('SurveyResponse')->find_or_create(
                        {
                            user_survey_id     => $user_survey->id,
                            survey_question_id => $question,
                        }
                    );

                    if ( $param =~ /^q_\d+$/ ) {

                        # radio or checkbox

                        my @options = ( $params->{$param} );
                        if ( ref( $params->{$param} ) eq 'ARRAY' ) {

                            # checkbox
                            @options = @{ $params->{$param} };
                        }
                        foreach my $option (@options) {
                            rset('SurveyResponseOption')->create(
                                {
                                    survey_response_id        => $response->id,
                                    survey_question_option_id => $option,
                                }
                            );
                        }
                    }
                    elsif ( $param =~ /^q_\d+_o_(\d+)$/ ) {

                        # grid

                        my $option = $1;

                        rset('SurveyResponseOption')->create(
                            {
                                survey_response_id        => $response->id,
                                survey_question_option_id => $option,
                                value                     => $params->{$param},
                            }
                        );

                    }
                    elsif ( $param =~ /^other_\d+$/ ) {
                        if ( $params->{$param} =~ /\S/ ) {

                            # 'other' with some content
                            $response->update( { other => $params->{$param} } );
                        }
                    }
                    else {
                        warning "Unexpected param: $param";
                    }
                }
            }
        );

        deferred success => "Thankyou for submitting the survey: "
          . $survey->title;
    }
    catch {
        # deal with problem
        error "$_";
        deferred error =>
          "Something went horribly wrong. Please accept our apologies.";
    };

    redirect '/surveys';
};

get '/surveys/:id' => require_login sub {
    my $tokens = {};
    my $id     = route_parameters->get('id');

    if ( $id !~ /^\d+$/ ) {

        # no survey found
        status 'not_found';
        return template '404';
    }

    $tokens->{survey} = rset('Survey')->search(
        {
            'me.conferences_id'     => setting('conferences_id'),
            'me.survey_id'          => $id,
            -bool                   => 'me.public',
            'user_surveys.users_id' => schema->current_user->id,
            -not_bool               => 'user_surveys.completed',
        },
        {
            join     => 'user_surveys',
            prefetch => { sections => { questions => "options" } },
            order_by => {
                -desc => [
                    'sections.priority', 'questions.priority',
                    'options.priority'
                ]
            },
            rows => 1,
        }
    )->hri->next;

    if ( !$tokens->{survey} ) {

        # no survey found
        status 'not_found';
        return template '404';
    }

    $tokens->{title} = $tokens->{survey}->{title};

    PerlDance::Routes::add_javascript( $tokens, "/js/survey-questions.js" );
    template '/surveys/questions', $tokens;
};

get qr {^/survey-results/?$} => sub {
    my $tokens = {};

    my $surveys_rs = rset('Survey');
    $surveys_rs = $surveys_rs->search(
        {
            'me.conferences_id' => setting('conferences_id'),
            -bool               => 'me.public',
        },
        {
            join       => [ 'talk', 'user_surveys' ],
            distinct   => 1,
            '+columns' => {
                completed_count => $surveys_rs->correlate('user_surveys')
                  ->search( { completed => 1 } )->count_rs->as_query
            },
        }
    )->order_by('!me.priority,me.title');

    if ( my $user = logged_in_user ) {
        if ( user_has_role('admin') ) {

            # admins can see all survey results whether closed or not
            $tokens->{is_admin} = 1;
        }
        else {
            # non-admins can see closed surveys that are either:
            # - not a talk review
            # - is a review of user's own talk
            # AND where there are completed responses
            $surveys_rs = $surveys_rs->search(
                {
                    'user_surveys.completed' => 1,
                    -bool                    => 'me.closed',
                    -or                      => [
                        { 'talk.talks_id'  => undef },
                        { 'talk.author_id' => $user->id },
                    ],
                }
            );
        }
    }
    else {

        # anonymous users can only see closed surveys that are NOT talk
        # reviews
        $surveys_rs = $surveys_rs->search(
            {
                -bool           => 'me.closed',
                'talk.talks_id' => undef,
            }
        );
    }

    $tokens->{title} = "Conference Surveys";

    $tokens->{survey_count} = $surveys_rs->count;

    $tokens->{surveys} = [ $surveys_rs->hri->all ];

    template '/surveys/results', $tokens;
};

get '/survey-results/:id' => sub {
    my $tokens = {};
    my $id     = route_parameters->get('id');

    if ( $id !~ /^\d+$/ ) {

        # no survey found
        status 'not_found';
        return template '404';
    }

    my $survey = rset('Survey')->search(
        {
            'me.conferences_id' => setting('conferences_id'),
            'me.survey_id'      => $id,
            -bool               => 'me.public',
        },
        {
            prefetch => [
                'user_surveys',
                {
                    sections => {
                        questions =>
                          [ 'responses', { options => 'response_options' } ]
                    },
                },
            ],
            order_by => {
                -desc => [
                    'sections.priority', 'questions.priority',
                    'options.priority'
                ]
            },
            rows => 1,
        }
    )->hri->next;

    $tokens->{no_responses} = 1 if !$survey;

    foreach my $section ( @{ $survey->{sections} } ) {
        foreach my $question ( @{ $section->{questions} } ) {

            if ( @{ $question->{options} } ) {

                # not just 'other' so display options table
                $question->{options_table} = 1;
            }

            # see if we have 'other' responses
            my @other;
            foreach my $response ( @{ $question->{responses} } ) {
                push @other, { response => $response->{other} }
                  if $response->{other} =~ /\S/;
            }
            delete $question->{responses};
            $question->{others} = \@other if scalar @other;

            foreach my $option ( @{ $question->{options} } ) {
                my $selected = delete $option->{response_options};
                if ( $question->{type} =~ /^(checkbox|radio)$/ ) {
                    $question->{is_simple} = 1;
                    $option->{count1}      = scalar @$selected;
                    $option->{is_simple}   = 1;
                }
                elsif ( $question->{type} eq 'grid' ) {
                    foreach my $i ( 1 .. 5 ) {
                        $option->{"show_count$i"} = 1;
                    }
                    $question->{is_grid} = 1;
                    foreach my $row (@$selected) {
                        my $i = $row->{value};
                        $option->{"count$i"}++;
                        $option->{is_grid} = 1;
                    }
                }
            }
        }
    }

    my $responded =
      scalar grep { $_->{completed} == 1 } @{ $survey->{user_surveys} };
    my $no_response =
      scalar grep { $_->{completed} == 0 } @{ $survey->{user_surveys} };
    my $total             = $responded + $no_response;
    my $percent_responded = $total ? int( $responded / $total * 100 + 0.5 ) : 0;

    unshift @{ $survey->{sections} }, {
        title => 'Responses',
        description => '',
        questions => [
            {
                title => 'Survey responses received:',
                description => '',
                is_simple => 1,
                options_table => 1,
                options => [
                    {
                        is_simple => 1,
                        title => 'Responded',
                        count1 => $responded,
                    },
                    {
                        is_simple => 1,
                        title => 'No response',
                        count1 => $no_response,
                    },
                    {
                        is_simple => 1,
                        title => 'Total',
                        count1 => $total,
                    },
                    {
                        is_simple => 1,
                        title => 'Response percentage',
                        count1 => $percent_responded,
                    },
                ],
            },
        ],
    };

    $tokens->{survey} = $survey;
    $tokens->{title}  = $tokens->{survey}->{title};

    template '/surveys/result', $tokens;
};

true;
