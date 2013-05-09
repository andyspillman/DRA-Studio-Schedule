use strict;
use warnings;

use Perl::Tidy;

perltidy(
    source=>"$ARGV[0]",
    destination=>"$ARGV[1]",
    );
