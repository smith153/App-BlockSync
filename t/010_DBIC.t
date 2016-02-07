use strict;
use warnings;

use Test::More tests => 4;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);

=head1 010_DBIC.t

    Test ability to override default database with in-memory Sqlite instance

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

use App::BlockSync::Server;

my $app = App::BlockSync::Server->to_app;
is( ref $app, 'CODE', 'Got app' );
my $test      = Plack::Test->create($app);
my $test_file = {
    ufn        => 'test',
    uhn        => 'test',
    hostname   => 'test',
    path       => 'test/path',
    filename   => 'testfile',
    crcsum     => '1234asb',
    mod_time   => 1354186306,
    block_size => '32000',
};

cmp_ok( rset('File')->count(), '==', 0, "0 rows in new deployment" );

ok rset('File')->create($test_file), "Created Test file entry";
cmp_ok( [ rset('File')->all() ]->[0]->ufn(), 'eq', 'test', "ufn is 'test'" );

