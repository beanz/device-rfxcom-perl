#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_RX_TEST_DEBUG}
};

$|=1;

BEGIN {
  require Test::More;
  eval { require AnyEvent; import AnyEvent;
         require AnyEvent::Handle; import AnyEvent::Handle;
         require AnyEvent::Socket; import AnyEvent::Socket };
  if ($@) {
    import Test::More skip_all => 'No AnyEvent::Socket module installed: $@';
  }
  import Test::More tests => 12;
}

my @connections =
  (
   [
    'F020' => '4d26',
    'F041' => '41',
    'F02A' => '41',
    '' => '20649b08f7',
    '' => '80',
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

my $addr = $cv->recv;
$addr = $addr->[0].':'.$addr->[1];

use_ok('Device::RFXCOM::RX');

my $rx = Device::RFXCOM::RX->new(device => $addr);

ok($rx, 'instantiate Device::RFXCOM::RX object');

$rx->handle(); # hack to kick start init before there is anything to read

$cv = AnyEvent->condvar;
my $res;
my $w = AnyEvent->io(fh => $rx->handle, poll => 'r',
                     cb => sub { $cv->send($rx->read()) });
$res = $cv->recv;
is_deeply($res, { type => 'version', header_byte => 0x4d, bytes => [0x26],
                  master => 1, data => chr(38), },
         'version check reply');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is_deeply($res, { type => 'mode', header_byte => 0x41, bytes => [],
                  master => 1, data => '', },
         'mode set reply');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is_deeply($res, { type => 'mode', header_byte => 0x41, bytes => [],
                  master => 1, data => '', },
         'receiving option reply');

$cv = AnyEvent->condvar;
$res = $cv->recv;
my $data = pack 'H*', '649b08f7';
is_deeply($res, { type => 'x10', header_byte => 0x20,
                  bytes => [unpack 'C*', $data],
                  master => 1, data => $data,
                  'messages' =>
                  [
                   {
                    'schema' => 'x10.basic',
                    'body' => {'command' => 'on', 'device' => 'a11', },
                   }
                  ],
                },
          'simple data message');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is_deeply($res, { type => 'empty', header_byte => 0x80,
                  bytes => [],
                  master => '', data => '', },
          'empty slave message');

undef $server;

$rx = Device::RFXCOM::RX->new(device => $addr);
ok($rx, 'instantiate Device::RFXCOM::RX object');
eval { $rx->handle() }; # hack to kick start init
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o, 'connection failed');

#use Data::Dumper; print Data::Dumper->Dump([$res],[qw/res/]);exit;
