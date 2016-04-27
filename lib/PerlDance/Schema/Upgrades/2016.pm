package PerlDance::Schema::Upgrades::2016;

use Moo;
use Types::Standard qw/InstanceOf/;

use DateTime;

has schema => (
    is => 'ro',
    isa => InstanceOf['PerlDance::Schema'],
    required => 1,
);

sub upgrade {
    my $self = shift;
    my $schema = $self->schema;

    # create new conference
    my $conf = $schema->resultset('Conference')->create(
        {name => 'Perl Dancer Conference 2016',
         start_date => DateTime->new(
             year => 2016,
             month => 9,
             day => 21,
         ),
         end_date => DateTime->new(
             year => 2016,
             month => 9,
             day => 22,
         ),
     },
    );

    # register organizators, gurus, speakers ...
    my %attendees = (
        'xsawyerx@cpan.org' => 1,
        'racke@linuxia.de' => 1,
        'peter@sysnix.com' => 1,
        'mickey75@gmail.com' => 1,
        'sbatschelet@mac.com' => 1,
    );

    while ((my ($email, $data)) = each %attendees) {
        print "Registering $email\n";

        if (my $user = $schema->resultset('User')->find({
            email => $email,
        })) {
            $user->find_or_create_related(
                'conferences_attended',
                { conferences_id => $conf->id,
                  confirmed => 1,
              }
            );
        }
        else {
            die "No such user $email.";
        }
    }
}

sub clear {
    my $self = shift;
    my $schema = $self->schema;

    my $conf = $schema->resultset('Conference')->find(
        {name => 'Perl Dancer Conference 2016'},
    );

    if ($conf) {
        $conf->delete;
    }
}

1;

