use strict;
use warnings;
package Device::RFXCOM::Response::Thermostat;

# ABSTRACT: Device::RFXCOM::Response class for Thermostat RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Thermostat messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_THERMOSTAT_DEBUG};
use Carp qw/croak/;

=method C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

=method C<type()>

This method returns 'thermostat'.

=cut

sub type { 'thermostat' }

=method C<device()>

This method returns an identifier for the device.

=cut

sub device { shift->{device} }

=method C<state()>

This method returns the state of the thermostat.  Typical values include:

=over 4

=item undef

If no set point has been defined

=item demand

If heat (or cooling in 'cool' mode) is required.

=item satisfied

If no heat (or cooling in 'cool' mode) is required.

=item init

If the thermostat is being initialized.

=back

=cut

sub state { shift->{state} }

=method C<temp()>

This method returns the current temperature.

=cut

sub temp { shift->{temp} }

=method C<set()>

This method returns the set point for the thermostat.  It will be zero
if it has not been defined.

=cut

sub set { shift->{set} }

=method C<mode()>

This method returns the mode for the thermostat.  It will be 'heat'
or 'cool'.
`
=cut

sub mode { shift->{mode} }

=method C<summary()>

This method returns a string summary of the thermostat message.

=cut

sub summary {
  my $self = shift;
  sprintf('%s/%s=%d/%d/%s/%s',
          $self->type,
          $self->device,
          $self->temp,
          $self->set,
          $self->state,
          $self->mode)
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
