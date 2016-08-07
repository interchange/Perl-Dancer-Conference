#!perl

# add extra fields for existing conferences
sub {
    my $schema = shift;

    $schema->resultset('Conference')->find({
        name => 'Perl Dancer Conference 2015'
    })->update({
        uri => 'https://www.perl.dance/2015/',
        logo => 'img/perl-dancer-2015-logo.png',
        email => '2015@perl.dance',
    });

    $schema->resultset('Conference')->find({
        name => 'Perl Dancer Conference 2016'
    })->update({
        uri => 'https://www.perl.dance/',
        logo => 'img/perl-dancer-2016-logo.png',
        email => '2016@perl.dance',
    });
};

