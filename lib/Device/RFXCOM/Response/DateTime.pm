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

=method C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

=method C<type()>

This method returns 'datetime'.

=cut

sub type { 'datetime' }

=method C<device()>

This method returns a string representing the name of the device that
sent the date and time data.

=cut

sub device { shift->{device} }

=method C<date()>

This method returns a string of the form 'YYYYMMDD' representing the
date from the date and time RF message.

=cut

sub date { shift->{date} }

=method C<time()>

This method returns a string of the form 'HHMMSS' representing the
time from the date and time RF message.

=cut

sub time { shift->{time} }

=method C<day()>

This method returns the day (in English) from the date and time RF
message.  It is probably best to avoid using this and calculate the
correct value for the locale from the other data.

=cut

sub day { shift->{day} }

=method C<summary()>

This method returns a string summary of the date and time information.

=cut

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
