use strict;
use warnings;
package Device::RFXCOM::TX;

# ABSTRACT: Device::RFXCOM::TX module for RFXCOM RF receiver

=head1 SYNOPSIS

  # for a USB-based device, transmitting X10 RF messages
  my $tx = Device::RFXCOM::TX->new(device => '/dev/ttyUSB0', x10 => 1);
  $tx->init;
  $tx->transmit(type => 'homeeasy', command => 'on', ...);
  $tx->wait_for_ack() while ($tx->queue);

=head1 DESCRIPTION

Module for sending RF messages with an RFXCOM transmitter.

B<IMPORTANT:> This API is still subject to change.

=cut

use 5.006;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_TX_DEBUG},
  TESTING => $ENV{DEVICE_RFXCOM_TX_TESTING},
};
use Carp qw/croak carp/;
use Fcntl;
use IO::Handle;
use IO::Select;
use Time::HiRes;
use Device::RFXCOM::Response;
use Module::Pluggable
  search_path => 'Device::RFXCOM::Encoder',
  instantiate => 'new';

=method C<new(%parameters)>

This constructor returns a new RFXCOM RF receiver object.
The only supported parameter is:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based RFXCOM receivers.

The default is C</dev/rfxcom-tx> in anticipation of a scenario where a
udev rule has been used to identify the USB tty device for the device.
For example, a file might be created in C</etc/udev/rules.d/91-rfxcom>
with a line like:

  SUBSYSTEM=="tty", SYSFS{idProduct}=="6001", SYSFS{idVendor}=="0403", SYSFS{serial}=="AnnnnABC", NAME="rfxcom-tx"

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
     device => '/dev/rfxcom-tx',
     baud => 4800,
     port => 10001,
     discard_timeout => 0.03,
     ack_timeout => 6,
     dup_timeout => 0.5,
     receiver_connected => 0,
     flamingo => 0,
     harrison => 0,
     koko => 0,
     x10 => 0,
     _q => [],
     _buf => '',
     _last_read => 0,
     %p,
    }, $pkg;
  foreach my $plugin (@{$self->{plugins} || [$self->plugins()]}) {
    my $p = lc ref $plugin;
    $p =~ s/.*:://;
    $self->{plugins}->{$p} = $plugin;
    print STDERR "Initialized plugin for $p messages\n" if DEBUG;
  }
  $self;
}

sub receiver_connected { shift->{receiver_connected} }
sub flamingo { shift->{flamingo} }
sub harrison { shift->{harrison} }
sub koko { shift->{koko} }
sub x10 { shift->{x10} }

sub DESTROY {
  my $self = shift;
  delete $self->{init};
}

sub queue {
  my $self = shift;
  scalar @{$self->{_q}};
}

sub _write {
  my $self = shift;
  my %p = @_;
  $p{raw} = pack 'H*', $p{hex} unless (exists $p{raw});
  $p{hex} = unpack 'H*', $p{raw} unless (exists $p{hex});
  print STDERR "Queued: ", $p{hex}, ' ', ($p{desc}||''), "\n" if DEBUG;
  push @{$self->{_q}}, \%p;
  $self->_write_now unless (exists $self->{_waiting});
  1;
}

sub _write_now {
  my $self = shift;
  my $rec = shift @{$self->{_q}};
  delete $self->{_waiting};
  return unless (defined $rec);
  print STDERR "Sending: ", $rec->{hex}, ' ', ($rec->{desc}||''), "\n" if DEBUG;
  syswrite $self->handle, $rec->{raw}, length $rec->{raw};
  $self->{_waiting} = [ $self->_time_now, $rec ];
}

=method C<handle()>

This method returns the file handle for the device.  If the device
is not connected it initiates the connection and initialization of
the device.

=cut

sub handle {
  my $self = shift;
  unless (exists $self->{handle}) {
    $self->{handle} = $self->_open();
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

sub init {
  my $self = shift;
  $self->_write(hex => 'F030F030', desc => 'version check');
  $self->_init_mode();
  $self->_write(hex => 'F03CF03C', desc => 'enabling harrison')
    if ($self->harrison);
  $self->_write(hex => 'F03DF03D', desc => 'enabling klikon-klikoff')
    if ($self->koko);
  $self->_write(hex => 'F03EF03E', desc => 'enabling flamingo')
    if ($self->flamingo);
  $self->_write(hex => 'F03FF03F', desc => 'disabling x10') unless ($self->x10);
  $self->{init} = 1;
}

sub _init_mode {
  my $self = shift;
  $self->_write($self->receiver_connected ?
                (hex => 'F033F033',
                 desc => 'variable length mode w/receiver connected') :
                (hex => 'F037F037',
                 desc=> 'variable length mode w/o receiver connected'));
}

sub _reset_device {
  my $self = shift;
  carp "No ack from transmitter!\n";
  $self->init_device();
  1;
}

=method C<transmit(%params)>

This method sends an RF message to the device for transmission.

=cut

sub transmit {
  my ($self, %p) = @_;
  my $type = $p{type} || 'x10';
  $self->init unless ($self->{init});
  my $plugin = $self->{plugins}->{$type} or
    croak $self, '->transmit: ', $type, ' encoding not supported';
  my $encode = $plugin->encode($self, \%p);
  if (ref $encode eq 'ARRAY') {
    foreach my $e (@$encode) {
      $self->_write(%$e);
    }
  } else {
    $self->_write(%$encode);
  }
  return 1;
}

=method C<wait_for_ack($timeout)>

This method blocks until a new message has been received by the
device.  When a message is received a data structure is returned
that represents the data received.

B<IMPORTANT:> This API is still subject to change.

=cut

sub wait_for_ack {
  my ($self, $timeout) = @_;
  $timeout = $self->{ack_timeout} unless (defined $timeout);
  my $handle = $self->handle;
  my $sel = IO::Select->new($handle);
  $sel->can_read($timeout) or return;
  my $buf;
  my $bytes = sysread $handle, $buf, 2048;
  unless ($bytes) {
    croak defined $bytes ? 'closed' : 'error: '.$!;
  }
  $self->_write_now();
  return $buf;
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
