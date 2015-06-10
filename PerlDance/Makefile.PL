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
        'Dancer'                           => 1.3136,
        'Dancer::Plugin::Auth::Extensible' => '0.40',
        'Dancer::Plugin::DBIC'             => '0.2102',
        'Dancer::Plugin::Interchange6'     => '0.080',
        'Dancer::Template::TemplateFlute'  => '0.0142',
        'DateTime::Format::ISO8601'        => 0,
        'HTML::Scrubber'                   => 0,
        'Interchange6'                     => '0.080',
        'Interchange6::Schema'             => '0.084',
        'Template::Flute'                  => '0.0180',
        'Text::Markdown'                   => 0,
        'URI::Escape'                      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'PerlDance-*' },
);
