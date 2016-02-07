use strict;
use warnings;

use Test::More tests => 6;
use lib 't/lib';
use HTTP::Request::Common;
use Test::App::BlockSync::Server;
use JSON;

=head1 100_new-file

    Test ability to post a new file with block map and then retrieve 

=cut

my $res;
my $json;
my $test_obj = Test::App::BlockSync::Server->new();
ok( $test_obj, "Got test object" );

my $test_app = $test_obj->populated_app();
ok( $test_app, "Got test app" );

my $test_file = $test_obj->test_file();

$res  = $test_app->request( GET "/block-map/$test_file->{ufn}" );
$json = from_json( $res->content );
cmp_ok(
    $json->{file_blocks}[2]{crcsum},
    'eq',
    $test_file->{file_blocks}[2]{crcsum},
    "Block should have same sum"
);

$res  = $test_app->request( GET "/block/$test_file->{ufn}/2" );
$json = from_json( $res->content );
cmp_ok(
    $json->{crcsum}, 'eq',
    $test_file->{file_blocks}[2]{crcsum},
    "Block should have same sum"
);

$res  = $test_app->request( GET "/delete/$test_file->{ufn}" );
$json = from_json( $res->content );
ok( !$json->{error}, "Delete should not error" );

$res  = $test_app->request( GET "/delete/fake-ufn" );
$json = from_json( $res->content );
ok( $json->{error}, "Delete should error" );

