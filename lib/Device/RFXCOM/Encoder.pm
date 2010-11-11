use strict;
use warnings;
package Device::RFXCOM::Encoder;

# ABSTRACT: Device::RFXCOM::Encoder base class for encoding RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Base class for RFXCOM encoder modules.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_ENCODER_DEBUG};
use Carp qw/croak/;

use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

=method C<new()>

This constructor returns a new encoder object.

=cut

sub new {
  my $pkg = shift;
  bless { @_ }, $pkg;
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
