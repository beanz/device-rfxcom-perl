#!/usr/bin/perl -w
#
# Copyright (C) 2007, 2009 by Mark Hindess

use strict;
my %msg;

BEGIN {
  my $tests = 1;
  my $dir = 't/rf';
  opendir my $dh, $dir or die "Open of $dir directory: $!\n";
  local $/ = "\n\n";
  foreach (sort readdir $dh) {
    next if (!/^(.*)\.txt$/);
    my $name = $1;
    my $f = $dir.'/'.$_;
    open my $fh, '<', $f or die "Failed to open $f: $!\n";
    my ($message, $string, $warn, $rem, $flags) = <$fh>;
    chomp $message;
    $string =~ s/\n+$//;
    $warn && $warn =~ s/\n+$//;
    $rem && $rem =~ s/\n+$//;
    $flags && chomp $flags;
    $msg{$name} =
      {
       msg => $message,
       string => $string,
       warn => $warn,
       rem => $rem || '',
       flags => $flags,
      };
    $tests += 3;
    close $fh;
  }
  closedir $dh;
  require Test::More;
  import Test::More tests => $tests;
}

use_ok('Device::RFXCOM::RX');

my $rf = Device::RFXCOM::RX->new();
foreach my $m (sort keys %msg) {
  my $rec = $msg{$m};
  my $res;
  if ($rec->{flags} && $rec->{flags} =~ s/^pause//) {
    select undef, undef, undef, 1.1;
  }
  if ($rec->{flags} && $rec->{flags} =~ s/^clear//) {
    $rf->stash('unit_cache', {}); # clear unit code cache and try again
    $rf->{_cache} = {}; # clear duplicate cache to avoid hitting it
  }

  my $buf = pack "H*", $rec->{msg}.'deadbeef';
  my $w = test_warn( sub { $res = $rf->read_one(\$buf); });
  $res->{data} = unpack 'H*', $res->{data} if ($res && defined $res->{data});
  is((unpack 'H*', $buf), $rec->{rem}.'deadbeef', $m.' - buffer remaining');

  is($w || "none\n", $rec->{warn} ? $rec->{warn}."\n" : "none\n",
     $m.' - test warning');

  my $expected;
  eval $rec->{string};
  is_deeply($res, $expected, $m.' - correct messages');
}

sub test_warn {
  my $sub = shift;
  my $warn;
  local $SIG{__WARN__} = sub { $warn .= $_[0]; };
  eval { $sub->(); };
  die $@ if ($@);
  if ($warn) {
    $warn =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $warn =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $warn =~ s/ \(\@INC contains:.*?\)$//;
  }
  return $warn;
}
