#!perl
sub {
    my $schema = shift;
    $schema->resultset('Conference')
      ->find( { name => 'Perl Dancer Conference 2015' } )
      ->update( { start_date => '2015-10-19' } );
};
