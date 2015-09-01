package PerlDance::Routes::Admin::Events;

=head1 NAME

PerlDance::Routes::Admin::Events - /admin/events routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DataTransposeValidator;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use Try::Tiny;

=head1 ROUTES 

=head2 PREFIX

All routes in the class are prefixed with C</admin/events>.

=cut

prefix '/admin/events';

=head2 get ''

=cut

get '' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Event Admin";

    $tokens->{events} = rset('Event')->search(
        {
            conferences_id => setting('conferences_id'),
        },
        {
            order_by => 'start_time',
        }
    );

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

    template 'admin/events', $tokens;
};

=head2 get /create

=cut

get '/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create Event";

    my $form = form('update-create-event');
    $form->reset;
    $form->fill(
        {
            scheduled => 0,
        }
    );
    $tokens->{form} = $form;

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/events/create_update', $tokens;
};

=head2 post /create

=cut

post '/create' => require_role admin => sub {
    my $tokens = {};

    my $form = form('update-create-event');
    my $data = validator( $form->values, "update-create-event" );

    if ($data->{valid}) {
        $form->reset;
        rset('Event')->create(
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
        return redirect '/admin/events';
    }

    # validation failed
    
    $tokens->{title} = "Create Event";
    $tokens->{data}  = $data;
    $tokens->{form}  = $form;

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/events/create_update', $tokens;
};

=head2 get /delete/:id

=cut

get '/delete/:id' => require_role admin => sub {
    try {
        rset('Event')->find( param('id') )->delete;
    };
    redirect '/admin/events';
};

=head2 get /edit/:id

=cut

get '/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $event = rset('Event')->find( param('id') );

    if ( !$event ) {
        $tokens->{title} = "Event Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form   = form('update-create-event');
    $form->reset;

    $form->fill(
        {
            duration   => $event->duration,
            title      => $event->title,
            abstract   => $event->abstract,
            url        => $event->url,
            scheduled  => $event->scheduled,
            start_time => $event->start_time,
            room       => $event->room
        }
    );
    $tokens->{form}    = $form;
    $tokens->{title}   = "Edit Event";

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/events/create_update', $tokens;
};

=head2 post /edit/:id

=cut

post '/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $event = rset('Event')->find( param('id') );

    if ( !$event ) {
        $tokens->{title} = "Event Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('update-create-event');
    my $data = validator( $form->values, "update-create-event" );

    if ( $data->{valid} ) {
        $form->reset;
        $event->update(
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
        return redirect '/admin/events';
    }

    # validation failed

    $tokens->{title} = "Edit Event";
    $tokens->{data}  = $data;
    $tokens->{form}  = $form;

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/events/create_update', $tokens;
};

prefix undef;
true;
