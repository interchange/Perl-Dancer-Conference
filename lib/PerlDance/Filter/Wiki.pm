package PerlDance::Filter::Wiki;
use PerlDance::Filter::Markdown;

=head1 NAME

PerlDance::Filter::Wiki - wiki markdown filter

=head1 DESCRIPTION

Add support for [wiki:PageName] and [user:NickName] to standard Markdown
filter.

=cut

use strict;
use warnings;

use base 'Template::Flute::Filter';
use HTML::Scrubber;
use Text::Markdown;
use URI::Escape;

sub filter {
    my ( $self, $value ) = @_;

    $value =~
      s{\[wiki:(.+?)\]}{"[$1](/wiki/node/" . uri_escape_utf8($1) . ")"}eg;

    my $markdown_filter = PerlDance::Filter::Markdown->new;
    return $markdown_filter->filter($value);
}

1;
