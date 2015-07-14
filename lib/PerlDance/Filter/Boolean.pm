package PerlDance::Filter::Boolean;

=head1 NAME

PerlDance::Filter::Boolean - bool filter

=head1 DESCRIPTION

Turns true/false values into Yes/No.

=cut

use strict;
use warnings;

use base 'Template::Flute::Filter';

sub filter {
    my ($self, $value) = @_;
    $value ? 'Yes' : 'No';
}

1;
