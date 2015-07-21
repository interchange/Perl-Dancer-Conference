#!perl
sub {
    my $schema = shift;
    my $media_type_image =
      $schema->resultset('MediaType')->find( { type => 'image' } );
    $schema->resultset('Media')->create(
        {
            file           => "img/people/unknown.jpg",
            uri            => "/img/people/unknown.jpg",
            mime_type      => 'image/jpg',
            media_types_id => $media_type_image->id,
            label          => 'unknown user',
        }
    );
};
