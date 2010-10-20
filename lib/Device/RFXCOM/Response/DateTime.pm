use strict;
use warnings;
package Device::RFXCOM::Response::DateTime;

# ABSTRACT: Device::RFXCOM::Response class for DateTime message from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for DateTime messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_DATETIME_DEBUG};
use Carp qw/croak/;

=head2 C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

sub type { 'datetime' }
sub device { shift->{device} }
sub date { shift->{date} }
sub time { shift->{time} }
sub day { shift->{day} }

sub summary {
  my $self = shift;
  $self->type.'/'.$self->device.'='.$self->date.' '.$self->time.' '.$self->day;
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
