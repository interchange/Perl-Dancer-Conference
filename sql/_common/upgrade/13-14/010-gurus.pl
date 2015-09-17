#!perl
sub {
    my $schema = shift;
    $schema->resultset('User')->search(
        {
            username => {
                -in => [
                    'xsawyerx@cpan.org',
                    'russell.jenkins@strategicdata.com.au',
                    'rabbit@rabbit.us',
                ]
            }
        }
    )->update( { guru_level => 100 } );
};
