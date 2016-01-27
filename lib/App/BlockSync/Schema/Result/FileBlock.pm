use utf8;
package App::BlockSync::Schema::Result::FileBlock;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::BlockSync::Schema::Result::FileBlock

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<App::BlockSync::Schema::Result>

=cut

use base 'App::BlockSync::Schema::Result';

=head1 TABLE: C<file_block>

=cut

__PACKAGE__->table("file_block");

=head1 ACCESSORS

=head2 file

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 crcsum

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "file",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "id",
  { data_type => "integer", is_nullable => 0 },
  "crcsum",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</file>

=back

=cut

__PACKAGE__->set_primary_key("file");

=head1 RELATIONS

=head2 file

Type: belongs_to

Related object: L<App::BlockSync::Schema::Result::File>

=cut

__PACKAGE__->belongs_to(
  "file",
  "App::BlockSync::Schema::Result::File",
  { ufn => "file" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-26 21:04:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S4eWUuY1aE0z7gN3jdoVSQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
