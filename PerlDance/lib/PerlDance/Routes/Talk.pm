package PerlDance::Routes::Talk;

=head1 NAME

PerlDance::Routes::Talk - Talk routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Dancer::Plugin::Interchange6;
use Data::Transpose::Validator;
use HTML::FormatText::WithLinks;
use HTML::TagCloud;
use Try::Tiny;

=head1 ROUTES

=head2 get /talks

Talks list by speaker

=cut

get '/talks' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

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

    $talks = $talks->search(
        {
            'me.accepted' => 1,
        },
        {
            order_by => [ 'author.first_name', 'author.last_name' ],
            prefetch => 'author',
        }
    );

    if ( my $tag = var('tag') ) {
        my $tagged_talks = $talks->search(
            {
                "me.tags" => { like => '%' . $tag . '%' }
            }
        );
        if ( $tagged_talks->has_rows ) {
            $talks = $tagged_talks;
            $tokens->{tag} = $tag;
            $tokens->{title} .= " | " . $tag;
        }
    }

    $tokens->{talks} = $talks;

    template 'talks', $tokens;
};

=head2 get /talks/schedule

Talks schedule

=cut

get '/talks/schedule' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

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

=head2 get/post /talks/submit

CFP

=cut

any [ 'get', 'post' ] => '/talks/submit' => sub {
    my $tokens = {};

    PerlDance::Routes::add_navigation_tokens($tokens);

    if ( request->is_post && logged_in_user ) {

        my %params = params('body');

        my $validator = Data::Transpose::Validator->new(
            stripwhite => 1,
            requireall => 1,
        );

        $validator->prepare(
            talk_title => "String",
            abstract   => "String",
            tags       => "String",
            duration   => {
                validator => {
                    class   => "NumericRange",
                    options => {
                        integer => 1,
                        min     => 20,
                        max     => 40,
                    }
                }
            }
        );

        my $valid = $validator->transpose(\%params);

        if ( $valid ) {

            my $tags = $valid->{tags};
            $tags =~ s/,/ /g;
            $tags =~ s/\s+/ /g;

            try {
                my $talk = shop_schema->resultset('Talk')->create(
                    {
                        author_id      => logged_in_user->id,
                        conferences_id => setting('conferences_id'),
                        duration       => $valid->{duration},
                        title          => $valid->{talk_title},
                        tags           => $tags,
                        abstract       => $valid->{abstract},
                    }
                );

                debug "new talk submitted";

                my $html = template '/email/talk_submitted',
                  {
                    %$valid,
                    logged_in_user    => logged_in_user,
                    talk              => $talk,
                    "conference-logo" => uri_for(
                        shop_schema->resultset('Media')
                          ->search( { label => "email-logo" } )->first->uri
                    ),
                  },
                  { layout => 'email' };

                my $f = HTML::FormatText::WithLinks->new;
                my $text = $f->parse($html);

                email {
                    subject => setting("conference_name") . " talk submitted",
                    body    => $text,
                    type    => 'text',
                    attach  => {
                        Data     => $html,
                        Encoding => "quoted-printable",
                        Type     => "text/html"
                    },
                    multipart => 'alternative',
                };

                debug "sent email/talk_submitted";

                redirect '/profile';
            }
            catch {
                # FIXME: handle errors
                error "Talk submission error: $_";
            };
        }
        else {
            my %errors;
            my $v_hash = $validator->errors_hash;
            while ( my ( $key, $value ) = each %$v_hash ) {
                $errors{$key} = $value->[0]->{value};
                $errors{ $key . '_input' } = 'has-error';
            }
            $tokens->{errors} = \%errors;
            foreach my $field (qw/talk_title abstract tags duration/) {
                $tokens->{$field} = $params{$field};
            }
        }
    }
    else {
        # for login redirect
        session return_url => "/talks/submit";
    }

    $tokens->{durations} = [
        {
            value => 20, label => "20 minutes",
        },
        {
            value => 40, label => "40 minutes",
        },
    ];

    template 'cfp', $tokens;
};


=head2 get /talks/tag/:tag

Tag cloud links in /talks

=cut

get '/talks/tag/:tag' => sub {
    var tag => param('tag');
    forward '/talks';
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
