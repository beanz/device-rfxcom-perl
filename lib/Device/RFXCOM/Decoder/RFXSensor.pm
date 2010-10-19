use strict;
use warnings;
package Device::RFXCOM::Decoder::RFXSensor;

# ABSTRACT: Device::RFXCOM::Decoder::RFXSensor decode RFXSensor RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize RFXSensor RF messages from an RFXCOM RF receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_RFXSENSOR_DEBUG};
use Carp qw/croak/;
use Device::RFXCOM::Decoder qw/nibble_sum/;
our @ISA = qw(Device::RFXCOM::Decoder);

my %info =
  (
   0x01 => "sensor addresses incremented",
   0x02 => "battery low detected",
   0x03 => "conversion not ready",
  );

my %error =
  (
   0x81 => "no 1-wire device connected",
   0x82 => "1-wire ROM CRC error",
   0x83 => "1-wire device connected is not a DS18B20 or DS2438",
   0x84 => "no end of read signal received from 1-wire device",
   0x85 => "1-wire scratchpad CRC error",
   0x86 => "temperature conversion not ready in time",
   0x87 => "A/D conversion not ready in time",
  );

my %types = (
             'RFX' => { fun => \&decode_init, len => 32 },
             'RF2' => { fun => \&decode_init, len => 32 },
             'RF3' => { fun => \&decode_init, len => 32 },
             'SEN' => { fun => \&decode_sen, len => 40 },
);

=head2 C<new($parent)>

This constructor returns a new RFXSensor decoder object.

=cut

sub new {
  my ($pkg, $parent) = @_;
  $pkg->SUPER::new(rfxsensor_cache => {}, @_);
}

=head2 C<decode( $parent, $message, $bytes, $bits )>

This method attempts to recognize and decode RF messages from
RFXSensor devices.  If messages are identified, a reference to a list
of message data is returned.  If the message is not recognized, undef
is returned.

=cut

sub decode {
  my ($self, $parent, $message, $bytes, $bits) = @_;
  my $str = substr $message, 0, 3;
  if (exists $types{$str} && $bits == $types{$str}->{len}) {
    return $types{$str}->{fun}->($self, $parent, $message, $bytes, $bits, $str);
  }
  $bits == 32 or return;
  (($bytes->[0]^0xf0) == $bytes->[1]) or return;
  my @nib = map { hex $_ } split //, unpack "H*", $message;
  ((nibble_sum(7, \@nib)&0xf)^0xf) == $nib[7] or return;
  my $device = sprintf("rfxsensor%02x%02x", $bytes->[0], $bytes->[1]);
  my $base = sprintf("%02x%02x", $bytes->[0]&0xfc, $bytes->[1]&0xfc);
  my $cache = $self->{rfxsensor_cache};
  my $supply_voltage = $cache->{$base}->{supply};
  my $last_temp = $cache->{$base}->{temp};
  my $flag = $bytes->[3]&0x10;
  if ($flag) {
    if (exists $info{$bytes->[2]}) {
      warn "RFXSensor info $device: ".$info{$bytes->[2]}."\n";
    } elsif (exists $error{$bytes->[2]}) {
      warn "RFXSensor error $device: ".$error{$bytes->[2]}."\n";
    } else {
      warn sprintf "RFXSensor unknown status messages: %02x\n", $bytes->[2];
    }
    return;
  } else {
    my $type = ($bytes->[0]&0x3);
    if ($type == 0) {
      # temp
      my $temp = $bytes->[2] + (($bytes->[3]&0xe0)/0x100);
      if ($temp > 150) {
        $temp = -1*(256-$temp);
      }
      $cache->{$base}->{temp} = $temp;
      return [{
               schema => 'sensor.basic',
               body => {
                        device => $device,
                        type => 'temp',
                        current => $temp,
                        base_device => $base,
                       },
              }];
    } elsif ($type == 1) {
      my $v = ( ($bytes->[2]<<3) + ($bytes->[3]>>5) ) / 100;
      my @res = ();
      push @res,
        {
         schema => 'sensor.basic',
         body => {
                  device => $device,
                  type => 'voltage',
                  current => $v,
                  base_device => $base,
                 },
        };
      unless (defined $supply_voltage) {
        warn "Don't have supply voltage for $device/$base yet\n";
        return \@res;
      }
      # See http://archives.sensorsmag.com/articles/0800/62/main.shtml
      my $hum = sprintf "%.2f", (($v/$supply_voltage) - 0.16)/0.0062;
      #print STDERR "Sensor Hum: $hum\n";
      if (defined $last_temp) {
        #print STDERR "Last temp: $last_temp\n";
        $hum = sprintf "%.2f", $hum / (1.0546 - 0.00216*$last_temp);
        #print STDERR "True Hum: $hum\n";
      } else {
        warn "Don't have temperature for $device/$base yet - assuming 25'C\n";
      }
      push @res,
        {
         schema => 'sensor.basic',
         body => {
                  device => $device,
                  type => 'humidity',
                  current => $hum,
                  base_device => $base,
                 },
        };
      return \@res;
    } elsif ($type == 2) {
      my $v = ( ($bytes->[2]<<3) + ($bytes->[3]>>5) ) / 100;
      $cache->{$base}->{supply} = $v;
      return [{
               schema => 'sensor.basic',
               body => {
                        device => $device,
                        type => 'voltage',
                        current => $v,
                        base_device => $base,
                       },
              }];
    } else {
      warn "Unsupported RFXSensor: type=$type\n";
      # not implemented yet
    }
  }
  return;
}

=head2 C<decode_init( $parent, $message, $bytes, $bits, $type )>

Parse RFX Sensor initialization messages and output information to STDERR.

=cut

sub decode_init {
  my ($self, $parent, $message, $bytes, $bits, $type) = @_;

  warn sprintf "RFXSensor %s, version %02x, transmit mode %s, initialized\n",
    { 0x58 => 'Type-1', 0x32 => 'Type-2', 0x33 => 'Type-3' }->{$bytes->[2]},
      $bytes->[3]&0x7f, $bytes->[3]&0x80 ? 'slow' : 'fast';
  return [];
}

=head2 C<decode_sen( $parent, $message, $bytes, $bits, $str )>

Parse RFX Sensor version messages and output information to STDERR.

=cut

sub decode_sen {
  my ($self, $parent, $message, $bytes, $bits, $str) = @_;

  warn sprintf "RFXSensor SEN%d, type %02x (%s)\n", $bytes->[3], $bytes->[4],
    { 0x26 => 'DS2438', 0x28 => 'DS18B20' }->{$bytes->[4]} || 'unknown';
  return [];
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
