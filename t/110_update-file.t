use strict;
use warnings;

use Test::More tests => 9;
use lib 't/lib';
use HTTP::Request::Common;
use Test::App::BlockSync::Server;
use JSON;

=head1 110_update-file

    Test ability to update a file block

=cut

my $res;
my $res2;
my $json;
my $json2;

my $test_obj = Test::App::BlockSync::Server->new();
ok( $test_obj, "Got test object" );

my $test_app = $test_obj->populated_app();
ok( $test_app, "Got test app" );

my $test_file      = $test_obj->test_file();
my $test_file_part = $test_file;

#move block up one to simulate change
$test_file_part->{file_blocks} = [ $test_file->{file_blocks}[4] ];

$test_file_part->{file_blocks}[0]->{id} = 5;

$res = $test_app->request(
    POST '/block',
    Content_Type => 'application/json',
    Content      => to_json($test_file_part)
);

$json = from_json( $res->content );

ok( $json->{success} && !$json->{error}, "Update block should be success" );

$res  = $test_app->request( GET "/block/$test_file->{ufn}/4" );
$res2 = $test_app->request( GET "/block/$test_file->{ufn}/5" );

$json  = from_json( $res->content );
$json2 = from_json( $res2->content );

cmp_ok( $json->{id},  '==', 4, "Should be block 4" );
cmp_ok( $json2->{id}, '==', 5, "Should be block 4" );

cmp_ok( $json->{crcsum}, 'eq', $json2->{crcsum},
    "Blocks should now have same sum" );

$res  = $test_app->request( GET "/block-map/$test_file->{ufn}" );
$json = from_json( $res->content );

ok( $json->{dirty}, "File should be dirty" );

delete $test_file_part->{file_blocks};
$res = $test_app->request(
    POST '/file',
    Content_Type => 'application/json',
    Content      => to_json($test_file_part)
);

$json = from_json( $res->content );

ok(
    $json->{success} && !$json->{error},
    "File meta data update should be success"
);

$res  = $test_app->request( GET "/block-map/$test_file->{ufn}" );
$json = from_json( $res->content );

ok( !$json->{dirty}, "File shouldn't be dirty" );

