#!perl
sub {
    my $schema = shift;
    $schema->resultset('MessageType')
      ->create( { name => "news_item", active => 1 } );
};
