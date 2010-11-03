use strict;
use warnings;
package Device::RFXCOM::Response::HomeEasy;

# ABSTRACT: Device::RFXCOM::Response class for Home Easy message from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Home Easy messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_HOMEEASY_DEBUG};
use Carp qw/croak/;

=method C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

=method C<type()>

This method returns 'homeeasy'.

=cut

sub type { 'homeeasy' }

=method C<address()>

This method returns the address of the home easy device that sent the
message.

=cut

sub address { shift->{address} }

=method C<unit()>

This method returns the unit of the home easy device that sent the
message.  It will be a number or the string 'group'.

=cut

sub unit { shift->{unit} }

=method C<command()>

This method returns the command from the home easy message.

=cut

sub command { shift->{command} }

=method C<level()>

This method returns the level from the home easy message.  This
is only defined for some types of preset/bright/dim messages.

=cut

sub level { shift->{level} }

=method C<summary()>

This method returns a string summary of the home easy message.

=cut

sub summary {
  my $self = shift;
  sprintf('%s/%s.%s/%s%s',
          $self->type,
          $self->address,$self->unit,
          $self->command,
          $self->level ? '['.$self->level.']' : '');
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
