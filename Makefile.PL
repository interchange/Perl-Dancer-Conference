use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on them.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME         => 'PerlDance',
    AUTHOR       => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM => 'lib/PerlDance.pm',
    ABSTRACT     => 'YOUR APPLICATION ABSTRACT',
    (
        $eumm_version >= 6.3001
        ? ( 'LICENSE' => 'perl' )
        : ()
    ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                       => 0,
        'YAML'                             => 0,
        'Class::Method::Modifiers'         => '2.11',
        'Dancer'                           => '1.3136',
        'Dancer::Plugin::Auth::Extensible' => '0.40',
        'Dancer::Plugin::DBIC'             => '0.2102',
        'Dancer::Plugin::Email'            => '1.0400',
        'Dancer::Plugin::Interchange6'     => '0.086',
        'Dancer::Template::TemplateFlute'  => '0.0142',
        'Data::Transpose'                  => '0.0015',
        'DateTime::Format::ISO8601'        => 0,
        'DBIx::Class::DeploymentHandler'   => 0,
        'HTML::FormatText::WithLinks'      => 0,
        'HTML::Scrubber'                   => 0,
        'HTML::TagCloud'                   => '0.38',
        'Imager'                           => 0,
        'Interchange6'                     => '0.080',
        'Interchange6::Schema'             => '0.085',
        'Number::Format'                   => 0,
        'Plack::Middleware::XSRFBlock'     => 0,
        'Template::Flute'                  => '0.0184',
        'Text::Markdown'                   => 0,
        'URI::Escape'                      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'PerlDance-*' },
);
