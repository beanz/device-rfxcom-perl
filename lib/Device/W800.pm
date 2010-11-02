use strict;
use warnings;
package Device::W800;

# ABSTRACT: Device::W800 module for W800 RF receiver

=head1 SYNOPSIS

  # for a USB-based device
  my $rx = Device::W800->new(device => '/dev/ttyUSB0');

  $|=1; # don't buffer output

  # simple interface to read received data
  while (my $data = $rx->read($timeout)) {
    print $data->summary,"\n";
  }

  # for a networked device
  my $rx = Device::W800->new(device => '10.0.0.1:10001');

=head1 DESCRIPTION

Module for reading data from an W800 RF receiver from WGL & Associates.

B<IMPORTANT:> This API is still subject to change.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_W800_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::RX';
use Device::RFXCOM::Response;

=head2 C<new(%parameters)>

This constructor returns a new W800 RF receiver object.
The only supported parameter is:

=over

=item device

The name of the device to connect to.  The value can be a tty device
name or a C<hostname:port> for TCP-based serial port redirection.

The default is C</dev/w800> in anticipation of a scenario where a
udev rule has been used to identify the USB tty device for the device.

=back

=cut

sub new {
  my ($pkg, %p) = @_;
  $pkg->SUPER::new(device => '/dev/w800', %p);
}

sub _write {
  croak "Writes not supported for W800: @_\n";
}

sub _write_now {
  # do nothing
}

sub _init {
  my $self = shift;
  $self->{init} = 1;
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
  my $bits = 32;
  my $length = 4;
  my %result =
    (
     master => 1,
     header_byte => $bits,
     type => 'unknown',
    );
  my $msg = '';
  my @bytes;

  return if (length $$rbuf < $length);

  $msg = substr $$rbuf, 0, $length, ''; # message from buffer
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

  @result{qw/data bytes/} = ($msg, \@bytes);
  return Device::RFXCOM::Response->new(%result);
}

1;

=head1 SEE ALSO

L<Device::RFXCOM::RX>

W800 website: http://www.wgldesigns.com/w800.html
