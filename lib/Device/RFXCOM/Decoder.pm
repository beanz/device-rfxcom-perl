use strict;
use warnings;
package Device::RFXCOM::Decoder;

# ABSTRACT: Device::RFXCOM::Decoder base class for decoding RF messages

=head1 SYNOPSIS

  # see Device::RFXCOM::Decorder

=head1 DESCRIPTION

Base class for RFXCOM decoder modules.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_ELECTRISAVE_DEBUG};
use Carp qw/croak/;

use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(lo_nibble hi_nibble nibble_sum) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

=head2 C<new($parent)>

This constructor returns a new decoder object.

=cut

sub new {
  my ($pkg, $parent) = @_;
  bless {}, $pkg;
}

=head2 C<lo_nibble($byte)>

This function returns the low nibble of a byte.  So, for example, given
0x16 it returns 6.

=cut

sub lo_nibble {
  $_[0]&0xf;
}

=head2 C<hi_nibble($byte)>

This function returns the hi nibble of a byte.  So, for example, given
0x16 it returns 1.

=cut

sub hi_nibble {
  ($_[0]&0xf0)>>4;
}

=head2 C<nibble_sum($count, \@nibbles)>

This function returns the sum of the nibbles of count nibbles.

=cut

sub nibble_sum {
  my $s = 0;
  foreach (0..$_[0]-1) {
    $s += $_[1]->[$_];
  }
  return $s;
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
