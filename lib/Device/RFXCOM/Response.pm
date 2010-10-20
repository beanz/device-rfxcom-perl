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

sub type { shift->{type} }
sub header_byte { shift->{header_byte} }
sub master { shift->{master} }
sub hex_data { unpack 'H*', shift->data }
sub data { shift->{data} }
sub length { length shift->data }
sub bytes { shift->{bytes} }
sub messages { shift->{messages} || [] }

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
