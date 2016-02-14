use strict;
use warnings;

use Test::More tests => 10;
use lib 't/lib';
use Test::App::BlockSync::Server;
use File::Temp qw(tempfile);
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw ( encode_base64 decode_base64);
use JSON;

use Data::Dumper;

=head1 115_update-file

    Test ability to update last file block with a shorter block

=cut

my $json;
my $fh = File::Temp->new();

my $test_obj =
  Test::App::BlockSync::Server->new( { file_opts => { compressed => 0 } } );
ok( $test_obj, "Got test object" );

my $test_app = $test_obj->populated_app();
ok( $test_app, "Got test app" );

my $test_file      = $test_obj->test_file();
my $test_file_part = $test_obj->test_file();
my $short_block    = $test_file->{file_blocks}[-1];
my $data_length    = length $short_block->{data};

$short_block->{data} =
  substr( $short_block->{data}, 0, length( $short_block->{data} ) / 2 );
$short_block->{data}   = decode_base64( $short_block->{data} );
$short_block->{crcsum} = md5_hex( $short_block->{data} );
$short_block->{data}   = encode_base64( $short_block->{data} );

#write to temp file
foreach my $block ( @{ $test_file->{file_blocks} } ) {

    $block->{data} = decode_base64( $block->{data} );

    if ( $test_file->{compressed} ) {
        $block->{data} = uncompress( $block->{data} );
    }

    $fh->write( $block->{data} );
}

#warn Dumper $short_block;
my $md5 = Digest::MD5->new();

$fh->seek( 0, 0 );
$md5->addfile($fh);
$md5 = $md5->hexdigest();

cmp_ok($test_file->{crcsum}, 'ne',  $md5, "md5 sum should not be the same");

$test_file->{crcsum}    = $md5;
$test_file->{file_size} = -s $fh->filename();

$test_file_part                = { %{$test_file} };
$short_block->{data}           = encode_base64( $short_block->{data} );
$test_file_part->{file_blocks} = [$short_block];

#post the change
$json = $test_obj->post_request(
    '/block',
    Content_Type => 'application/json',
    Content      => to_json($test_file_part)
);

ok( $json->{success} && !$json->{error}, "Update block should be success" );

ok( $test_obj->get_request("/block-map/$test_file->{ufn}")->{dirty},
    "File should be dirty" );

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

cmp_ok(
    $json->{file_blocks}[-1]->{crcsum},
    'eq',
    $short_block->{crcsum},
    "Sums of last block should match"
);
cmp_ok(
    $json->{file_size}, '==',
    $test_file->{file_size},
    "File sizes should match"
);

$json = $test_obj->get_request("/delete/$test_file->{ufn}");
ok( !$json->{error}, "Delete should not error" );

