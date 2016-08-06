package PerlDance::Schema::Upgrades::Sponsors;

use Moo;
use Types::Standard qw/InstanceOf/;

use DateTime;

has schema => (
    is => 'ro',
    isa => InstanceOf['PerlDance::Schema'],
    required => 1,
);

has sponsor_levels => (
    is => 'ro',
    default => sub {
        return [
            {
                name => 'Diamond Sponsor',
                uri => 'sponsors/diamond',
                priority => 50,
            },
            {
                name => 'Gold Sponsor',
                uri => 'sponsors/gold',
                priority => 40,
                sponsors => [
                    {
                        title => 'iVouch',
                        uri => 'http://www.ivouch.com/',
                        media => {
                            file => 'img/ivouch-logo.png',
                            mime_type => 'image/png',
                        },
                    }
                ],
            },
            {
                name => 'Silver Sponsor',
                uri => 'sponsors/silver',
                priority => 30,
            },
            {
                name => 'Bronze Sponsor',
                uri => 'sponsors/bronze',
                priority => 20,
                sponsors => [
                    {
                        title => 'Geekuni',
                        summary => 'Need your team to tune to the Dancer beat? Enrole them at Geekuni!',
                        uri => 'https://geekuni.com/',
                        media => {
                            file => 'img/geekuni-logo.png',
                            mime_type => 'image/png',
                        },
                    },
                    {
                        title => 'M & D',
                        uri => 'https://www.m-and-d.com/',
                        media => {
                            file => 'img/mandd-logo.png',
                            mime_type => 'image/png',
                        },
                    },
                ],
            },
        ];
    }
);

sub upgrade {
    my $self = shift;
    my $schema = $self->schema;

    # create message type for sponsors
    my $message_type = $schema->resultset('MessageType')->create({
        name => 'sponsors',
    });

    # add navigation entries for the different sponsor types
    my $sponsor_nav = $schema->resultset('Navigation')->find({uri => 'sponsors'});

    for my $level (@{$self->sponsor_levels}) {
        my $nav = $schema->resultset('Navigation')->create({
            parent_id => $sponsor_nav->id,
            name => $level->{name},
            uri => $level->{uri},
            priority => $level->{priority},
        });

        my $sponsors = $level->{sponsors} || [];

        for my $sponsor_msg (@{ $level->{sponsors} || []}) {
            $sponsor_msg->{message_types_id} = $message_type->id;
            $sponsor_msg->{content} ||= '';
            my $media_info = delete $sponsor_msg->{media};
            my $msg = $schema->resultset('Message')->create($sponsor_msg);
            $msg->create_related('navigation_messages', {navigation_id => $nav->id});

            if ($media_info) {
                # create media entry
                my $media_type =
                    $schema->resultset('MediaType')->find( { type => 'image' } );

                $msg->add_to_media({
                    %$media_info, media_type => { type => 'image' }
                });
            }
        }
    }
}

sub clear {
    my $self = shift;
    my $schema = $self->schema;

 
    # delete all descendants of sponsors navigation entry
    $schema->resultset('Navigation')->find({uri => 'sponsors'})->children->delete;

   # delete message type for sponsors
    if (my $msg_type = $schema->resultset('MessageType')->find({name => 'sponsors'})) {
        my $msg_rs = $msg_type->messages;
        while (my $msg = $msg_rs->next) {
            $msg->media_messages->delete;
        }
        
    #    $msg_type->messages->delete;
        
        $msg_type->delete;
    }

    
}

1;

