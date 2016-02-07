use utf8;
package App::BlockSync::Server::Schema::Result::File;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::BlockSync::Server::Schema::Result::File

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<App::BlockSync::Server::Schema::Result>

=cut

use base 'App::BlockSync::Server::Schema::Result';

=head1 TABLE: C<file>

=cut

__PACKAGE__->table("file");

=head1 ACCESSORS

=head2 ufn

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 uhn

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 hostname

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 path

  data_type: 'text'
  is_nullable: 0

=head2 filename

  data_type: 'text'
  is_nullable: 0

=head2 crcsum

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 file_size

  data_type: 'integer'
  is_nullable: 0

=head2 mod_time

  data_type: 'integer'
  is_nullable: 0

=head2 block_size

  data_type: 'integer'
  is_nullable: 0

=head2 compressed

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ufn",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "uhn",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "hostname",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "filename",
  { data_type => "text", is_nullable => 0 },
  "crcsum",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "file_size",
  { data_type => "integer", is_nullable => 0 },
  "mod_time",
  { data_type => "integer", is_nullable => 0 },
  "block_size",
  { data_type => "integer", is_nullable => 0 },
  "compressed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ufn>

=back

=cut

__PACKAGE__->set_primary_key("ufn");

=head1 RELATIONS

=head2 file_blocks

Type: has_many

Related object: L<App::BlockSync::Server::Schema::Result::FileBlock>

=cut

__PACKAGE__->has_many(
  "file_blocks",
  "App::BlockSync::Server::Schema::Result::FileBlock",
  { "foreign.file" => "self.ufn" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-02-07 17:41:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:12cWkrQGf4ky22hRZdwKZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
