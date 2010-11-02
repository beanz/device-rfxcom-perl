use strict;
use warnings;
package Device::RFXCOM::Decoder::X10;

# ABSTRACT: Device::RFXCOM::Decoder::X10 decode X10 RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize X10 RF messages from an RFXCOM RF receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_X10_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::Decoder';
use Device::RFXCOM::Response::X10;

=head2 C<new($parent)>

This constructor returns a new X10 decoder object.

=cut

sub new {
  my $pkg = shift;
  $pkg->SUPER::new(unit_cache => {}, default_x10_level => 10, @_);
}

=head2 C<decode( $parent, $message, $bytes, $bits )>

This method attempts to recognize and decode RF messages from X10
devices.  If messages are identified, a reference to a list of message
data is returned.  If the message is not recognized, undef is
returned.

=cut

sub decode {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  my $res = from_rf($bytes) or return;
  my $h = $res->{house};
  my $f = $res->{command};
  $self->{unit_cache}->{$h} = $res->{unit} if (exists $res->{unit});
  my %r =
    (
     command => $f,
    );
  my $u = $self->{unit_cache}->{$h};
  my $dont_cache;
  if (defined $u) {
    $r{device} = $h.$u;
  } else {
    warn "Don't have unit code for: $h $f\n";
    $dont_cache = 1;
    $r{house} = $h;
  }
  if ($f eq 'bright' or $f eq 'dim') {
    $r{level} = $self->{default_x10_level};
  }
  return ([Device::RFXCOM::Response::X10->new(%r)], undef, undef, $dont_cache);
}

my %byte_to_house =
  (
   '6' => 'a',  '7' => 'b',  '4' => 'c',  '5' => 'd',  '8' => 'e',  '9' => 'f',
   '10' => 'g',  '11' => 'h',  '14' => 'i',  '15' => 'j',  '12' => 'k',
   '13' => 'l',  '0' => 'm',  '1' => 'n',  '2' => 'o',  '3' => 'p',
  );

my $i = 1;
my %byte_to_unit =
  (
   0x00 => 1, 0x10 => 2, 0x08 => 3, 0x18 => 4, 0x40 => 5, 0x50 => 6,
   0x48 => 7, 0x58 => 8
  );
my $unit_mask= 0x58;

my %byte_to_command =
  (
   0x0 => 'on',
   0x20 => 'off',
   0x80 => 'all_lights_off',
   0x88 => 'bright',
   0x90 => 'all_lights_on',
   0x98 => 'dim',
  );

=head2 C<from_rf( $bytes )>

Takes an array reference of bytes from an RF message and converts it
in to an hash reference with the details.

=cut

sub from_rf {
  my $bytes = shift;

  return unless (is_x10($bytes));
  my %r = ();
  my $mask = 0x98;
  unless ($bytes->[2]&0x80) {
    $r{unit} = $byte_to_unit{$bytes->[2]&$unit_mask};
    $r{unit} += 8 if ($bytes->[0]&0x4);
    $mask = 0x20;
  }
  $r{house} = $byte_to_house{($bytes->[0]&0xf0)>>4};
  $r{command} = $byte_to_command{$bytes->[2]&$mask};
  return \%r;
}

=head2 C<is_x10( $bytes )>

Takes an array reference of bytes from an RF message and returns true
if it appears to be a valid X10 message.

=cut

sub is_x10 {
  my $bytes = shift;

  return unless (scalar @$bytes == 4);

  (($bytes->[2]^0xff) == $bytes->[3] &&
   ($bytes->[0]^0xff) == $bytes->[1] &&
   !($bytes->[2]&0x7));
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
