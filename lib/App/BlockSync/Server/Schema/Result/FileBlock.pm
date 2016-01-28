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
  is_nullable: 0
  size: 64

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 crcsum

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 compressed

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "file",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "id",
  { data_type => "integer", is_nullable => 0 },
  "crcsum",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "compressed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</file>

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("file", "id");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-28 09:32:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u02IbugKXnoa0RcMJWBViw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
