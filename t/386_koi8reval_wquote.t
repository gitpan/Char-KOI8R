# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{��} ne "\x82\xa0";

use Char::KOI8R;

print "1..12\n";

# Char::KOI8R::eval "..." has Char::KOI8R::eval "..."
if (Char::KOI8R::eval " Char::KOI8R::eval \" if ('��' =~ /[��]/i) { return 1 } else { return 0 } \" ") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has Char::KOI8R::eval qq{...}
if (Char::KOI8R::eval " Char::KOI8R::eval qq{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } } ") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has Char::KOI8R::eval '...'
if (Char::KOI8R::eval " Char::KOI8R::eval ' if (qq{��} =~ /[��]/i) { return 1 } else { return 0 } ' ") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has Char::KOI8R::eval q{...}
if (Char::KOI8R::eval " Char::KOI8R::eval q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } } ") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has Char::KOI8R::eval $var
my $var = q{q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }};
if (Char::KOI8R::eval " Char::KOI8R::eval $var ") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has Char::KOI8R::eval (omit)
$_ = "if ('��' =~ /[��]/i) { return 1 } else { return 0 }";
if (Char::KOI8R::eval " Char::KOI8R::eval ") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has Char::KOI8R::eval {...}
if (Char::KOI8R::eval " Char::KOI8R::eval { if ('��' =~ /[��]/i) { return 1 } else { return 0 } } ") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has "..."
if (Char::KOI8R::eval " if ('��' =~ /[��]/i) { return \"1\" } else { return \"0\" } ") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has qq{...}
if (Char::KOI8R::eval " if ('��' =~ /[��]/i) { return qq{1} } else { return qq{0} } ") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has '...'
if (Char::KOI8R::eval " if ('��' =~ /[��]/i) { return '1' } else { return '0' } ") {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has q{...}
if (Char::KOI8R::eval " if ('��' =~ /[��]/i) { return q{1} } else { return q{0} } ") {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Char::KOI8R::eval "..." has $var
my $var1 = 1;
my $var0 = 0;
if (Char::KOI8R::eval " if ('��' =~ /[��]/i) { return $var1 } else { return $var0 } ") {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
