package PerlDance::Filter::Wiki;

=head1 NAME

PerlDance::Filter::Wiki - wiki markdown filter

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
}

sub filter {
    my ( $self, $value ) = @_;

    $value =~ s{\[wiki:(.+?)\]}{[$1](/wiki/node/$1)}g;
    $value =~ s{\[user:(.+?)\]}{[$1](/users/$1)}g;

    my $m = Text::Markdown->new;
    my $s = HTML::Scrubber->new( allow => [qw/a p b i img u hr br ul ol li/] );
    $s->rules(
        a => {
            href => 1,
            '*' => 0,
        },
        img => {
            src => 1,
            alt => 1,
            '*' => 0,
        },
    );
    return $s->scrub( $m->markdown($value) );
}

1;
