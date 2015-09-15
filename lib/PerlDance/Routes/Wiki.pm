package PerlDance::Routes::Wiki;

=head1 NAME

PerlDance::Routes::Wiki

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use DateTime;
use HTML::TagCloud;
use Text::Diff 'diff';

=head1 ROUTES

=head2 get /wiki

Forward internally to /wiki/node/HomePage

=cut

get '/wiki' => sub {
    forward '/wiki/node/HomePage';
};

=head2 get /wiki/diff/*/**

Display diff between two versions.

=cut

get '/wiki/diff/*/**' => sub {
    my $tokens = {};

    my ( $version, $splat ) = splat;

    if ( $version !~ /^\d+$/ ) {
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $title = join( '/', @$splat );

    my $rset = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.title'          => $title,
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => 'me.created',
            offset   => $version - 1,
            rows     => 2,
        }
    );

    my $first  = $rset->next;
    my $second = $rset->next;

    if ( !$first && !$second ) {
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $first  = $first->content;
    $second = $second->content;

    $tokens->{diff} = diff \$first, \$second,
      {
        FILENAME_A => "version $version",
        FILENAME_B => "version " . ( $version + 1 ),
        STYLE      => "Table"
      };

    $tokens->{title} = "Wiki - $title Diff $version -> " . ( $version + 1 );
    $tokens->{uri} = $title;

    add_wiki_toc($tokens);

    template 'wiki/diff', $tokens;
};

=head2 get /wiki/edit/**

Edit page.

=cut

get '/wiki/edit/**' => require_login sub {
    my $tokens = {};

    my ($splat) = splat;
    my $title = join( '/', @$splat );

    my $node = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.title'          => $title,
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => { -desc => 'me.created' },
            rows     => 1,
        }
    )->single;

    if ($node) {
        $tokens->{content} = $node->content;
        $tokens->{tags}    = $node->tags;
    }

    $tokens->{title} = "Wiki - editing $title";
    $tokens->{uri}   = $title;

    PerlDance::Routes::add_javascript( $tokens, '/js/wiki-edit.js' );

    template 'wiki/edit', $tokens;
};

=head2 post /wiki/edit/**

Preview or save node.

=cut

post '/wiki/edit/**' => require_login sub {
    my $tokens = {};

    my ($splat) = splat;
    my $title = join( '/', @$splat );

    my $user_id = logged_in_user->id;

    my $content = param('content');
    $content =~ s(\[user:(.+?)\])(translate_wiki_user($1))gie;
    $content =~ s(\[me\])(translate_wiki_user('me'))gie;

    if ( param('preview') ) {

        # back to the edit page with a preview shown above
        $tokens->{content} = $content;
        $tokens->{preview} = $content;
        $tokens->{tags}    = param('tags');
        $tokens->{title}   = "Wiki - editing $title";
        $tokens->{uri}     = $title;

        PerlDance::Routes::add_javascript( $tokens, '/js/wiki-edit.js' );

        return template 'wiki/edit', $tokens;
    }
    else {

        $content =~ s/\r\n/\n/g;

        my $tags = param('tags');
        $tags =~ s/(^\s+|\s+$)//g;

        rset('Message')->create(
            {
                title           => $title,
                content         => param('content'),
                type            => 'wiki_node',
                format          => 'markdown',
                author_users_id => logged_in_user->id,
                tags            => $tags,
            }
        );
        redirect "/wiki/node/$title";
    }
};

=head2 get /wiki/history/**

Page history

=cut

get '/wiki/history/**' => sub {
    my $tokens = {};

    my ($splat) = splat;
    my $title = join( '/', @$splat );

    my @nodes = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.title'          => $title,
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => 'me.created',
        }
    )->all;

    $tokens->{count}  = scalar @nodes;
    $tokens->{latest} = pop @nodes;

    my @result;
    my $i = scalar @nodes;
    foreach my $node ( reverse @nodes ) {
        push @result, { version => $i--, node => $node };
    }

    $tokens->{history} = \@result;

    $tokens->{title} = "Wiki - $title History";

    add_wiki_toc($tokens);

    template 'wiki/history', $tokens;
};

=head2 get /wiki/node/**

Display appropriate wiki node.

=cut

get '/wiki/node/**' => sub {
    my $tokens = {};

    my ($splat) = splat;
    my $title = join( '/', @$splat );

    my $nodes = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.title'          => $title,
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => { -desc => 'me.created' },
        }
    );

    $tokens->{has_history} = 1 if $nodes->count > 1;
    $tokens->{node}        = $nodes->first;
    $tokens->{title}       = "Wiki - $title";
    $tokens->{uri}         = $title;

    add_wiki_toc($tokens);

    template 'wiki', $tokens;
};

=head2 get/post /wiki/recent

Recent changes

=cut

any [ 'get', 'post' ] => '/wiki/recent' => sub {
    my $tokens = {};

    my $form = form('wiki-recent');
    my $values;

    if ( request->is_post ) {
        $values = $form->values;
    }
    else {
        $values = $form->values('session');
    }

    my $days = $values->{period};
    $days = 7 unless ( $days && $days =~ /^\d+$/ );

    $form->fill( { period => $days } );

    $tokens->{form} = $form;

    my $rset = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.created'        => {
                '>=',
                schema->format_datetime(
                    DateTime->today->subtract( days => $days )
                )
            },
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => { -desc => 'me.created' },
        }
    );

    my ( @changes, %seen );
    while ( my $message = $rset->next ) {
        next if $seen{ $message->title };
        $seen{ $message->title } = 1;
        push @changes, $message;
    }

    $tokens->{changes} = \@changes;

    $tokens->{periods} = [
        { value => 1,  label => "1 day" },
        { value => 2,  label => "2 days" },
        { value => 3,  label => "3 days" },
        { value => 7,  label => "1 week" },
        { value => 14, label => "2 weeks" },
        { value => 30, label => "1 month" },
        { value => 60, label => "2 months" },
    ];

    PerlDance::Routes::add_javascript( $tokens, '/js/wiki-recent.js' );

    $tokens->{title} = "Wiki - Recent changes";

    add_wiki_toc($tokens);

    template 'wiki/recent', $tokens;
};

=head2 get /wiki/tags

Pages by tag

=cut

get '/wiki/tags' => sub {
    my $tokens = {};

    my $rset = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
        },
        {
            join     => 'message_type',
            order_by => { -desc => 'me.created' },
        }
    );

    my ( %tags, %seen );
    while ( my $message = $rset->next ) {
        next if $seen{ $message->title };
        $seen{ $message->title } = 1;
        map { $tags{$_}++ } map { s/,/ /g; split( /\s+/, $_ ) } $message->tags;
    }

    my $cloud = HTML::TagCloud->new;
    foreach my $tag ( sort keys %tags ) {

        # add space to tag to force wrapping since TF removes the line breaks
        # added by HTML::TagCloud
        $cloud->add( "$tag ", "/wiki/tags/$tag", $tags{$tag} );
    }
    $tokens->{cloud} = $cloud->html;

    $tokens->{title} = "Wiki - Tags";

    add_wiki_toc($tokens);

    template 'wiki/tags', $tokens;
};

=head2 get /wiki/tags/:tag

List of pages with this tag

=cut

get '/wiki/tags/:tag' => sub {
    my $tokens = {};

    my $tag = param 'tag';

    my $rset = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.tags'           => { like => '%' . $tag . '%' }
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => { -desc => 'me.created' },
        }
    );

    my ( @nodes, %seen );
    while ( my $message = $rset->next ) {
        next if $seen{ $message->title };
        $seen{ $message->title } = 1;
        push @nodes, $message;
    }

    $tokens->{nodes} = \@nodes;
    $tokens->{title} = "Wiki - Pages tagged $tag";

    add_wiki_toc($tokens);

    template 'wiki/tagged_pages', $tokens;
};

=head2 get /wiki/version/*/**

Display specific version of page

=cut

get '/wiki/version/*/**' => sub {
    my $tokens = {};

    my ( $version, $splat ) = splat;

    if ( $version !~ /^\d+$/ ) {
        $tokens->{title} = "Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $title = join( '/', @$splat );

    my $node = rset('Message')->search(
        {
            'message_type.name' => 'wiki_node',
            'me.title'          => $title,
        },
        {
            join     => 'message_type',
            prefetch => 'author',
            order_by => 'me.created',
            offset   => $version - 1,
            rows     => 1,
        }
    )->single;

    $tokens->{node}    = $node;
    $tokens->{title}   = "Wiki - $title Version $version";
    $tokens->{uri}     = $title;
    $tokens->{version} = $version;

    add_wiki_toc($tokens);

    template 'wiki/version', $tokens;
};

sub add_wiki_toc {
    my $tokens = shift;
    $tokens->{toc} = [
        rset('Message')->search(
            {
                'message_type.name' => 'wiki_node',
                'me.title'          => { '!=' => 'HomePage' },
            },
            {
                join     => 'message_type',
                order_by => 'me.title',
                columns  => 'title',
                distinct => 1,
            }
        )->hri->all
    ];
}

sub translate_wiki_user {
    my $arg = shift;
    my $user;
    if ( $arg eq 'me' ) {
        $user = logged_in_user;
    }
    else {
        if ( $arg =~ /.+\@.+/ ) {

            # smells like email so try username
            $user = rset('User')->find( { username => lc($arg) } );
        }
        if ( !$user && $arg =~ /^(\d+)/ ) {

            # could be users_id
            $user = rset('User')->find($1);
        }
        if ( !$user ) {

            # try nickname

            $user =
              rset('User')
              ->search( \[ 'LOWER(nickname) = ?', lc($arg) ], { rows => 1 } )
              ->first;
        }
    }
    return "[user:$arg]" unless $user;

    my $name = $user->name;
    $name .= " (" . $user->nickname . ")" if $user->nickname;
    return "[$name](/users/" . $user->uri . ")";
}

true;
