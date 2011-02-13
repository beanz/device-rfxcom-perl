#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use warnings;
use constant {
  DEBUG => $ENV{DEVICE_W800_TEST_DEBUG}
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
  import Test::More;
  use t::Helpers qw/:all/;
}

my @connections =
  (
   [
    {
     desc => 'partial message',
     send => '609f08',
    },
    {
     desc => 'sleep 1',
     sleep => 0.3,
    },
    {
     desc => 'rest of message',
     send => 'f7',
    },
    {
     desc => 'complete message',
     send => '609f08f7',
    },
    {
     desc => 'sleep 2',
     sleep => 0.3,
    },
   ],
  );

my $cv = AnyEvent->condvar;
my $server;
eval { $server = test_server($cv, @connections) };
plan skip_all => "Failed to create dummy server: $@" if ($@);

my $addr = $cv->recv;
$addr = $addr->[0].':'.$addr->[1];

import Test::More tests => 27;

use_ok('Device::W800');

my $w800 = Device::W800->new(device => $addr,
                             discard_timeout => 0.4);

ok($w800, 'instantiate Device::W800 object');

my $res;
my $w = AnyEvent->io(fh => $w800->filehandle, poll => 'r',
                     cb => sub { $cv->send($w800->read(0.1)) });
$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res, undef, 'timeout');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res->type, 'x10', 'got x10 message');
is($res->header_byte, 0x20, '... correct header_byte');
ok($res->master, '... from master receiver');
is($res->length, 4, '... correct data length');
is($res->hex_data, '609f08f7', '... correct data');
is($res->summary,
   'master x10 20.609f08f7: x10/a3/on',
   '... correct summary string');

is(scalar @{$res->messages}, 1, '... correct number of messages');
my $message = $res->messages->[0];
is($message->type, 'x10', '... correct message type');
is($message->command, 'on', '... correct message command');
is($message->device, 'a3', '... correct message device');

$cv = AnyEvent->condvar;
$res = $cv->recv;
ok($res->duplicate, '... received a duplicate');
is($res->type, 'x10', 'got x10 message');
is($res->header_byte, 0x20, '... correct header_byte');
ok($res->master, '... from master receiver');
is($res->length, 4, '... correct data length');
is($res->hex_data, '609f08f7', '... correct data');
is($res->summary,
   'master x10 20.609f08f7(dup): x10/a3/on',
   '... correct summary string');

is(scalar @{$res->messages}, 1, '... correct number of messages');
$message = $res->messages->[0];
is($message->type, 'x10', '... correct message type');
is($message->command, 'on', '... correct message command');
is($message->device, 'a3', '... correct message device');

undef $server;

SKIP: {
  skip 'fails with some event loops', 1
    unless ($AnyEvent::MODEL eq 'AnyEvent::Impl::Perl');
  $cv = AnyEvent->condvar;
  eval { $res = $cv->recv; };
  like($@, qr!^closed at \Q$0\E line \d+$!, 'close');
}

eval { $w800->_write('BEEF'); };
like($@, qr!^Writes not supported for W800!, 'write unsupported');

undef $w800;
undef $w;

eval { Device::W800->new(device => $addr) };
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o, 'connection failed');
