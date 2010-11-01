package LocalOverride;

use strict;
use warnings;

use PerlIO::scalar;

our $VERSION = 0.001000;

our $base_namespace = '';
our $core_only = 0;
our $local_prefix = 'Local';

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

1;

__END__

# ABSTRACT: Transparently override subs with those in local module versions

