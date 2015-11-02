package PerlDance::Routes::Survey;

=head1 NAME

PerlDance::Routes::Survey

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashNote;
use Dancer::Plugin::Form;
use Try::Tiny;

=head1 ROUTES

=head2 get /surveys

=cut

get '/surveys' => require_login sub {

    my $surveys_rs = rset('UserSurvey')->search(
        {
            'survey.conferences_id' => setting('conferences_id'),
            -bool                   => 'survey.public',
            -not_bool               => 'me.completed',
            'me.users_id'           => logged_in_user->id,
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
    my $params = params('body');

    my $survey_id = delete $params->{survey_id};
    my $user      = logged_in_user;

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

    if ( !$survey ) {
        status 'not_found';
        return template '404';
    }

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
                    if ( $param =~ /^q_(\d+)$/ ) {

                        # radio or checkbox

                        my $question = $1;

                        if ( !grep { $_ == $question } @questions ) {
                            die "Question $question not valid";
                        }

                        my @options = ( $params->{$param} );
                        if ( ref( $params->{$param} ) eq 'ARRAY' ) {

                            # checkbox
                            @options = @{ $params->{$param} };
                        }
                        foreach my $option (@options) {
                            rset('SurveyResponse')->create(
                                {
                                    user_survey_id => $user_survey->id,
                                    survey_question_option_id => $option,
                                }
                            );
                        }
                    }
                    elsif ( $param =~ /^q_(\d+)_o_(\d+)$/ ) {

                        # grid

                        my ( $question, $option ) = ( $1, $2 );

                        if ( !grep { $_ == $question } @questions ) {
                            die "Question $question not valid";
                        }

                        rset('SurveyResponse')->create(
                            {
                                user_survey_id            => $user_survey->id,
                                survey_question_option_id => $option,
                                value                     => $params->{$param},
                            }
                        );

                    }
                    elsif ( $param =~ /^other_(\d+)$/ ) {

                        # 'other' TODO: put this in Message?
                        my $question = $1;
                    }
                    else {
                        warning "Unexpected param: $param";
                    }
                }
            }
        );

        flash success => "Thankyou for submitting the survey: "
          . $survey->title;
    }
    catch {
        # deal with problem
        error "$_";
        flash error =>
          "Something went horribly wrong. Please accept our apologies.";
    };

    redirect '/surveys';
};

get '/surveys/:id' => require_login sub {
    my $tokens = {};

    $tokens->{survey} = rset('Survey')->search(
        {
            'me.conferences_id'     => setting('conferences_id'),
            'me.survey_id'          => param('id'),
            -bool                   => 'me.public',
            'user_surveys.users_id' => logged_in_user->id,
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

get '/survey-results' => sub {
    my $tokens = {};

    my $surveys_rs = rset('Survey')->search(
        {
            'me.conferences_id' => setting('conferences_id'),
            -bool               => 'me.public',
        },
        {
            join => 'talk',
        }
    )->order_by('!me.priority,me.title');

    if ( my $user = logged_in_user ) {
        if ( user_has_role('admin') ) {

            # admins can see all survey results
            $tokens->{is_admin} = 1;
        }
        else {
            # non-admins can see closed surveys that are either:
            # - not a talk review
            # - is a review of user's own talk
            $surveys_rs = $surveys_rs->search(
                {
                    -bool => 'me.closed',
                    -or   => [
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

    $tokens->{surveys} = $surveys_rs;

    template '/surveys/results', $tokens;
};

get '/survey-results/:id' => sub {
    my $tokens = {};

    my $survey = rset('Survey')->search(
        {
            'me.conferences_id' => setting('conferences_id'),
            'me.survey_id'      => param('id'),
            -bool               => 'me.public',
            -bool               => 'user_surveys.completed',
        },
        {
            join     => 'user_surveys',
            prefetch => {
                sections => { questions => { options => 'selected_options' } }
            },
            order_by => {
                -desc => [
                    'sections.priority', 'questions.priority',
                    'options.priority'
                ]
            },
            rows => 1,
        }
    )->hri->next;

    foreach my $section ( @{ $survey->{sections} } ) {
        foreach my $question ( @{ $section->{questions} } ) {
            if ( @{ $question->{options} } ) {
                $question->{options_table} = 1;
            }
            foreach my $option ( @{ $question->{options} } ) {
                my $selected = delete $option->{selected_options};
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

    $tokens->{survey} = $survey;
    $tokens->{title}  = $tokens->{survey}->{title};
    print STDERR to_dumper($survey);

    template '/surveys/result', $tokens;
};

true;
