package PerlDance::Filter::Markdown;

=head1 NAME

DanceShop::Filters::SellingPrice - filter for possibly undef selling_price

=head1 DESCRIPTION

The filter inherits from L<Template::Flute::Filter::Currency> and but instead
of throwing an exception when the price is undefined it instead returns undef.

=cut

use strict;
use warnings;

use base 'Template::Flute::Filter';
use HTML::Scrubber;
use Text::Markdown;

sub filter {
    my ($self, $value) = @_;
    my $m = Text::Markdown->new;
    my $s = HTML::Scrubber->new(allow => [qw/p b i u hr br ul ol li/]);
    return $s->scrub($m->markdown($value));
}

1;
