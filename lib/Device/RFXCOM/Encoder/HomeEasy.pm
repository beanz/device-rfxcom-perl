use strict;
use warnings;
package Device::RFXCOM::Encoder::HomeEasy;

# ABSTRACT: Device::RFXCOM::Encoder::HomeEasy encode HomeEasy RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

This is a module for encoding RF messages for HomeEasy
(L<http://www.homeeasy.eu/>) devices so that they can be dispatched to
an RFXCOM RF transmitter.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_ENCODER_HOMEEASY_DEBUG};
use Carp qw/croak carp/;
use base 'Device::RFXCOM::Encoder';
use Device::RFXCOM::Response::HomeEasy;

=method C<encode( $parent, \%params )>

This method constructs the RF message data for a message to send to
a HomeEasy device.

=cut

sub encode {
  my ($self, $parent, $p) = @_;
  my @bytes = ( 0, 0, 0, 0, 0 );
  my $length = 33;
  my $command;

  unless (exists $p->{command} && exists $p->{unit} && exists $p->{address}) {
    carp $self.'->encode: Invalid homeeasy message';
    return [];
  }
  if ($p->{command} eq 'preset') {
    unless (exists $p->{level}) {
      carp $self.'->encode: Invalid homeeasy message';
      return [];
    }
    $length = 36;
    $bytes[4] = $p->{level} << 4;
    $command = 0;
  } else {
    $command = $p->{command} eq 'on' ? 1 : 0;
  }
  if ($p->{unit} eq 'group') {
    $p->{unit} = 0;
    $command |= 0x2;
  }
  my $addr = encode_address($p->{address});
  $bytes[0] = $addr >> 18;
  $bytes[1] = ($addr >> 10) & 0xff;
  $bytes[2] = ($addr >> 2) & 0xff;
  $bytes[3] = (($addr & 0x3) << 6);
  $bytes[3] |= $p->{unit};
  $bytes[3] |= ($command << 4);
  return {
          raw => (pack 'C6', $length, @bytes),
          desc =>
            'homeeasy: '.(join '/',
                          grep { defined $_
                               } @{$p}{qw/command address unit/})
         },
}

=method C<encode_address( $addr )>

Takes a 26-bit address in the form of a hex string prefixed by '0x' or
an arbitrary string.  A hex string is converted in the obvious way.
An arbitrary string is hashed to a 26-bit value.

=cut

sub encode_address {
  my $addr = shift;
  return hex($addr) & 0x3ffffff if ($addr =~ /^0x[0-9a-f]{1,8}$/i);
  my $val = 0;
  my $offset = 0;
  foreach my $b (map { ord $_ } split //, $addr) {
    $val ^= ($b&0x7f) << $offset;
    $offset += 4;
    $offset = 0 if ($offset > 20);
  }
  return $val & 0x3ffffff;
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
