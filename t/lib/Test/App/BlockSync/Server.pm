use strict;
use warnings;

package Test::App::BlockSync::Server;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);
use Compress::Zlib qw ( compress);
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw ( encode_base64);
use IO::File;

BEGIN {
    eval { require DBD::SQLite };
    die 'DBD::SQLite required to run these tests' if $@;

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

use App::BlockSync::Server;

our $test_file = {
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

sub new
{
    my ( $class, $args ) = @_;
    my $ref = { test_file => $test_file, };
    return bless $ref, $class;
}

sub test_file
{
    my $self = shift();
    return $self->{test_file};
}

sub blank_app
{
    my $self = shift();
    my $app = App::BlockSync::Server->to_app || die "Couldn't get app!";
    return Plack::Test->create($app);
}

sub populated_app
{
    my $self = shift();
    my $app  = App::BlockSync::Server->to_app || die "Couldn't get app!";
    my $test = Plack::Test->create($app);
    my $fh;
    my $test_file = $self->test_file();
    my $path      = "$test_file->{path}/$test_file->{filename}";
    my $data;
    my $res;
    my $json;
    my $md5 = Digest::MD5->new();
    open( $fh, "<$path" );
    $md5->addfile($fh);
    close($fh);

    die "md5 mismatch" unless $md5->hexdigest() eq $test_file->{crcsum};

    $fh = IO::File->new("< $path");
    $fh->binmode();

    my $i    = 0;
    my $size = $test_file->{block_size};

    while ( $fh->read( $data, $size, $size * $i ) )
    {    #read ( BUF, LEN, [OFFSET] )
        my $block = {
            file   => $test_file->{ufn},
            id     => $i++,
            crcsum => md5_hex($data),
            data   => encode_base64( compress( $data, 1 ) ),
        };

        push( @{ $test_file->{file_blocks} }, $block );

    }

    $res = $test->request(
        POST '/new',
        Content_Type => 'application/json',
        Content      => to_json($test_file)
    );

    $json = from_json( $res->content );
    die "Couldn't post file $json->{error} " if ( $json->{error} );
    return $test;
}

