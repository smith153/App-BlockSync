package App::BlockSync::Server;
use Dancer2;
use Dancer2::Plugin::DBIC qw(rset);
use IO::File;
use Compress::Zlib qw(uncompress);
use MIME::Base64 qw ( encode_base64 decode_base64);
use Digest::MD5 qw(md5_hex);
use File::Path qw(make_path);
use File::Temp qw(tempfile);

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
        { 'file' => $ufn, id => $block_id },
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
    my $file = request->data;
    my $rs;
    my $path;
    my $compressed = ( exists $file->{compressed} && $file->{compressed} );
    my $block_size = $file->{block_size};

    eval {
        $path = create_file_path(
            $file->{hostname}, $file->{uhn},
            $file->{path},     $file->{filename}
        );

        foreach my $block ( @{ $file->{file_blocks} } ) {

            my $seek = $block->{id} * $block_size;
            write_block( $seek, $block, $compressed, $path );

            delete $block->{data};    #don't store to DB
        }

        file_sum_compare( $path, $file->{crcsum} ) or die "Sum missmatch!";

        #warn Dumper $file;
        rset('File')->create($file);
    };

    if ($@) {
        warn $@;
        return { success => 0, error => ( split( /\n/, $@ ) )[0] };
    } else {
        return { success => 1, error => 0 };
    }

};

post '/file' => sub {
    my $file = request->data;
    warn Dumper $file;

    my $rs;
    eval { $rs = rset('File')->update($file); };

    if ($@) {
        warn $@;
        return { success => 0, error => ( split( /\n/, $@ ) )[0] };
    } else {
        return { success => 1, error => 0 };
    }

};

post '/block' => sub {
    my $file = request->data;
    warn Dumper $file;

    my $rs;
    my $path;
    my $compressed = ( exists $file->{compressed} && $file->{compressed} );
    my $block_size;
    my $block    = $file->{file_blocks}[0];
    my $file_old = rset('File')->search(
        {
            ufn => $file->{ufn},
            id  => $block->{id},

        },
        {
            prefetch => 'file_blocks',
        }
    )->next();

    eval {
        $block_size = $file_old->block_size();
        $path       = create_file_path(
            $file->{hostname}, $file->{uhn},
            $file->{path},     $file->{filename}
        );

        #shorten file if newer file is shorter
        if ( $file->{file_size} < $file_old->file_size() ) {
            file_shorten( $path, $file->{file_size}, );
        }

        my $seek = $block->{id} * $block_size;
        write_block( $seek, $block, $compressed, $path );

        delete $block->{data};    #don't store to DB

        $file_old->dirty('1');
        ( $file_old->file_blocks )[0]->update($block);
        $file_old->update();
    };

    if ($@) {
        warn $@;
        return { success => 0, error => ( split( /\n/, $@ ) )[0] };
    } else {
        return { success => 1, error => 0 };
    }

};

sub file_sum_compare
{
    my ( $file_path, $sum ) = @_;
    my $md5 = Digest::MD5->new();
    open( my $fh, "<$file_path" );
    binmode($fh);

    $md5->addfile($fh);
    close($fh);

    return $md5->hexdigest() eq $sum;
}

sub file_shorten
{
    my ( $file_path, $size ) = @_;
    truncate( $file_path, $size ) or die "Couldn't shorten file $file_path $!";

}

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
