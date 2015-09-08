package PerlDance::Filter::MongerGroups;

=head1 NAME

PerlDance::Filter::MongerGroups

=head1 DESCRIPTION

Translate Perl Monger group names into html link snippets

=cut

use strict;
use warnings;

use base 'Template::Flute::Filter';

# pm groups NOT in %lookup get translated to Group.pm.org
# undef value means no website
my %lookup = (
    'Bicycle.pm'   => 'Bicycle.pm',
    'drinkers.pm'  => undef,
    'Ljubljana.pm' => 'www.meetup.com/Ljubljana-pm-Perl-Mongers',
    'Hannover.pm'  => 'Hannover.pm',
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
                  qq{<a href="http://$lookup{ $groups[$i] }/" target="_blank">$groups[$i]</a>};
            }
        }
        else {
            $groups[$i] = qq{<a href="http://$groups[$i].org/" target="_blank">$groups[$i]</a>};
        }
    }
    return join( ", ", @groups );
}

1;
