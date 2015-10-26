package PerlDance::Routes::Survey;

=head1 NAME

PerlDance::Routes::Survey

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;

=head1 ROUTES

=head2 get /survey

=cut

get '/survey' => require_login sub {
    my $tokens = {};

    $tokens->{title} = "Conference Survey";

    $tokens->{survey} = [
        {
            section => 'Demographics',
            text =>
              'These questions will help us understand who our attendees are.',
            questions => [
                {
                    title   => 'Age Band:',
                    options => [
                        'under 20',
                        '20 - 29',
                        '30 - 39',
                        '40 - 49',
                        '50 - 59',
                        '60 and over'
                    ],
                },
                {
                    title => 'Job Type:',
                    text =>
q{If your position covers many roles, please base this on your most senior responsibility. Also base this on the role you perform, rather than your job title. For example, a 'QA Developer' would be a 'Developer' role, and 'Information Manager' would a Manager role (Technical or Non-Technical depending upon your responsibilites)},
                    options => [
                        'CEO/Company Director/Senior Manager',
                        'Non-Technical Manager',
                        'Technical Manager',
                        'Technical Architect/Analyst',
                        'Developer',
                        'Engineer',
                        'SysAdmin',
                        'Student',
                        'Lecturer/Teacher/Trainer',
                        'Human Resources',
                        'Researcher',
                        'Unemployed',
                        'Other',
                    ],
                    other => 'please enter your professional job role or title',
                },
                {
                    title => 'Industry:',
                    text =>
'If you or your company undertake work within mulitple industry sectors, please select the primary one you are currently working within.',
                    options => [
                        'Automotive',         'Education',
                        'Engineering',        'Finance',
                        'Government',         'IT Services',
                        'Internet/Web',       'Legal',
                        'Logistics',          'Media/Entertainment',
                        'Medical/Healthcare', 'Property',
                        'Research',           'Retail',
                        'Telecommunications', 'Travel',
                        'Unemployed',         'Other',
                    ],
                    other => 'please enter your industry sector',
                },
                {
                    title => 'Region:',
                    text =>
'Please note this is the region you were a resident in, prior to attending the conference.',
                    options => [

                    ],
                },
            ],
        },
        {
            section =>
              'The Perl and Dancer Communities, Conferences and Workshops',
            text =>
'These questions are designed to help us understand our attendees level of involvement in the Perl, Dancer and DBIC communities.',
            questions => [
                {
                    title   => 'How do you rate your Perl knowledge?',
                    options => [qw/Beginner Intermediate Advanced/],
                },
                {
                    title   => 'How do you rate your Dancer knowledge?',
                    options => [qw/Beginner Intermediate Advanced/],
                },
                {
                    title   => 'How do you rate your DBIx::Class knowledge?',
                    options => [qw/Beginner Intermediate Advanced/],
                },
                {
                    title   => 'How long have you been programming in Perl?',
                    options => [
                        'less than a year',
                        '1-2 years',
                        '3-5 years',
                        '5-10 years',
                        'more than 10 years'
                    ],
                },
                {
                    title   => 'How long have you been using Dancer?',
                    options => [
                        'less than a year',
                        '1-2 years',
                        '3-5 years',
                        '5-10 years',
                        'more than 10 years'
                    ],
                },
                {
                    title   => 'How long have you been using DBIx::Class?',
                    options => [
                        'less than a year',
                        '1-2 years',
                        '3-5 years',
                        '5-10 years',
                        'more than 10 years'
                    ],
                },
                {
                    title   => 'Did you attend Perl Dancer Conference 2014?',
                    options => [qw/Yes No/],
                },
                {
                    title =>
'How many previous Perl-related conferences have you attended?',
                    text =>
'Please include technical conferences which included a Perl track and any Perl Workshops.',
                    options => [ '0', '1', '2 - 5', '6 - 10', '10 or more' ],
                },
                {
                    title =>
                      'Do you plan to attend a future Perl Dancer conference?',
                    options => [ 'Yes', 'Maybe', "Don't Know", 'No' ],
                },
                {
                    title =>
'What other areas of the Perl Community do you contribute to?',
                    type    => 'checkbox',
                    options => [
                        "I'm a CPAN Author",
                        "I'm a CPAN Tester",
"I'm a Perl event organiser (e.g. YAPC, Perl Workshop, QA Hackathon, local technical meetings, etc.)",
"I'm a board or committee member of a recognised Perl body (e.g. TPF, EPO, YEF, JPF, etc.)",
"I'm a Perl project developer (e.g. Dancer, Catalyst, Mojo, DBIx::Class, etc.)",
"I have a technical blog (e.g. on blogs.perl.org or a personal blog)",
"I use or contribute to PerlMonks, Stackoverflow or other discussion forums",
                        "I use IRC (e.g. #dancer, #yapc, #drinkers.pm, etc.)",
"I contribute to Perl mailing lists (e.g. Dancer, P5P, Perl QA, etc)",
                        "other ...",
                    ],
                    other => 'please enter your area of contribution',
                },
            ],
        },
        {
            section   => '',
            text      => '',
            questions => [
                {
                    title   => '',
                    text    => '',
                    options => [],
                    other   => '',
                },
            ],
        },
    ];

    template 'survey', $tokens;
};

true;
