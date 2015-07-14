package PerlDance::Filter::Markdown;

=head1 NAME

PerlDance::Filter::Markdown - markdown filter

=head1 DESCRIPTION

Turns text in Markdown format into HTML. The HTML
is subject to scrubbing with L<HTML::Scrubber>.

=cut

use strict;
use warnings;

use base 'Template::Flute::Filter';
use HTML::Scrubber;
use Text::Markdown;

sub init {
    my ( $self, %args ) = @_;
    $self->{unsafe} = $args{options}->{unsafe};
}

sub filter {
    my ( $self, $value ) = @_;

    my $m = Text::Markdown->new;
    return $m->markdown($value) if $self->{unsafe};

    my $s = HTML::Scrubber->new( allow => [qw/p b i u hr br ul ol li/] );
    return $s->scrub( $m->markdown($value) );
}

1;
