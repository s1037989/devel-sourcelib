package Devel::SourceLib;

use List::MoreUtils 'uniq';

BEGIN {
  use Mojo::File 'path';
  use constant DEBUG => $ENV{DEVEL_SOURCELIB_DEBUG} || 0;
  our @BINPATH = split /:/, $ENV{PATH};
  return unless $ENV{DEVEL_SOURCELIB};
  warn "DEVEL_SOURCELIB=$ENV{DEVEL_SOURCELIB}\n" if DEBUG;
  if ( $ENV{DEVEL_SOURCELIB_OVERRIDE_USE} ) {
    *CORE::GLOBAL::use = sub {
      my $module = shift;
      for ( reverse split /:/, $ENV{DEVEL_SOURCELIB} ) {
        path($_)->list({dir=>1})->each(sub{
          my $path = $_->child('lib', split /::/, "$module.pm")->to_string;
          next unless -e $path && -f _;
          my $libdir = $_->child('lib')->to_string;
          unshift @INC, $libdir and DEBUG and warn "Adding: $libdir\n"
            unless grep { $_ eq $libdir } @INC;
          require $module;
          $module->import(@_);
        })->each(sub{;
          my $bindir = $_->child('bin')->to_string;
          next unless -e $bindir && -d _;
          next if grep { $_ eq $bindir } @BINPATH;
          warn "Adding: $bindir\n" if DEBUG;
          unshift @BINPATH, $bindir;
        });
      }
    };
  } else {
    for ( reverse split /:/, $ENV{DEVEL_SOURCELIB} ) {
      path($_)->list({dir=>1})->each(sub{
        my $libdir = $_->child('lib')->to_string;
        next unless -e $libdir && -d _;
        next if grep { $_ eq $libdir } @INC;
        warn "Adding: $libdir\n" if DEBUG;
        unshift @INC, $libdir;
      })->each(sub{;
        my $bindir = $_->child('bin')->to_string;
        next unless -e $bindir && -d _;
        next if grep { $_ eq $bindir } @BINPATH;
        warn "Adding: $bindir\n" if DEBUG;
        unshift @BINPATH, $bindir;
      });
    }
  }
  @INC = uniq @INC;
  #$ENV{PERL5LIB}=join ':', @INC;
  warn join "\n", '@INC:', (map{"  $_"}@INC), '' if DEBUG > 1;
}

sub perl5lib { printf "%s\n", join ':', @INC }

sub binpath { printf "%s\n", join ':', @BINPATH }

1;
