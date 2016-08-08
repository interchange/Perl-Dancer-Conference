package PerlDance::StructuredData;

use strict;
use warnings;

use JSON::MaybeXS;
use Imager;

=head1 NAME

PerlDance::Structured::Data - Generate structured data.

=cut

use Moo;

has context => (
    is => 'ro',
    default => 'http://schema.org',
);

=head1 ATTRIBUTES

=head2 uri

Link to news article.

=cut

has uri => (
    is => 'ro',
    required => 1,
);

has type => (
    is => 'ro',
    default => 'NewsArticle',
);

has headline => (
    is => 'ro',
    required => 1,
);

has image_uri => (
    is => 'ro',
    required => 1,
);

has image_path => (
    is => 'ro',
    required => 1,
);

has date_published => (
    is => 'ro',
    required => 1,
);

has date_modified => (
    is => 'ro',
);

has author => (
    is => 'ro',
    required => 1,
);

has publisher => (
    is => 'ro',
    required => 1,
);

has logo_uri => (
    is => 'ro',
    required => 1,
);

has logo_path => (
    is => 'ro',
    required => 1,
);

sub out {
    my $self = shift;
    my $data_href = {};

    # add context
    $data_href->{'@context'} = $self->context;

    # add type
    $data_href->{'@type'} = $self->type;

    # add main entity of page
    $data_href->{'mainEntityOfPage'} = {
        '@type' => 'WebPage',
        '@id' => $self->uri,
    },

    # add headline
    $data_href->{'headline'} = $self->headline;

    # add image
    $data_href->{'image'} = {
        '@type' => 'ImageObject',
        url => $self->image_uri,
        %{$self->image_dimensions($self->image_path)},
    };

    # add published date
    $data_href->{'datePublished'} = '' . $self->date_published;

    # add modified date
    if ($self->date_modified) {
        $data_href->{'dateModified'} = '' . $self->date_modified;
    }

    # add author
    $data_href->{'author'} = {
        '@type' => 'Person',
        name => $self->author,
    };

    # add publisher
    $data_href->{'publisher'} = {
        '@type' => 'Organization',
        name => $self->publisher,
        logo => {
            '@type' => 'ImageObject',
            url => $self->logo_uri,
            %{$self->image_dimensions($self->logo_path)},
        },
    };

    return encode_json($data_href);
}

sub image_dimensions {
    my ($self, $image_path) = @_;

    my $imager = Imager->new( file => $image_path)
        or die "File: $image_path, " . Imager->errstr();

    my %results;

    $results{width} = $imager->getwidth;
    $results{height} = $imager->getheight;

    return \%results;
}

1;
