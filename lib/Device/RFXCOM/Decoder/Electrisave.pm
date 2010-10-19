use strict;
use warnings;
package Device::RFXCOM::Decoder::Electrisave;

# ABSTRACT: Device::RFXCOM::Decoder::Electrisave decode Electrisave RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize Electrisave/Cent-a-meter/OWL RF messages from an
RFXCOM RF receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_ELECTRISAVE_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::Decoder';

=head2 C<decode( $parent, $message, $bytes, $bits )>

This method attempts to recognize and decode RF messages from
Electrisave/Cent-a-meter/OWL devices.  If a suitable message is
identified, a reference to a list of readings is returned.
If the message is not recognized, undef is returned.

=cut

sub decode {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  $bits == 120 or return;

  ($bytes->[0]==0xea && $bytes->[9]==0xff && $bytes->[10]==0x5f) or return;

  my $device = sprintf "%02x", $bytes->[2];
  my @ct = ();
  $ct[1] = ( (($bytes->[3]     )   )+(($bytes->[4]&0x3 )<<8) ) / 10;
  $ct[2] = ( (($bytes->[4]&0xFC)>>2)+(($bytes->[5]&0xF )<<6) ) / 10;
  $ct[3] = ( (($bytes->[5]&0xF0)>>4)+(($bytes->[6]&0x3F)<<4) ) / 10;
  $ct[0] = $ct[1] + $ct[2] + $ct[3];
  my @msgs = ();
  foreach my $index (0..3) {
    my $dev = $device.($index ? '.'.$index : '');
    printf "electrisave d=%s current=%.2f\n", $dev, $ct[$index] if DEBUG;
    push @msgs,
      {
       schema => 'sensor.basic',
       body => {
                device => 'electrisave.'.$dev,
                type => 'current',
                current => $ct[$index],
               }
      };
  }
  return \@msgs;
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
