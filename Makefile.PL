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
        'Dancer::Plugin::DataTransposeValidator' => '0.003',
        'Dancer::Plugin::DBIC'             => '0.2102',
        'Dancer::Plugin::Email'            => '1.0400',
        'Dancer::Plugin::FlashNote'        => 0,
        'Dancer::Plugin::Interchange6'     => '0.086',
        'Dancer::Template::TemplateFlute'  => '0.0142',
        'DateTime::Format::ISO8601'        => 0,
        'DateTime::Format::Pg'             => 0,
        'DBIx::Class::DeploymentHandler'   => 0,
        'Email::Sender::Transport::Redirect' => 0,
        'Geo::Coder::OSM'                  => 0,
        'Geo::IP'                          => 0,
        'HTML::FormatText::WithLinks'      => 0,
        'HTML::Scrubber'                   => 0,
        'HTML::TagCloud'                   => '0.38',
        'Imager'                           => 0,
        'Interchange6'                     => '0.080',
        'Interchange6::Schema'             => '0.089',
        'Number::Format'                   => 0,
        'Plack::Middleware::XForwardedFor' => 0,
        'Plack::Middleware::XSRFBlock'     => 0,
        'Plack::Session'                   => 0,
        'Template::Flute'                  => '0.0184',
        'Text::Diff'                       => 0,
        'Text::Markdown'                   => 0,
        'Try::Tiny'                        => 0,
        'URI::Escape'                      => 0,
        # PayPal payments (with bugfix for umlauts in address)
        'Business::PayPal::API' => '0.73',
	# Live requirements
	'Starman'               => 0,
	'DBD::Pg'               => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'PerlDance-*' },
);
