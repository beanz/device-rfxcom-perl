use strict;
use warnings;
package Device::RFXCOM::Response::Security;

# ABSTRACT: Device::RFXCOM::Response class for Security messages from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Security messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_SECURITY_DEBUG};
use Carp qw/croak/;

=head2 C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

sub type { 'security' }
sub device { shift->{device} }
sub event { shift->{event} }
sub tamper { shift->{tamper} }
sub min_delay { shift->{min_delay} }

sub summary {
  my $self = shift;
  $self->type.'/'.$self->device.'/'.$self->event.
    ($self->tamper ? '/tamper' : '').
    ($self->min_delay ? '/min' : '')
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
