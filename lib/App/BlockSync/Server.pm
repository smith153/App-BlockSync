package App::BlockSync::Server;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);

our $VERSION = '0.1';
use Data::Dumper;

set environment => "production";
set public_dir  => "";
set views       => "";
set template    => "Tiny";
set layout      => "";
set layout_dir  => "";
set show_errors => "";
set serializer  => 'JSON';

set plugins => {
    DBIC => {
        default => {
            schema_class => "App::BlockSync::Schema",
            dsn          => "dbi:Pg:dbname=$ENV{BS_DB}",
            user         => $ENV{BS_USER},
            password     => $ENV{BS_PASS},
        },
    }
};

get '/' => sub {
    my @files = rset('File')->all();
warn "size: " scalar @files ."\n";
    return { error => 1, files => [ @files ] };
};

get '/block-map/:ufn' => sub {
    my $ufn = params->{ufn};

};

get '/block/:ufn/:id' => sub {
    my $ufn      = params->{ufn};
    my $block_id = params->{id};
};

post '/new' => sub {
    my $json = request->data;
    warn Dumper $json;

};

post '/block' => sub {
    my $json = request->data;
    warn Dumper $json;

};

1;
