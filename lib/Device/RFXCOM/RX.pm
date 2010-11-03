use strict;
use warnings;
package Device::RFXCOM::RX;

# ABSTRACT: Device::RFXCOM::RX module for RFXCOM RF receiver

=head1 SYNOPSIS

  # for a USB-based device
  my $rx = Device::RFXCOM::RX->new(device => '/dev/ttyUSB0');

  $|=1; # don't buffer output

  # simple interface to read received data
  while (my $data = $rx->read($timeout)) {
    print $data->summary,"\n" unless ($data->duplicate);
  }

  # for a networked device
  my $rx = Device::RFXCOM::RX->new(device => '10.0.0.1:10001');

=head1 DESCRIPTION

Module for reading data from an RFXCOM RF receiver.

B<IMPORTANT:> This API is still subject to change.

=cut

use 5.006;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_RX_DEBUG},
  TESTING => $ENV{DEVICE_RFXCOM_RX_TESTING},
};
use Carp qw/croak/;
use Fcntl;
use IO::Handle;
use IO::Select;
use Time::HiRes;
use Device::RFXCOM::Response;
use Module::Pluggable
  search_path => 'Device::RFXCOM::Decoder',
  instantiate => 'new';

=head2 C<new(%parameters)>

This constructor returns a new RFXCOM RF receiver object.
The only supported parameter is:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based RFXCOM receivers.

The default is C</dev/rfxcom-rx> in anticipation of a scenario where a
udev rule has been used to identify the USB tty device for the device.
For example, a file might be created in C</etc/udev/rules.d/91-rfxcom>
with a line like:

  SUBSYSTEM=="tty", SYSFS{idProduct}=="6001", SYSFS{idVendor}=="0403", SYSFS{serial}=="AnnnnABC", NAME="rfxcom-rx"

where the C<serial> number attribute is obtained from the output
from:

  udevinfo -a -p `udevinfo -q path -n /dev/ttyUSB0` | \
    sed -e'/ATTRS{serial}/!d;q'

=back

=cut

sub new {
  my ($pkg, %p) = @_;
  my $self = bless
    {
     device => '/dev/rfxcom-rx',
     baud => 4800,
     port => 10001,
     discard_timeout => 0.03,
     ack_timeout => 2,
     dup_timeout => 0.5,
     _q => [],
     _buf => '',
     _last_read => 0,
     %p,
    }, $pkg;
  $self->{plugins} = [$self->plugins()] unless ($self->{plugins});
  $self;
}

sub DESTROY {
  my $self = shift;
  delete $self->{init};
}

sub _write {
  my $self = shift;
  print STDERR "Queued: @_\n" if DEBUG;
  push @{$self->{_q}}, [ @_ ];
  $self->_write_now unless (exists $self->{_waiting});
  1;
}

sub _write_now {
  my $self = shift;
  my $record = shift @{$self->{_q}};
  delete $self->{_waiting};
  return unless (defined $record);
  my ($msg, $desc) = @$record;
  print STDERR "Sending: $msg $desc\n" if DEBUG;
  my $out = pack 'H*', $msg;
  syswrite $self->handle, $out, length $out;
  $self->{_waiting} = [ $self->_time_now, @$record ];
}

=head2 C<handle()>

This method returns the file handle for the device.  If the device
is not connected it initiates the connection and initialization of
the device.

=cut

sub handle {
  my $self = shift;
  unless (exists $self->{handle}) {
    $self->{handle} = $self->_open();
    $self->_init();
  }
  $self->{handle};
}

sub _open {
  my $self = shift;
  $self->{device} =~ m!/! ?
    $self->_open_serial_port(@_) : $self->_open_tcp_port(@_)
}

sub _open_tcp_port {
  my $self = shift;
  my $dev = $self->{device};
  print STDERR "Opening $dev as tcp socket\n" if DEBUG;
  require IO::Socket::INET; import IO::Socket::INET;
  $dev .= ':'.$self->{port} unless ($dev =~ /:/);
  my $fh = IO::Socket::INET->new($dev) or
    croak "TCP connect to '$dev' failed: $!";
  return $fh;
}

sub _open_serial_port {
  my $self = shift;
  my $dev = $self->{device};
  print STDERR "Opening $dev as serial port\n" if DEBUG;
  require Device::SerialPort; import Device::SerialPort;
  my $ser =
    Device::SerialPort->new($dev) or
        croak "Failed to open '$dev' with Device::SerialPort: $!";
  $ser->baudrate($self->{baud});
  $ser->databits(8);
  $ser->parity('none');
  $ser->stopbits(1);
  $ser->write_settings;
  $ser->close;
  $self->{serialport} = $ser if TESTING; # keep mock object
  undef $ser;
  sysopen my $fh, $dev, O_RDWR|O_NOCTTY|O_NDELAY
    or croak "sysopen of '$dev' failed: $!";
  $fh->autoflush(1);
  binmode($fh);
  return $fh;
}

sub _init {
  my $self = shift;
  $self->_write('F020', 'version check');
  $self->_write('F041', 'variable length with visonic');
  $self->_write('F02A', 'enable all possible receiving modes');
  $self->{init} = 1;
}

=head2 C<read($timeout)>

This method blocks until a new message has been received by the
device.  When a message is received a data structure is returned
that represents the data received.

B<IMPORTANT:> This API is still subject to change.

=cut

sub read {
  my ($self, $timeout) = @_;
  my $res = $self->read_one(\$self->{_buf});
  return $res if (defined $res);
  $self->_discard_buffer_check() if ($self->{_buf} ne '');
  $self->_discard_dup_cache_check();
  my $handle = $self->handle;
  my $sel = IO::Select->new($handle);
 REDO:
  my $start = $self->_time_now;
  $sel->can_read($timeout) or return;
  my $bytes = sysread $handle, $self->{_buf}, 2048, length $self->{_buf};
  $self->{_last_read} = $self->_time_now;
  $timeout -= $self->{_last_read} - $start if (defined $timeout);
  unless ($bytes) {
    croak defined $bytes ? 'closed' : 'error: '.$!;
  }
  $res = $self->read_one(\$self->{_buf});
  $self->_write_now() if (defined $res);
  goto REDO unless ($res);
  return $res;
}


=head2 C<read_one(\$buffer)>

This method attempts to remove a single RF message from the buffer
passed in via the scalar reference.  When a message is removed a data
structure is returned that represents the data received.  If insufficient
data is available then undef is returned.  If a duplicate message is
received then 0 is returned.

B<IMPORTANT:> This API is still subject to change.

=cut

sub read_one {
  my ($self, $rbuf) = @_;
  return unless ($$rbuf);

  print STDERR "rbuf=", (unpack "H*", $$rbuf), "\n" if DEBUG;
  my $header_byte = unpack "C", $$rbuf;
  my %result =
    (
     header_byte => $header_byte,
     type => 'unknown',
    );
  $result{master} = !($header_byte&0x80);
  my $bits = $header_byte & 0x7f;
  my $msg = '';
  my @bytes;
  if (exists $self->{_waiting} && $header_byte == 0x4d) {

    print STDERR "got version check response\n" if DEBUG;
    $msg = $$rbuf;
    substr $msg, 0, 1, '';
    $$rbuf = '';
    $result{type} = 'version';
    @bytes = unpack 'C*', $msg;

  } elsif (exists $self->{_waiting} &&
           ( $header_byte == 0x2c || $header_byte == 0x41 )) {

    print STDERR "got mode response\n" if DEBUG;
    substr $$rbuf, 0, 1, '';
    $result{type} = 'mode';

  } elsif ($bits == 0) {

    print STDERR "got empty message\n" if DEBUG;
    substr $$rbuf, 0, 1, '';
    $result{type} = 'empty';

  } else {

    my $length = $bits / 8;

    print STDERR "bits=$bits length=$length\n" if DEBUG;
    return if (length $$rbuf < 1 + $length);

    if ($length != int $length) {
      $length = 1 + int $length;
    }

    $msg = substr $$rbuf, 0, 1 + $length, ''; # message from buffer
    substr $msg, 0, 1, '';
    @bytes = unpack 'C*', $msg;

    $result{key} = $bits.'!'.$msg;
    my $entry = $self->_cache_get(\%result);
    if ($entry) {
      print STDERR "using cache entry\n" if DEBUG;
      @result{qw/messages type/} = @{$entry->{result}}{qw/messages type/};
      $self->_cache_set(\%result);
    } else {
      foreach my $decoder (@{$self->{plugins}}) {
        my $matched = $decoder->decode($self, $msg, \@bytes, $bits, \%result)
          or next;
        ($result{type} = lc ref $decoder) =~ s/.*:://;
        last;
      }
      $self->_cache_set(\%result);
    }
  }

  @result{qw/data bytes/} = ($msg, \@bytes);
  return Device::RFXCOM::Response->new(%result);
}

sub _cache_get {
  my ($self, $result) = @_;
  $self->{_cache}->{$result->{key}};
}

sub _cache_set {
  my ($self, $result) = @_;
  return if ($result->{dont_cache});
  my $entry = $self->{_cache}->{$result->{key}};
  if ($entry) {
    $result->{duplicate} = 1 if ($self->_cache_is_duplicate($entry));
    $entry->{t} = $self->_time_now;
    return $entry;
  }
  $self->{_cache}->{$result->{key}} =
    {
     result => $result,
     t => $self->_time_now,
    };
}

sub _cache_is_duplicate {
  my ($self, $entry) = @_;
  ($self->_time_now - $entry->{t}) < $self->{dup_timeout};
}

sub _discard_buffer_check {
  my $self = shift;
  if ($self->{_buf} ne '' &&
      $self->{_last_read} < ($self->_time_now - $self->{discard_timeout})) {
    $self->{_buf} = '';
  }
}

sub _discard_dup_cache_check {
  my $self = shift;
  if ($self->{_last_read} < ($self->_time_now - $self->{dup_timeout})) {
    $self->{_cache} = {};
  }
}

sub _time_now {
  Time::HiRes::time
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
