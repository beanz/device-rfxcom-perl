use strict;
use warnings;
package Device::RFXCOM::Decoder::HomeEasy;

# ABSTRACT: Device::RFXCOM::Decoder::HomeEasy decode HomeEasy RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

This is a module for decoding RF messages from HomeEasy
(L<http://www.homeeasy.eu/>) devices that have been received by an
RFXCOM RF receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_HOMEEASY_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::Decoder';

=head2 C<decode( $parent, $message, $bytes, $bits )>

This method attempts to recognize and decode RF messages from HomeEasy
devices.  If messages are identified, a reference to a list of message
data is returned.  If the message is not recognized, undef is
returned.

=cut

sub decode {
  my ($self, $parent, $message, $bytes, $bits) = @_;

  $bits == 34 or $bits == 36 or return;

  # HomeEasy devices seem to send duplicates with different byte[4] high nibble
  my @b = @{$bytes};
  my $b4 = $b[4];
  $b[4] &= 0xf;
  if ($b[4] != $b4) {
    $parent->_is_duplicate($bits, pack "C*", @b) and return [];
    $b[4] = $b4;
  }

  my $res = from_rf($bits, $bytes);

  printf "homeeasy c=%s u=%d a=%x\n",
    $res->{command}, $res->{unit}, $res->{address} if DEBUG;
  my $body = {
              address => (sprintf "0x%x",$res->{address}),
              unit => $res->{unit},
              command => $res->{command},
             };

  $body->{level} = $res->{level} if ($res->{command} eq 'preset');

  return [{ schema => 'homeeasy.basic', body => $body }];
}

=head2 C<from_rf( $bits, $bytes )>

Takes an array reference of bytes from an RF message and converts it
in to an hash reference with the details.

=cut

sub from_rf {
  my $length = shift;
  my $bytes = shift;
  my %p = ();
  $p{address} = ($bytes->[0] << 18) + ($bytes->[1] << 10) +
    ($bytes->[2] << 2) + ($bytes->[3] >> 6);
  my $command = ($bytes->[3] >> 4) & 0x3;
  $p{unit} = ($command & 0x2) ? 'group' : ($bytes->[3] & 0xf);
  if ($length == 36) {
    $p{command} =  'preset';
    $p{level} = $bytes->[4] >> 4;
  } else {
    $p{command} = ($command & 0x1) ? 'on' : 'off';
  }
  return \%p;
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
