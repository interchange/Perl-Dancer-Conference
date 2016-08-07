#!perl

sub {
    my $schema = shift;

    # set dates for last year's conference
    $schema->resultset('Conference')
      ->find( { name => 'Perl Dancer Conference 2015' } )
      ->talks
      ->update( { created => '2015-10-19',
                  last_modified => '2015-10-19',
              } );

    # set dates for this year's conference
    $schema->resultset('Conference')
      ->find( { name => 'Perl Dancer Conference 2016' } )
      ->talks
      ->update( { created => '2016-08-07',
                  last_modified => '2016-08-07',
              } );

};

