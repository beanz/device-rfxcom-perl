use strict;
use warnings;
package Device::RFXCOM::Response::Sensor;

# ABSTRACT: Device::RFXCOM::Response class for Sensor message from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Sensor messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_SENSOR_DEBUG};
use Carp qw/croak/;

=method C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

=method C<type()>

This method returns 'sensor'.

=cut

sub type { 'sensor' }

=method C<measurement()>

This method returns a string describing the type of measurement.  For
example, C<temp>, C<humidity>, C<voltage>, C<battery>, C<uv>, etc.

=cut

sub measurement { shift->{measurement} }

=method C<device()>

This method returns a string representing the device that sent the
sensor RF message.

=cut

sub device { shift->{device} }

=method C<value()>

This method returns the value of the measurement in the sensor RF
message.

=cut

sub value { shift->{value} }

=method C<units()>

This method returns the units of the value() in the sensor RF message.

=cut

sub units { shift->{units} }

=method C<summary()>

This method returns a string summary of the sensor message.

=cut

sub summary {
  my $self = shift;
  $self->type.'/'.
    $self->device.'['.$self->measurement.']='.$self->value.($self->units||'');
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
