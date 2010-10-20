use strict;
use warnings;
package Device::RFXCOM::Response;

# ABSTRACT: Device::RFXCOM::Response class for data from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Base class for RFXCOM response modules.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_DEBUG};
use Carp qw/croak/;

=head2 C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

=head2 C<type()>

This method returns the type of the response.  It will be one of:

=over

=item unknown

for a message that could not be decoded

=item version

for a response to a version check request

=item mode

for a response to a mode setting request

=item empty

for an empty message

=back

or it will be a string representing the type of device from which the
message originated.

=cut

sub type { shift->{type} }

=head2 C<header_byte()>

This method returns the header byte contains the length in buts and
master/slave flag for the message.

=cut

sub header_byte { shift->{header_byte} }

=head2 C<master()>

This method returns true of the message originated from the master
receiver or false of it originated from a slave receiver.

=cut

sub master { shift->{master} }

=head2 C<hex_data()>

This method returns a hex string representing the payload of the RF
message.

=cut

sub hex_data { unpack 'H*', shift->data }

=head2 C<data()>

This method returns the binary string of the payload of the RF
message.

=cut

sub data { shift->{data} }

=head2 C<length()>

This method returns the length of the payload of the RF message (in bytes).

=cut

sub length { length shift->data }

=head2 C<bytes()>

This method returns an array reference of bytes representing the
payload of the RF message.

=cut

sub bytes { shift->{bytes} }

=head2 C<messages()>

This method returns an array reference of message objects generated
from the payload.

=cut

sub messages { shift->{messages} || [] }

=head2 C<summary()>

This method returns a string summary of the contents of the RF message.
(If there are multiple message objects produced from the payload then
this may be a multiline string.)

=cut

sub summary {
  my $self = shift;
  my $str = join "\n  ", map { $_->summary } @{$self->messages};
  sprintf('%s %s %02x.%s%s',
          $self->master ? 'master' : 'slave',
          $self->type,
          $self->header_byte,
          $self->hex_data,
          $str =~ /\n/ ? ":\n  ".$str : $str ne '' ? ': '.$str : '');
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
