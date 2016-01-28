package App::BlockSync::Server;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);

our $VERSION = '0.1';
use Data::Dumper;

set plugins => {
    DBIC => {
        default => {
            schema_class => "App::BlockSync::Server::Schema",
            dsn          => "dbi:Pg:dbname=$ENV{BS_DB}",
            user         => $ENV{BS_USER},
            password     => $ENV{BS_PASS},
        },
    }
};

set engines => {
    serializer => {
        JSON => {
            convert_blessed => '1'
        }
    }
};

set environment => "production";
set public_dir  => "";
set views       => "";
set template    => "Tiny";
set layout      => "";
set layout_dir  => "";
set show_errors => "";
set serializer  => 'JSON';

get '/' => sub {
    my @files = rset('File')->all();
    return { error => 1, files => [ @files ] };
};

get '/block-map/:ufn' => sub {
    my $ufn = params->{ufn};
    my $rs =
      rset('File')->search( { ufn => $ufn }, { prefetch => 'file_block' }, )
      ->next();

    return $rs;

};

get '/block/:ufn/:id' => sub {
    my $ufn      = params->{ufn};
    my $block_id = params->{id};

    my $rs =
      rset('FileBlock')->search( { file => $ufn, id => $block_id } )->next();

    return $rs;
};

post '/new' => sub {
    my $json = request->data;
    warn Dumper $json;
    my $rs;
    eval { rset('File')->create($json); };
    if ($@) {
        warn $@;
        return { success => 0, error => ( split( /\n/, $@ ) )[ 0 ] };
    } else {
        return { success => 1, error => 0 };
    }

};

post '/block' => sub {
    my $json = request->data;
    warn Dumper $json;

};

1;
