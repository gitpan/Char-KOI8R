# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{��} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.00503;
use Char::KOI8R;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
