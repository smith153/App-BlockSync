use strict;
use warnings;

use Test::More tests => 11;
use lib 't/lib';
use Test::App::BlockSync::Server;
use File::Temp qw(tempfile);
use Digest::MD5 qw(md5_hex);
use Compress::Zlib qw(uncompress);
use MIME::Base64 qw ( encode_base64 decode_base64);
use JSON;

use Data::Dumper;

=head1 110_update-file

    Test ability to update a single file block

=cut

my $json;
my $fh = File::Temp->new();

my $test_obj = Test::App::BlockSync::Server->new();
ok( $test_obj, "Got test object" );

my $test_app = $test_obj->populated_app();
ok( $test_app, "Got test app" );

my $test_file      = $test_obj->test_file();
my $test_file_part = $test_obj->test_file();

#move block 4 up one to simulate change
$test_file_part->{file_blocks} = [ $test_file_part->{file_blocks}[4] ];

$test_file_part->{file_blocks}[0]->{id} = 5;

#post the change
$json = $test_obj->post_request(
    '/block',
    Content_Type => 'application/json',
    Content      => to_json($test_file_part)
);

ok( $json->{success} && !$json->{error}, "Update block should be success" );

cmp_ok( $test_obj->get_request("/block/$test_file->{ufn}/4")->{id},
    '==', 4, "Should be block id 4" );

cmp_ok( $test_obj->get_request("/block/$test_file->{ufn}/5")->{id},
    '==', 5, "Should be block id 5" );

cmp_ok(
    $test_obj->get_request("/block/$test_file->{ufn}/4")->{crcsum},
    'eq',
    $test_obj->get_request("/block/$test_file->{ufn}/5")->{crcsum},
    "Blocks 4 and 5 should now have same sum"
);

ok( $test_obj->get_request("/block-map/$test_file->{ufn}")->{dirty},
    "File should be dirty" );

#make sure sum mismatch will fail
$test_file_part->{file_blocks}[0]->{crcsum} = 'badsum';

#post the change
$json = $test_obj->post_request(
    '/block',
    Content_Type => 'application/json',
    Content      => to_json($test_file_part)
);

ok( !$json->{success} && $json->{error}, "Update block should not be success" );

#change data on original structure so was can get correct md5sum
$test_file->{file_blocks}[5] = { %{ $test_file->{file_blocks}[4] } };
$test_file->{file_blocks}[5]->{id} = 5;

#write to temp file
foreach my $block ( @{ $test_file->{file_blocks} } ) {

    $block->{data} = decode_base64( $block->{data} );

    if ( $test_file->{compressed} ) {
        $block->{data} = uncompress( $block->{data} );
    }

    $fh->write( $block->{data} );
}

my $md5 = Digest::MD5->new();

$fh->seek( 0, 0 );
$md5->addfile($fh);

$test_file->{crcsum} = $md5->hexdigest();

#post file meta data only
delete $test_file->{file_blocks};

$json = $test_obj->post_request(
    '/file',
    Content_Type => 'application/json',
    Content      => to_json($test_file)
);

ok(
    $json->{success} && !$json->{error},
    "File meta data update should be success"
);

$json = $test_obj->get_request("/block-map/$test_file->{ufn}");

ok( !$json->{dirty}, "File shouldn't be dirty" );

$json = $test_obj->get_request("/delete/$test_file->{ufn}");
ok( !$json->{error}, "Delete should not error" );

