package PerlDance::Routes::Admin::Surveys;

=head1 NAME

PerlDance::Routes::Admin::Survey - /admin/surveys

=cut

use Dancer2 appname => 'PerlDance';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DataTransposeValidator;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::TemplateFlute;
use Try::Tiny;

=head1 ROUTES 

=head2 PREFIX

All routes in the class are prefixed with C</admin/surveys>.

=cut

prefix '/admin/surveys';

=head2 get ''

=cut

get '' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Survey Admin";

    $tokens->{surveys} = rset('Survey')->search(
        {
            conferences_id => setting('conferences_id'),
        },
        {
            order_by => 'title',
            prefetch => 'author',
        }
    );

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

    template 'admin/surveys', $tokens;
};

=head2 get /create

=cut

get '/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create Survey";

    my $form = form('create-update-survey');
    $form->reset;
    $form->fill(
        {
            scheduled => 0,
        }
    );
    $tokens->{form} = $form;

    template 'admin/surveys/create_update', $tokens;
};

=head2 post /create

=cut

post '/create' => require_role admin => sub {
    my $tokens = {};

    my $form = form('create-update-survey');
    my $data = validator( $form->values, "create-update-survey" );

    if ($data->{valid}) {
        $form->reset;
        rset('Survey')->create(
            {
                conferences_id => setting('conferences_id'),
                duration       => $data->{values}->{duration},
                title          => $data->{values}->{title},
                abstract       => $data->{values}->{abstract},
                url            => $data->{values}->{url} || '',
                scheduled      => $data->{values}->{scheduled} ? 1 : 0,
                start_time     => $data->{values}->{start_time} || undef,
                room           => $data->{values}->{room} || '',
            }
        );
        return redirect '/admin/surveys';
    }

    # validation failed
    
    $tokens->{title} = "Create Survey";
    $tokens->{data}  = $data;
    $tokens->{form}  = $form;

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/surveys/create_update', $tokens;
};

=head2 get /delete/:id

=cut

get '/delete/:id' => require_role admin => sub {
    try {
        rset('Survey')->find( param('id') )->delete;
    };
    redirect '/admin/surveys';
};

=head2 get /edit/:id

=cut

get '/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $survey = rset('Survey')->find( param('id') );

    if ( !$survey ) {
        $tokens->{title} = "Survey Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form   = form('create-update-survey');
    $form->reset;

    $form->fill(
        {
            duration   => $survey->duration,
            title      => $survey->title,
            abstract   => $survey->abstract,
            url        => $survey->url,
            scheduled  => $survey->scheduled,
            start_time => $survey->start_time,
            room       => $survey->room
        }
    );
    $tokens->{form}    = $form;
    $tokens->{title}   = "Edit Survey";

    template 'admin/surveys/create_update', $tokens;
};

=head2 post /edit/:id

=cut

post '/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $survey = rset('Survey')->find( param('id') );

    if ( !$survey ) {
        $tokens->{title} = "Survey Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('create-update-survey');
    my $data = validator( $form->values, "create-update-survey" );

    if ( $data->{valid} ) {
        $form->reset;
        $survey->update(
            {
                conferences_id => setting('conferences_id'),
                duration       => $data->{values}->{duration},
                title          => $data->{values}->{title},
                abstract       => $data->{values}->{abstract},
                url            => $data->{values}->{url} || '',
                scheduled      => $data->{values}->{scheduled} ? 1 : 0,
                start_time     => $data->{values}->{start_time} || undef,
                room           => $data->{values}->{room} || '',
            }
        );
        return redirect '/admin/surveys';
    }

    # validation failed

    $tokens->{title} = "Edit Survey";
    $tokens->{data}  = $data;
    $tokens->{form}  = $form;

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/surveys/create_update', $tokens;
};

prefix undef;
true;
