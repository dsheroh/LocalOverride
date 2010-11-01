#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

my %fallthrough;
push @INC, sub { $fallthrough{$_[1]}++; open my $fh, '<', \'1'; return $fh; };

# Can we load the module?
use_ok 'LocalOverride';

# Verify correct modules are loaded in base case
{
    %fallthrough = ();
    require req::Foo;
    is_deeply(\%fallthrough, {
        'Local/req/Foo.pm'   => 1,
        'req/Foo.pm'         => 1,
    }, 'Foo and Local/Foo required');

    eval "use use::Foo";
    is_deeply(\%fallthrough, {
        'Local/req/Foo.pm'   => 1,
        'Local/use/Foo.pm'   => 1,
        'req/Foo.pm'         => 1,
        'use/Foo.pm'         => 1,
    }, 'Foo and Local/Foo used');
}

done_testing;
