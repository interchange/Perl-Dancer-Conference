#!perl

sub {
    my $schema = shift;
    my $rset   = $schema->resultset('Navigation');

    my $parent = $rset->create(
        {
            uri         => 'admin',
            name        => 'Admin',
            type        => 'nav',
            scope       => 'menu-admin',
            description => 'Administration',
        }
    );

    $parent->attach_child(
        $rset->create(
            {
                name        => 'Navigation',
                uri         => 'admin/navigation',
                type        => 'nav',
                description => 'Navigation Administration',
            }
        ),
        $rset->create(
            {
                name        => 'News',
                uri         => 'admin/news',
                type        => 'nav',
                description => 'News Administration',
            }
        ),
        $rset->create(
            {
                name        => 'Talks',
                uri         => 'admin/talks',
                type        => 'nav',
                description => 'Talks Administration',
            }
        ),
        $rset->create(
            {
                name        => 'Users',
                uri         => 'admin/users',
                type        => 'nav',
                description => 'User Administration',
            }
        ),
    );
};
