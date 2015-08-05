package PerlDance::Filter::MongerGroups;

=head1 NAME

PerlDance::Filter::Boolean - bool filter

=head1 DESCRIPTION

Turns true/false values into Yes/No.

=cut

use strict;
use warnings;

use base 'Template::Flute::Filter';

my %lookup = (
    'drinkers.pm' => undef,
    'Hannover.pm' => 'Hannover.pm',
);

sub filter {
    my ( $self, $value ) = @_;
    $value =~ s/,/ /g;
    $value =~ s/(^\s+|\s+$)//g;
    my @groups = split( /\s+/, $value );
    foreach my $i ( 0 .. $#groups ) {
        if ( exists $lookup{ $groups[$i] } ) {
            if ( defined $lookup{ $groups[$i] } ) {
                $groups[$i] =
                  qq{<a href="http://$lookup{ $groups[$i] }/">$groups[$i]</a>};
            }
        }
        else {
            $groups[$i] = qq{<a href="http://$groups[$i].org/">$groups[$i]</a>};
        }
    }
    return join( ", ", @groups );
}

1;
