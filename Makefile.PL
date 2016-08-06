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
        'YAML::XS'                         => 0,
        'Type::Tiny'                       => '0.038',
        'Class::Method::Modifiers'         => '2.11',
        'Dancer2'                          => '0.166001_01',
        'Dancer2::Plugin::Auth::Extensible' => '0.600',
        'Dancer2::Plugin::Auth::Extensible::Provider::DBIC' => '0.600',
        'Dancer2::Plugin::DataTransposeValidator' => '0.009',
        'Dancer2::Plugin::DBIC'             => '0.0013',
        'Dancer2::Plugin::Deferred'         => '0.007016',
        'Dancer2::Plugin::Email'            => '0.0004',
        'Dancer2::Plugin::Interchange6'     => '0.203',
        'Dancer2::Plugin::TemplateFlute'    => '0.202',
        'Dancer2::Session::DBIC'            => '0.102',
        'Dancer2::Template::TemplateFlute'  => '0.200',
        'DateTime::Format::ISO8601'        => 0,
        'DateTime::Format::Pg'             => 0,
        'DBIx::Class::DeploymentHandler'   => 0,
        'DBIx::Class::DeploymentHandler::CLI'  => 0,
        'Email::Sender::Transport::Redirect' => 0,
        'Geo::Coder::OSM'                  => 0,
        'Geo::IP'                          => 0,
        'HTML::FormatText::WithLinks'      => 0,
        'HTML::Scrubber'                   => 0,
        'HTML::TagCloud'                   => '0.38',
        'Imager'                           => 0,
        'Interchange6'                     => '0.110',
        'Interchange6::Schema'             => '0.130',
        'Number::Format'                   => 0,
        'Plack::Middleware::XForwardedFor' => 0,
        'Plack::Middleware::XSRFBlock'     => 0,
        'Plack::Session'                   => 0,
        'Template::Flute'                  => '0.020',
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
