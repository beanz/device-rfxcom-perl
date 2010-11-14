package Device::SerialPort;
sub new {
  my ($pkg, $dev) = @_;
  return if ($dev =~ /fail-serialport/);
  bless { calls => [] }, 'Device::SerialPort';
}
sub calls { $_[0]->{calls} }
sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  push @{$self->{calls}}, "$AUTOLOAD @_";
}
sub DESTROY {}
1;
