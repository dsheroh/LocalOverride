package LocalOverride;

use strict;
use warnings;

use PerlIO::scalar;

our $VERSION = 0.900000;

our $base_namespace = '';
our $core_only      = 0;
our $local_prefix   = 'Local';

BEGIN { unshift @INC, \&require_local }

my %already_seen;

sub require_local {
    # Exit immediately if we're not processing overrides
    return if $core_only;

    my (undef, $filename) = @_;

    # Keep track of what files we've already seen to avoid infinite loops
    return if exists $already_seen{$filename};
    $already_seen{$filename}++;

    # We only want to check overrides in $base_namespace
    return unless $filename =~ /^$base_namespace/;

    # OK, that all passed, so we can load up the actual files
    # Get the original version first, then overlay the local version
    require $filename;

    my $local_file = $filename;
    if ($base_namespace) {
        $local_file =~ s[^$base_namespace][${base_namespace}/$local_prefix];
    } else {
        # Empty base namespace is probably a bad idea, but it should be
        # handled anyhow
        $local_file = $local_prefix . '/' . $local_file;
    }
    $already_seen{$local_file}++;
    # Failure to load local version is not fatal, since it may not exist
    eval { require $local_file };

    open my $fh, '<', \'1';
    return $fh;
}

sub import {
    my (undef, %opts) = @_;

    if ($opts{base_namespace}) {
        $base_namespace = $opts{base_namespace};
        delete $opts{base_namespace};
    }

    if ($opts{core_only}) {
        $core_only = $opts{core_only};
        delete $opts{core_only};
    }

    if ($opts{local_prefix}) {
        $local_prefix = $opts{local_prefix};
        delete $opts{local_prefix};
    }

    warn "LocalOverride loaded with unrecognized option $_\n" for keys %opts;
}

sub unimport {
    @INC = grep { !(ref $_ && $_ == \&require_local) } @INC;
}

1;

__END__

# ABSTRACT: Transparently override subs with those in local module versions

=head1 SYNOPSIS

  use LocalOverride;

  # Load Foo, followed by Local::Foo
  use Foo;

=head1 DESCRIPTION

When this module is loaded and you C<use> or C<require> another module, it
will automatically check for whether any local modules are present which
override code from the module being loaded.  By default, these override
modules are placed in the file system at a location corresponding to
C<Local::[original module name]>, however their code should be within the
same package as the original module:

  In /path/to/libs/Foo.pm:

  package Foo;
  
  sub bar { ... }
  sub baz { ... }


  In /path/to/libs/Local/Foo.pm:

  package Foo;     # Not Local::Foo!
  
  sub bar { ... }  # Replaces the original sub Foo::bar

This is, obviously, a very extreme approach and one which should be used
only after due consideration, as it can create bugs which are very difficult
to debug if not used carefully.

If warnings are enabled, this will generate warnings about any redefined
subroutines.  You will typically want to include

  no warnings 'redefine';

in your override modules to prevent this.

=head1 CONFIGURATION

The following configuration settings can be used to enable/disable loading of
local override modules or customize where they are located.

Note that, because C<use> is processed at compile-time, any changes to these
settings must be made within a C<BEGIN> block if they are intended to affect
modules that you C<use>.  This is not necessary for modules you C<require>,
as C<require> is processed within the normal flow of the program.

=head2 base_namespace

B<Default:> ''

Local overrides will only be loaded for modules which fall within the base
namespace.  For example, if C<$base_namespace> is set to 'Foo', then an
override module will be loaded for C<Foo::Bar>, but not for C<Bar> or C<CGI>.

If C<$base_namespace> is set, overrides will be searched for within that
namespace, such as C<Foo::Local::Bar> (I<not> C<Local::Foo::Bar>) in the
previous paragraph's example case.

The default setting, an empty string, will attempt to load local overrides
for I<all> modules.  Setting C<$base_namespace> is recommended in order to
avoid this.

=head2 core_only

B<Default:> 0

If this is set to a true value, then local override processing will be
disabled.

=head2 local_prefix

B<Default:> 'Local'

The local prefix defines the namespace (within C<$base_namespace>) used for
local override definitions.  If you want them to be under C<Plugin> rather
than C<Local>, then setting

  $LocalOverride::local_prefix = 'Plugin';

will do this.

