# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{あ} ne "\x82\xa0";

use Char::KOI8R;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('ああいう' =~ /^(あいう)$/) {
    print "not ok - 1 $^X $__FILE__ not ('ああいう' =~ /^あいう\$/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('ああいう' =~ /^あいう\$/).\n";
}

__END__
