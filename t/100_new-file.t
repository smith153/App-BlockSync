use strict;
use warnings;

use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);
use HTTP::Request::Common;
use Compress::Zlib qw ( compress);
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw ( encode_base64);
use IO::File;

=head1 100_new-file

    Test ability to post a new file with block map and then retrieve 

=cut

BEGIN {
    eval { require DBD::SQLite };
    plan skip_all => 'DBD::SQLite required to run these tests' if $@;

    my $dbic = {
        DBIC => {
            default => {
                schema_class => "App::BlockSync::Server::Schema",
                dsn          => "dbi:SQLite:dbname=:memory:",
            },
        }
    };

    #override config.yml
    set plugins => $dbic;
    schema->deploy;

}

######################## MAIN ###########################

use App::BlockSync::Server;

my $app = App::BlockSync::Server->to_app;
is( ref $app, 'CODE', 'Got app' );
my $test = Plack::Test->create($app);
my $fh;
my $data;
my $md5       = Digest::MD5->new();
my $test_file = {
    ufn         => '1f098e9',
    uhn         => 'e98ea',
    hostname    => 'testhost',
    path        => 't/data',
    filename    => 'test.wav',
    crcsum      => '2c79c8cae98ea3ac7dc31f098e9f2da1',
    mod_time    => 1354186306,
    block_size  => '2048',                               #2KB
    compressed  => 1,
    file_blocks => [],
};


open($fh, "<t/data/test.wav");
$md5->addfile($fh);
close($fh);

cmp_ok(
    $md5->hexdigest(), "eq",
    "2c79c8cae98ea3ac7dc31f098e9f2da1",
    "Uncompress md5sum is correct"
);

$fh = IO::File->new("< t/data/test.wav");
$fh->binmode();

my $i    = 0;
my $size = $test_file->{block_size};

while ( $fh->read( $data, $size, $size * $i ) ) {   #read ( BUF, LEN, [OFFSET] )
    my $block = {
        file   => $test_file->{ufn},
        id     => $i++,
        crcsum => md5_hex($data),
        data   => encode_base64( compress( $data, 1 ) ),
    };

    push( @{ $test_file->{file_blocks} }, $block );

}


my $res = $test->request(
    POST '/new',
    Content_Type => 'application/json',
    Content      => to_json($test_file)
);

my $json = from_json( $res->content );

warn $json->{error};
