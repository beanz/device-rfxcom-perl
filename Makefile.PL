
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.019.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl modules for RFXCOM RF receivers and transmitters",
  "AUTHOR" => "Mark Hindess <soft-cpan\@temporalanomaly.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Device-RFXCOM",
  "EXE_FILES" => [
    "bin/rfxcom-tx",
    "bin/w800-rx",
    "bin/rfxcom-rx"
  ],
  "LICENSE" => "perl",
  "NAME" => "Device::RFXCOM",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Device::SerialPort" => 0,
    "Exporter" => 0,
    "Fcntl" => 0,
    "IO::Handle" => 0,
    "IO::Select" => 0,
    "IO::Socket::INET" => 0,
    "Module::Pluggable" => 0,
    "Symbol" => 0,
    "Time::HiRes" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::MockTCPServer" => 0,
    "AnyEvent::Socket" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "1.142010",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent" => 0,
  "AnyEvent::Handle" => 0,
  "AnyEvent::MockTCPServer" => 0,
  "AnyEvent::Socket" => 0,
  "Carp" => 0,
  "Device::SerialPort" => 0,
  "Exporter" => 0,
  "Fcntl" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IO::Select" => 0,
  "IO::Socket::INET" => 0,
  "Module::Pluggable" => 0,
  "Symbol" => 0,
  "Test::More" => 0,
  "Time::HiRes" => 0,
  "base" => 0,
  "constant" => 0,
  "lib" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



