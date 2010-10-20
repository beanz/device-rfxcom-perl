use strict;
use warnings;
package Device::RFXCOM::Decoder::Visonic;

# ABSTRACT: Device::RFXCOM::Decoder::Visonic decode Visonic RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize Visonic RF messages from an RFXCOM RF receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_VISONIC_DEBUG};
use Carp qw/croak/;
use Device::RFXCOM::Decoder qw/hi_nibble lo_nibble/;
our @ISA = qw(Device::RFXCOM::Decoder);
use Device::RFXCOM::Response::Security;
use Device::RFXCOM::Response::Sensor;

my %bits = ( 36 => 'powercode', 66 => 'codesecure' );

=head2 C<decode( $parent, $message, $bytes, $bits )>

This method attempts to recognize and decode RF messages from Visonic
PowerCode and CodeSecure devices.  If messages are identified, a
reference to a list of message data is returned.  If the message is
not recognized, undef is returned.

=cut

sub decode {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  my $method = $bits{$bits} or return;
  return $self->$method($parent, $message, $bytes, $bits);
}

=head2 C<codesecure( $parent, $message, $bytes, $bits )>

This method decodes a message from a Visonic code secure keyfob.

=cut

sub codesecure {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  # parity check?

  my $code =
    sprintf '%02x%02x%02x%02x',
      $bytes->[0], $bytes->[1], $bytes->[2], $bytes->[3];

  my $device =
    sprintf 'codesecure.%02x%02x%02x%x',
      $bytes->[4], $bytes->[5], $bytes->[6], hi_nibble($bytes->[7]);
  my $event =
    { 0x1 => "light",
      0x2 => "arm-away",
      0x4 => "disarm",
      0x8 => "arm-home",
    }->{lo_nibble($bytes->[7])};
  unless ($event) {
    # probably invalid message
    # TOFIX: figure out parity check so this isn't required
    return;
  }
  my $repeat = $bytes->[8]&0x4;
  my $low_bat = $bytes->[8]&0x8;
  my %args =
    (
     event => $event,
     device  => $device,
    );
  $args{repeat} = 1 if ($repeat);
  return
    [
     Device::RFXCOM::Response::Security->new(%args),
     Device::RFXCOM::Response::Sensor->new(device => $device,
                                           measurement => 'battery',
                                           value => $low_bat ? 10 : 90,
                                           units => '%'),
    ];
}

=head2 C<powercode( $parent, $message, $bytes, $bits )>

This method decodes a message from a Visonic powercode sensor.

=cut

sub powercode {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  my $parity;
  foreach (0 .. 3) {
    $parity ^= hi_nibble($bytes->[$_]);
    $parity ^= lo_nibble($bytes->[$_]);
  }
  unless ($parity == hi_nibble($bytes->[4])) {
    warn
      sprintf("Possible Visonic powercode with parity error %x != %x\n",
              $parity, hi_nibble($bytes->[4]));
    return;
  }

  my $device = sprintf('powercode.%02x%02x%02x',
                       $bytes->[0], $bytes->[1], $bytes->[2]);
  $device .= 's' unless ($bytes->[3] & 0x4); # suffix s for secondary contact
  my $restore = $bytes->[3] & 0x8;
  my $event   = $bytes->[3] & 0x10;
  my $low_bat = $bytes->[3] & 0x20;
  my $alert   = $bytes->[3] & 0x40;
  my $tamper  = $bytes->[3] & 0x80;

  # I assume $event is to distinguish whether it's a new event or just a
  # heartbeat message?
  my %args =
    (
     event => $alert ? 'alert' : 'normal',
     device  => $device,
    );
  $args{restore} = 1 if ($restore);
  $args{tamper} = 1 if ($tamper);
  return [
          Device::RFXCOM::Response::Security->new(%args),
          Device::RFXCOM::Response::Sensor->new(device => $device,
                                                measurement => 'battery',
                                                value => $low_bat ? 10 : 90,
                                                units => '%'),
         ];
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
