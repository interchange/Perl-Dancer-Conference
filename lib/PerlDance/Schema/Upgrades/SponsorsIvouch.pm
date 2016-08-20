package PerlDance::Schema::Upgrades::SponsorsIvouch;

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
            },
            {
                name => 'Special Sponsor',
                uri => 'sponsors/special',
                priority => 10,
                sponsors => [
                    {
                        title => 'Jovial',
                        summary => '[Jovial Org](http://www.jovial.org)',
                        uri => 'Jovial.org ',
                        media => {
                            file => 'img/jovial-dark.png',
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
    my $message_type = $schema->resultset('MessageType')->search({
        name => 'sponsors',
    })->single;

    # add navigation entries for the different sponsor types
    my $sponsor_nav = $schema->resultset('Navigation')->find({uri => 'sponsors'});

    for my $level (@{$self->sponsor_levels}) {
        my $nav = $schema->resultset('Navigation')->find_or_create({
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
            next if $schema->resultset('Message')->find({title => $sponsor_msg->{title}});
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

    # add teaser to iVouch sponsor
    $schema->resultset('Message')->search( { title => 'iVouch' } )->update(
        { summary => '[iVouch.com](http://www.ivouch.com/)' }
    );
}

sub clear {
    my $self = shift;
    my $schema = $self->schema;

}

1;

