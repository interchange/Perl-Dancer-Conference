#!perl
sub {
    use DateTime;
    my $schema = shift;
    my $rset   = $schema->resultset('Navigation');

    # create wiki
    my $wiki = $rset->create(
        {
            uri         => 'wiki',
            type        => 'nav',
            scope       => 'menu-main',
            name        => 'Wiki',
            description => 'Wiki',
            priority    => 30,
        }
    );

    # make speakers a child of top-level talks menu

    my $talks = $rset->search(
        { uri  => undef, type => 'nav', scope => 'menu-main', name => 'Talks' },
        { rows => 1 }
    )->single;

    my $speakers = $rset->find( { uri => 'speakers' } );
    $speakers->update(
        {
            scope     => '',
            parent_id => $talks->id,
            priority  => 65
        }
    );
};
