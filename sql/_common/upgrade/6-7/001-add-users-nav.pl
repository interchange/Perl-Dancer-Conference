#!perl
sub {
    use DateTime;
    my $schema = shift;
    my $rset   = $schema->resultset('Navigation');

    my $top = $rset->create(
        {
            type        => 'nav',
            scope       => 'menu-main',
            name        => 'Users',
            description => 'Users',
            priority    => 25,
        }
    );

    $rset->create(
        {
            uri         => 'users',
            type        => 'nav',
            name        => 'Search',
            description => 'User Search',
            priority    => 80,
            parent_id   => $top->id,
        }
    );

    $rset->create(
        {
            uri         => 'users/statistics',
            type        => 'nav',
            name        => 'Statistics',
            description => 'User Statistics',
            priority    => 60,
            parent_id   => $top->id,
        }
    );
};
