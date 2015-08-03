#!perl

sub {
    my $schema = shift;
    my $rset   = $schema->resultset('Navigation');

    my $parent = $rset->find(
        {
            uri => 'users',
        }
      )->update(
        {
            uri => 'users/search',
        }
      )->parent;

    $parent->children->update( { active => 0 } );

    $parent->attach_child(
        $rset->create(
            {
                uri         => 'users',
                type        => 'nav',
                name        => 'Map',
                description => 'User Map',
                priority    => 100,
            }
        )
    );
};
