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
  import Test::More tests => 27;
}

my @connections =
  (
   [
    '609f08',
    '',
    'f7',
    '609f08f7',
    '',
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
  unless (scalar @$actions) {
    print STDERR "closing connection\n" if DEBUG;
    return $handle->push_shutdown;
  }
  my $send = shift @$actions;
  unless ($send) {
    # pause to permit read to happen
    my $w; $w = AnyEvent->timer(after => 0.3, cb => sub {
                                  handle_connection($handle, $actions);
                                  undef $w;
                                });
    return;
  }
  print STDERR "Sending: ", $send, "\n" if DEBUG;
  $send = pack "H*", $send;
  print STDERR "Sending ", length $send, " bytes\n" if DEBUG;
  $handle->push_write($send);
  handle_connection($handle, $actions);
  return;
}

my $addr = $cv->recv;
$addr = $addr->[0].':'.$addr->[1];

use_ok('Device::W800');

my $w800 = Device::W800->new(device => $addr,
                             discard_timeout => 0.4);

ok($w800, 'instantiate Device::W800 object');

my $res;
my $w = AnyEvent->io(fh => $w800->fh, poll => 'r',
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
