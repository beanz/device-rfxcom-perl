#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_RX_TEST_DEBUG}
};
use lib 't/lib';
use Test::More tests => 12;
use File::Temp qw/tempfile/;

BEGIN {
  $ENV{DEVICE_RFXCOM_TESTING} = 1;
}

my ($fh, $filename) = tempfile();
END { unlink $filename if ($filename); }

print $fh pack 'H*', '4d26414120609f08f7';

use_ok('Device::RFXCOM::RX');

my @sent;
{
  package MY::RX;
  our @ISA = qw/Device::RFXCOM::RX/;
  sub _write_now {
    my $self = shift;
    my $rec = shift @{$self->{_q}};
    delete $self->{_waiting};
    return unless (defined $rec);
    push @sent, $rec->{hex};
    $self->{_waiting} = [ $self->_time_now, $rec ];
  }
}

my $rx = MY::RX->new(device => $filename);

ok($rx, 'instantiate MY::RX object');
$fh = $rx->filehandle;
my $fd = $fh->fileno;
$rx->_termios_config($fh);
my @calls = POSIX::Termios->calls;
foreach my $exp ('POSIX::Termios::getattr '.$fd,
                 'POSIX::Termios::getlflag ',
                 'POSIX::Termios::setlflag 0',
                 'POSIX::Termios::setcflag 15',
                 'POSIX::Termios::setiflag 3',
                 'POSIX::Termios::setospeed 1',
                 'POSIX::Termios::setispeed 1',
                 'POSIX::Termios::setattr '.$fd.' 1',
                ) {
  my $got = shift @calls;
  is($got, $exp, 'POSIX calls - '.$exp);
}
is_deeply(\@sent, ['F020'], '... sent data');

# TOFIX: delay closing error until all data is consumed from buffer

#@sent = ();

#use Data::Dumper;
#print STDERR Data::Dumper->Dump([$rx->read(0.1)],[qw/read/]);

eval { MY::RX->new(device => 't/does-not-exist.dev') };
like($@, qr!^sysopen of 't/does-not-exist\.dev' failed:!, 'sysopen error');
