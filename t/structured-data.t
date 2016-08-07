use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Warnings;

use PerlDance::Schema;
use PerlDance::StructuredData;

my $schema = PerlDance::Schema->connect('PerlDance');

# test structured data for talks
my $talks_rs = $schema->resultset('Talk')->search( { accepted => 1 } );

while (my $talk = $talks_rs->next) {
    my $sdh = $talk->structured_data_hash( { public_dir => 'public'} );
    my $ld = PerlDance::StructuredData->new(%$sdh);

    isa_ok($ld, 'PerlDance::StructuredData');

    my $json = $ld->out;
    ok(length($json), 'Check length of JSON data for talk ' . $talk->talks_id);
}

# test structured data for news
my $news_rs = $schema->resultset('Message')->search(
    {
        'message_type.name' => 'news_item',
        'me.public'         => 1,
    },
    {
        join => 'message_type',
    }
);

done_testing;
