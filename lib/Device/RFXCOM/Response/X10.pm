use strict;
use warnings;
package Device::RFXCOM::Response::X10;

# ABSTRACT: Device::RFXCOM::Response class for X10 message from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for X10 messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_X10_DEBUG};
use Carp qw/croak/;

=head2 C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

=head2 C<type()>

This method returns 'x10'.

=cut

sub type { 'x10' }

=head2 C<device()>

This method returns the X10 device from the RF message.  That is,
C<a1>, C<a2>, ... C<a16>, ..., C<p1>, ..., C<p16>.  It will be
undefined if no unit code is present for the house code.

=cut

sub device { shift->{device} }

=head2 C<house()>

This method returns the X10 house code from the RF message.  That is,
C<a>, C<b>, ... C<p>.  It will be undefined if L<device> is defined.

=cut

sub house { shift->{house} }

=head2 C<command()>

This method returns the X10 command from the RF message.  For example,
C<on>, C<off>, C<bright>, C<dim>, etc.

=cut

sub command { shift->{command} }

=head2 C<level()>

This method returns the X10 level for C<bright> and C<dim> commands or
undef if the level is not defined for the command.

=cut

sub level { shift->{level} }

=head2 C<summary()>

This method returns a string summary of the X10 message.

=cut

sub summary {
  my $self = shift;
  sprintf('%s/%s/%s%s',
          $self->type,
          $self->device ? $self->device : $self->house,
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
