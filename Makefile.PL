
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl modules for RFXCOM RF receivers and transmitters',
  'AUTHOR' => 'Mark Hindess <soft-cpan@temporalanomaly.com>',
  'BUILD_REQUIRES' => {
    'AnyEvent' => '0',
    'AnyEvent::Handle' => '0',
    'AnyEvent::MockTCPServer' => '0',
    'AnyEvent::Socket' => '0',
    'English' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Device-RFXCOM',
  'EXE_FILES' => [
    'bin/w800-rx',
    'bin/rfxcom-rx',
    'bin/rfxcom-tx'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Device::RFXCOM',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'Fcntl' => '0',
    'IO::Handle' => '0',
    'IO::Select' => '0',
    'IO::Socket::INET' => '0',
    'Module::Pluggable' => '0',
    'POSIX' => '0',
    'Time::HiRes' => '0',
    'constant' => '0'
  },
  'VERSION' => '1.111960',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



