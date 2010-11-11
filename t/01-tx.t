#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_TX_TEST_DEBUG}
};

$|=1;

BEGIN {
  require Test::More;
  eval { require AnyEvent; import AnyEvent;
         require AnyEvent::Handle; import AnyEvent::Handle;
         require AnyEvent::Socket; import AnyEvent::Socket };
  if ($@) {
    import Test::More skip_all => 'Missing AnyEvent module(s): '.$@;
  }
  import Test::More tests => 16;
}

my @connections =
  (
   [
    'F030F030' => '10',
    'F037F037' => '37',
    'F03FF03F' => '37',
    '20E41B30CF' => '37',
    '2101D5EA0A00' => '37',
   ],

  );
my $cv = AnyEvent->condvar;
my $server = tcp_server undef, undef, sub {
  my ($fh, $host, $port) = @_;
  print STDERR "In server\n" if DEBUG;
  my $handle;
  $handle = AnyEvent::Handle->new(fh => $fh,
                                  on_error => sub {
                                    warn "error $_[2]\n";
                                    $_[0]->destroy;
                                  },
                                  on_eof => sub {
                                    $handle->destroy; # destroy handle
                                    warn "done.\n";
                                  },
                                  timeout => 1,
                                  on_timeout => sub {
                                    die "server timeout\n";
                                  }
                                 );
  my $actions = shift @connections;
  unless ($actions && @$actions) {
    die "Server received unexpected connection\n";
  }
  handle_connection($handle, $actions);
}, sub {
  my ($fh, $host, $port) = @_;
  $cv->send([$host, $port]);
};

sub handle_connection {
  my ($handle, $actions) = @_;
  print STDERR "In handle connection ", scalar @$actions, "\n" if DEBUG;
  my ($recv, $send) = splice @$actions, 0, 2, ()
    or do {
      print STDERR "closing connection\n" if DEBUG;
      return $handle->push_shutdown;
    };
  if ($recv eq '') {
    print STDERR "Sending: ", $send if DEBUG;
    $send = pack "H*", $send;
    print STDERR "Sending ", length $send, " bytes\n" if DEBUG;
    $handle->push_write($send);
    handle_connection($handle, $actions);
    return;
  }
  my $expect = $recv;
  print STDERR "Waiting for ", $recv, "\n" if DEBUG;
  my $len = .5*length $recv;
  print STDERR "Waiting for ", $len, " bytes\n" if DEBUG;
  $handle->push_read(chunk => $len,
                     sub {
                       print STDERR "In receive handler\n" if DEBUG;
                       my $got = uc unpack 'H*', $_[1];
                       is($got, $expect,
                          '... correct message received by server');
                       print STDERR "Sending: ", $send, "\n" if DEBUG;
                       $send = pack "H*", $send;
                       print STDERR "Sending ", length $send, " bytes\n"
                         if DEBUG;
                       $handle->push_write($send);
                       handle_connection($handle, $actions);
                       1;
                     });
}

my ($host,$port) = @{$cv->recv};
my $addr = join ':', $host, $port;

use_ok('Device::RFXCOM::TX');

my $tx = Device::RFXCOM::TX->new(device => $addr);

ok($tx, 'instantiate Device::RFXCOM::TX object');

$tx->init(); # hack to kick start init before there is anything to read

$cv = AnyEvent->condvar;
my $res;
my $w = AnyEvent->io(fh => $tx->handle, poll => 'r',
                     cb => sub { $cv->send($tx->wait_for_ack()) });
$res = $cv->recv;
is($res, chr(0x10), 'got version check response');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res, chr(0x37), 'got 1st mode acknowledgement');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res, chr(0x37), 'got 2nd mode acknowledgement');

$cv = AnyEvent->condvar;
$tx->transmit(type => 'x10', command => 'off', device => 'i10');
$res = $cv->recv;
is($res, chr(0x37), 'got x10 acknowledgement');

$cv = AnyEvent->condvar;
$tx->transmit(type => 'homeeasy', command => 'off',
              address => 'xmas', unit => 10);
$res = $cv->recv;
undef $res;
undef $server;

$cv = AnyEvent->condvar;
eval { $res = $cv->recv; };
like($@, qr!^closed at \Q$0\E line \d+$!, 'check close');

undef $tx;
undef $w;

$tx = Device::RFXCOM::TX->new(device => $addr);
ok($tx, 'instantiate Device::RFXCOM::TX object');
eval { $tx->handle() }; # hack to kick start init
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o, 'connection failed');

undef $tx;

$tx = Device::RFXCOM::TX->new(device => $host, port => $port);
ok($tx, 'instantiate Device::RFXCOM::TX object');
eval { $tx->handle() }; # hack to kick start init
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o,
     'connection failed (default port)');

undef $tx;
