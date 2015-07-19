#!perl
sub {
    my $schema = shift;
    $schema->resultset('ConferenceTicket')->populate(
        [
            [ 'conferences_id',  'sku', ],
            [ '1', '2015PERLDANCE2DAYS', ],
            [ '1', '2015PERLDANCE4DAYS', ],
        ]
    );
};
