package App::BlockSync::Server;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);
use IO::File;
use Compress::Zlib qw(uncompress);
use MIME::Base64 qw ( encode_base64 decode_base64);
use File::Path qw(make_path);

our $VERSION = '0.1';
use Data::Dumper;

$ENV{BS_DATADIR} //= "public/data";

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
            convert_blessed => '1',
        }
    }
};

set environment => "production";

#set public_dir  => "";
set views       => "";
set template    => "Tiny";
set layout      => "";
set layout_dir  => "";
set show_errors => "";
set serializer  => 'JSON';

get '/' => sub {
    my @files = rset('File')->all();
    return { error => 1, files => [@files] };
};

get '/block-map/:ufn' => sub {
    my $ufn = params->{ufn};
    my $rs  = rset('File')->search(
        { ufn => $ufn },
        {
            prefetch     => 'file_blocks',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',

        },
    )->next();

    return $rs;

};

get '/block/:ufn/:id' => sub {
    my $ufn      = params->{ufn};
    my $block_id = params->{id};

    my $rs = rset('FileBlock')->search(
        { 'me.file' => $ufn, id => $block_id },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next();

    return $rs || { error => 1 };
};

get '/delete/:ufn' => sub {
    my $ufn = params->{ufn};
    my $rs = rset('File')->search( { ufn => $ufn } )->next();
    my $path;

    return { success => 0, error => "Ufn not found" } unless $rs;

    eval {
        $path =
          create_file_path( $rs->hostname, $rs->uhn, $rs->path, $rs->filename );
        $rs->delete();
        unlink($path);
    };

    if ($@) {
        warn $@;
        return { success => 0, error => ( split( /\n/, $@ ) )[0] };
    } else {
        return { success => 1, error => 0 };
    }

};

post '/new' => sub {
    my $json = request->data;
    my $rs;
    my $path;
    my $compressed = ( exists $json->{compressed} && $json->{compressed} );
    my $block_size = $json->{block_size};

    eval {
        $path = create_file_path(
            $json->{hostname}, $json->{uhn},
            $json->{path},     $json->{filename}
        );

        foreach my $block ( @{ $json->{file_blocks} } ) {

            my $seek = $block->{id} * $block_size;
            write_block( $seek, $block, $compressed, $path );

            delete $block->{data};    #don't store to DB
        }

        #warn Dumper $json;
        rset('File')->create($json);
    };

    if ($@) {
        warn $@;
        return { success => 0, error => ( split( /\n/, $@ ) )[0] };
    } else {
        return { success => 1, error => 0 };
    }

};

post '/block' => sub {
    my $json = request->data;
    warn Dumper $json;

};

sub create_file_path
{
    my ( $hostname, $uhn, $path, $filename ) = @_;
    my $full_path = $ENV{BS_DATADIR} . "/$hostname-$uhn/$path";
    $full_path =~ s/[^\w\/\.]+/_/g;

    if ( not -d $full_path ) {
        make_path($full_path);
        die "Couldn't make path $full_path $!\n" if ( not -d $full_path );
    }
    $full_path .= "/$filename";
    return $full_path;
}

sub write_block
{
    my ( $seek, $block, $compressed, $path ) = @_;
    my $fh = IO::File->new("> $path");
    $fh->binmode();

    $block->{data} = decode_base64( $block->{data} );

    if ($compressed) {
        $block->{data} = uncompress( $block->{data} );
    }

    $fh->setpos($seek);
    $fh->write( $block->{data} );

    $fh->close();
}

1;
