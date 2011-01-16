package POSIX;

use constant {
  ECHO => 0x1,
  ECHOK => 0x2,
  ICANON => 0x4,
  CS8 => 0x1,
  CREAD => 0x2,
  CLOCAL => 0x4,
  HUPCL => 0x8,
  IGNBRK => 0x1,
  IGNPAR => 0x2,
  B4800 => 0x1,
  B9600 => 0x2,
  TCSANOW => 0x1,
};

package POSIX::Termios;

my @calls = ();

sub new {
  my ($pkg, $dev) = @_;
  bless [ @_ ], 'POSIX::Termios';
}
sub calls { @calls }
sub reset_calls { @calls = () }
sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  push @calls, "$AUTOLOAD @_";
}
sub DESTROY {}
1;
