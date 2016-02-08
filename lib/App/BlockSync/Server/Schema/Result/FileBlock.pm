use utf8;
package App::BlockSync::Server::Schema::Result::FileBlock;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::BlockSync::Server::Schema::Result::FileBlock

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<App::BlockSync::Server::Schema::Result>

=cut

use base 'App::BlockSync::Server::Schema::Result';

=head1 TABLE: C<file_block>

=cut

__PACKAGE__->table("file_block");

=head1 ACCESSORS

=head2 file

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

Unique file name that block belongs to

=head2 id

  data_type: 'integer'
  is_nullable: 0

File block number

=head2 crcsum

  data_type: 'varchar'
  is_nullable: 0
  size: 64

File block checksum

=cut

__PACKAGE__->add_columns(
  "file",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "id",
  { data_type => "integer", is_nullable => 0 },
  "crcsum",
  { data_type => "varchar", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</file>

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("file", "id");

=head1 RELATIONS

=head2 file

Type: belongs_to

Related object: L<App::BlockSync::Server::Schema::Result::File>

=cut

__PACKAGE__->belongs_to(
  "file",
  "App::BlockSync::Server::Schema::Result::File",
  { ufn => "file" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-02-07 19:02:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X7S4PfIZPjG6OTID5u7L1Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
