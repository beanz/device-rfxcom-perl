use strict;
use warnings;
package Device::RFXCOM::Decoder::Digimax;

# ABSTRACT: Device::RFXCOM::Decoder::Digimax decode Digimax RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize Digimax RF messages from an RFXCOM RF receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_DIGIMAX_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::Decoder';
use Device::RFXCOM::Response::Thermostat;
use Device::RFXCOM::Decoder qw/hi_nibble lo_nibble nibble_sum/;

=head2 C<decode( $parent, $message, $bytes, $bits )>

This method attempts to recognize and decode RF messages from Digimax
devices.  If messages are identified, a reference to a list of message
data is returned.  If the message is not recognized, undef is
returned.

=cut

sub decode {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  return unless ($bits == 44);
  my $p =
    hi_nibble($bytes->[0]) + lo_nibble($bytes->[0]) +
      hi_nibble($bytes->[1]) + lo_nibble($bytes->[1]) +
        hi_nibble($bytes->[2]) + lo_nibble($bytes->[2]);
  $p &= 0xf;
  return unless ($p == 0xf);

  $p =
    hi_nibble($bytes->[3]) + lo_nibble($bytes->[3]) +
      hi_nibble($bytes->[4]) + lo_nibble($bytes->[4]) +
        hi_nibble($bytes->[5]);
  $p &= 0xf;
  return unless ($p == 0xf);

  my $state =
    [
     'undef', 'demand', 'satisfied', 'init'
    ]->[hi_nibble($bytes->[2])&0x3];

  my $temp = $bytes->[3];
  my $set = $bytes->[4]&0x3f;
  my $mode = $bytes->[4]&0x40 ? 'heat' : 'cool';
  my $device = sprintf 'digimax.%02x%02x', $bytes->[0], $bytes->[1];
  printf STDERR "Thermostat: $device $state $temp $set $mode\n" if DEBUG;
  return [Device::RFXCOM::Response::Thermostat->new(device => $device,
                                                    temp => $temp,
                                                    set => $set,
                                                    mode => $mode,
                                                    state => $state,
                                                   )];
}

1;

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/