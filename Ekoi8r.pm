package Ekoi8r;
######################################################################
#
# Ekoi8r - Run-time routines for KOI8R.pm
#
# Copyright (c) 2008, 2009, 2010, 2011, 2012 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use 5.00503;

BEGIN {
    if ($^X =~ m/ jperl /oxmsi) {
        die __FILE__, ": needs perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
    if (ord('A') == 193) {
        die __FILE__, ": is not US-ASCII script (may be EBCDIC or EBCDIK script).";
    }
    if (ord('A') != 0x41) {
        die __FILE__, ": is not US-ASCII script (must be US-ASCII script).";
    }
}

# 12.3. Delaying use Until Runtime
# in Chapter 12. Packages, Libraries, and Modules
# of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
# (and so on)

BEGIN { eval q{ use vars qw($VERSION) } }
$VERSION = sprintf '%d.%02d', q$Revision: 0.81 $ =~ m/(\d+)/xmsg;

BEGIN {
    my $PERL5LIB = __FILE__;

    # DOS-like system
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        $PERL5LIB =~ s{[^/]*$}{KOI8R};
    }

    # UNIX-like system
    else {
        $PERL5LIB =~ s{[^/]*$}{KOI8R};
    }

    my @inc = ();
    my %inc = ();
    for my $path ($PERL5LIB, @INC) {
        if (not exists $inc{$path}) {
            push @inc, $path;
            $inc{$path} = 1;
        }
    }
    @INC = @inc;
}

BEGIN {

    # instead of utf8.pm
    eval q{
        no warnings qw(redefine);
        *utf8::upgrade   = sub { CORE::length $_[0] };
        *utf8::downgrade = sub { 1 };
        *utf8::encode    = sub {   };
        *utf8::decode    = sub { 1 };
        *utf8::is_utf8   = sub {   };
        *utf8::valid     = sub { 1 };
    };
    if ($@) {
        *utf8::upgrade   = sub { CORE::length $_[0] };
        *utf8::downgrade = sub { 1 };
        *utf8::encode    = sub {   };
        *utf8::decode    = sub { 1 };
        *utf8::is_utf8   = sub {   };
        *utf8::valid     = sub { 1 };
    }
}

# poor Symbol.pm - substitute of real Symbol.pm
BEGIN {
    my $genpkg = "Symbol::";
    my $genseq = 0;

    sub gensym () {
        my $name = "GEN" . $genseq++;

        # here, no strict qw(refs); if strict.pm exists

        my $ref = \*{$genpkg . $name};
        delete $$genpkg{$name};
        $ref;
    }

    sub qualify ($;$) {
        my ($name) = @_;
        if (!ref($name) && (Ekoi8r::index($name, '::') == -1) && (Ekoi8r::index($name, "'") == -1)) {
            my $pkg;
            my %global = map {$_ => 1} qw(ARGV ARGVOUT ENV INC SIG STDERR STDIN STDOUT);

            # Global names: special character, "^xyz", or other.
            if ($name =~ /^(([^a-z])|(\^[a-z_]+))\z/i || $global{$name}) {
                # RGS 2001-11-05 : translate leading ^X to control-char
                $name =~ s/^\^([a-z_])/'qq(\c'.$1.')'/eei;
                $pkg = "main";
            }
            else {
                $pkg = (@_ > 1) ? $_[1] : caller;
            }
            $name = $pkg . "::" . $name;
        }
        $name;
    }

    sub qualify_to_ref ($;$) {

        # here, no strict qw(refs); if strict.pm exists

        return \*{ qualify $_[0], @_ > 1 ? $_[1] : caller };
    }
}

# use strict; if strict.pm exists
BEGIN {
    if (eval {CORE::require strict}) {
        strict::->import;
    }
}

# P.714 29.2.39. flock
# in Chapter 29: Functions
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.863 flock
# in Chapter 27: Functions
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

sub LOCK_SH() {1}
sub LOCK_EX() {2}
sub LOCK_UN() {8}
sub LOCK_NB() {4}

# instead of Carp.pm
sub carp(@);
sub croak(@);
sub cluck(@);
sub confess(@);

my $your_char = q{[\x00-\xFF]};

# regexp of character
my $q_char = qr/$your_char/oxms;

#
# KOI8-R character range per length
#
my %range_tr = ();
my $is_shiftjis_family = 0;
my $is_eucjp_family    = 0;

#
# alias of encoding name
#
BEGIN { eval q{ use vars qw($encoding_alias) } }

#
# KOI8-R case conversion
#
my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
my %fc = ();
@fc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

if (0) {
}

elsif (__PACKAGE__ =~ m/ \b Ekoi8r \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0xFF],
             ],
    );
    $encoding_alias = qr/ \b (?: koi8-?r ) \b /oxmsi;

    %lc = (%lc,
        "\xB3" => "\xA3",     # CYRILLIC LETTER IO
        "\xE0" => "\xC0",     # CYRILLIC LETTER IU
        "\xE1" => "\xC1",     # CYRILLIC LETTER A
        "\xE2" => "\xC2",     # CYRILLIC LETTER BE
        "\xE3" => "\xC3",     # CYRILLIC LETTER TSE
        "\xE4" => "\xC4",     # CYRILLIC LETTER DE
        "\xE5" => "\xC5",     # CYRILLIC LETTER IE
        "\xE6" => "\xC6",     # CYRILLIC LETTER EF
        "\xE7" => "\xC7",     # CYRILLIC LETTER GE
        "\xE8" => "\xC8",     # CYRILLIC LETTER KHA
        "\xE9" => "\xC9",     # CYRILLIC LETTER II
        "\xEA" => "\xCA",     # CYRILLIC LETTER SHORT II
        "\xEB" => "\xCB",     # CYRILLIC LETTER KA
        "\xEC" => "\xCC",     # CYRILLIC LETTER EL
        "\xED" => "\xCD",     # CYRILLIC LETTER EM
        "\xEE" => "\xCE",     # CYRILLIC LETTER EN
        "\xEF" => "\xCF",     # CYRILLIC LETTER O
        "\xF0" => "\xD0",     # CYRILLIC LETTER PE
        "\xF1" => "\xD1",     # CYRILLIC LETTER IA
        "\xF2" => "\xD2",     # CYRILLIC LETTER ER
        "\xF3" => "\xD3",     # CYRILLIC LETTER ES
        "\xF4" => "\xD4",     # CYRILLIC LETTER TE
        "\xF5" => "\xD5",     # CYRILLIC LETTER U
        "\xF6" => "\xD6",     # CYRILLIC LETTER ZHE
        "\xF7" => "\xD7",     # CYRILLIC LETTER VE
        "\xF8" => "\xD8",     # CYRILLIC LETTER SOFT SIGN
        "\xF9" => "\xD9",     # CYRILLIC LETTER YERI
        "\xFA" => "\xDA",     # CYRILLIC LETTER ZE
        "\xFB" => "\xDB",     # CYRILLIC LETTER SHA
        "\xFC" => "\xDC",     # CYRILLIC LETTER REVERSED E
        "\xFD" => "\xDD",     # CYRILLIC LETTER SHCHA
        "\xFE" => "\xDE",     # CYRILLIC LETTER CHE
        "\xFF" => "\xDF",     # CYRILLIC LETTER HARD SIGN
    );

    %uc = (%uc,
        "\xA3" => "\xB3",     # CYRILLIC LETTER IO
        "\xC0" => "\xE0",     # CYRILLIC LETTER IU
        "\xC1" => "\xE1",     # CYRILLIC LETTER A
        "\xC2" => "\xE2",     # CYRILLIC LETTER BE
        "\xC3" => "\xE3",     # CYRILLIC LETTER TSE
        "\xC4" => "\xE4",     # CYRILLIC LETTER DE
        "\xC5" => "\xE5",     # CYRILLIC LETTER IE
        "\xC6" => "\xE6",     # CYRILLIC LETTER EF
        "\xC7" => "\xE7",     # CYRILLIC LETTER GE
        "\xC8" => "\xE8",     # CYRILLIC LETTER KHA
        "\xC9" => "\xE9",     # CYRILLIC LETTER II
        "\xCA" => "\xEA",     # CYRILLIC LETTER SHORT II
        "\xCB" => "\xEB",     # CYRILLIC LETTER KA
        "\xCC" => "\xEC",     # CYRILLIC LETTER EL
        "\xCD" => "\xED",     # CYRILLIC LETTER EM
        "\xCE" => "\xEE",     # CYRILLIC LETTER EN
        "\xCF" => "\xEF",     # CYRILLIC LETTER O
        "\xD0" => "\xF0",     # CYRILLIC LETTER PE
        "\xD1" => "\xF1",     # CYRILLIC LETTER IA
        "\xD2" => "\xF2",     # CYRILLIC LETTER ER
        "\xD3" => "\xF3",     # CYRILLIC LETTER ES
        "\xD4" => "\xF4",     # CYRILLIC LETTER TE
        "\xD5" => "\xF5",     # CYRILLIC LETTER U
        "\xD6" => "\xF6",     # CYRILLIC LETTER ZHE
        "\xD7" => "\xF7",     # CYRILLIC LETTER VE
        "\xD8" => "\xF8",     # CYRILLIC LETTER SOFT SIGN
        "\xD9" => "\xF9",     # CYRILLIC LETTER YERI
        "\xDA" => "\xFA",     # CYRILLIC LETTER ZE
        "\xDB" => "\xFB",     # CYRILLIC LETTER SHA
        "\xDC" => "\xFC",     # CYRILLIC LETTER REVERSED E
        "\xDD" => "\xFD",     # CYRILLIC LETTER SHCHA
        "\xDE" => "\xFE",     # CYRILLIC LETTER CHE
        "\xDF" => "\xFF",     # CYRILLIC LETTER HARD SIGN
    );

    %fc = (%fc,
        "\xB3" => "\xA3",     # CYRILLIC CAPITAL LETTER IO --> CYRILLIC SMALL LETTER IO
        "\xE0" => "\xC0",     # CYRILLIC CAPITAL LETTER YU --> CYRILLIC SMALL LETTER YU
        "\xE1" => "\xC1",     # CYRILLIC CAPITAL LETTER A --> CYRILLIC SMALL LETTER A
        "\xE2" => "\xC2",     # CYRILLIC CAPITAL LETTER BE --> CYRILLIC SMALL LETTER BE
        "\xE3" => "\xC3",     # CYRILLIC CAPITAL LETTER TSE --> CYRILLIC SMALL LETTER TSE
        "\xE4" => "\xC4",     # CYRILLIC CAPITAL LETTER DE --> CYRILLIC SMALL LETTER DE
        "\xE5" => "\xC5",     # CYRILLIC CAPITAL LETTER IE --> CYRILLIC SMALL LETTER IE
        "\xE6" => "\xC6",     # CYRILLIC CAPITAL LETTER EF --> CYRILLIC SMALL LETTER EF
        "\xE7" => "\xC7",     # CYRILLIC CAPITAL LETTER GHE --> CYRILLIC SMALL LETTER GHE
        "\xE8" => "\xC8",     # CYRILLIC CAPITAL LETTER HA --> CYRILLIC SMALL LETTER HA
        "\xE9" => "\xC9",     # CYRILLIC CAPITAL LETTER I --> CYRILLIC SMALL LETTER I
        "\xEA" => "\xCA",     # CYRILLIC CAPITAL LETTER SHORT I --> CYRILLIC SMALL LETTER SHORT I
        "\xEB" => "\xCB",     # CYRILLIC CAPITAL LETTER KA --> CYRILLIC SMALL LETTER KA
        "\xEC" => "\xCC",     # CYRILLIC CAPITAL LETTER EL --> CYRILLIC SMALL LETTER EL
        "\xED" => "\xCD",     # CYRILLIC CAPITAL LETTER EM --> CYRILLIC SMALL LETTER EM
        "\xEE" => "\xCE",     # CYRILLIC CAPITAL LETTER EN --> CYRILLIC SMALL LETTER EN
        "\xEF" => "\xCF",     # CYRILLIC CAPITAL LETTER O --> CYRILLIC SMALL LETTER O
        "\xF0" => "\xD0",     # CYRILLIC CAPITAL LETTER PE --> CYRILLIC SMALL LETTER PE
        "\xF1" => "\xD1",     # CYRILLIC CAPITAL LETTER YA --> CYRILLIC SMALL LETTER YA
        "\xF2" => "\xD2",     # CYRILLIC CAPITAL LETTER ER --> CYRILLIC SMALL LETTER ER
        "\xF3" => "\xD3",     # CYRILLIC CAPITAL LETTER ES --> CYRILLIC SMALL LETTER ES
        "\xF4" => "\xD4",     # CYRILLIC CAPITAL LETTER TE --> CYRILLIC SMALL LETTER TE
        "\xF5" => "\xD5",     # CYRILLIC CAPITAL LETTER U --> CYRILLIC SMALL LETTER U
        "\xF6" => "\xD6",     # CYRILLIC CAPITAL LETTER ZHE --> CYRILLIC SMALL LETTER ZHE
        "\xF7" => "\xD7",     # CYRILLIC CAPITAL LETTER VE --> CYRILLIC SMALL LETTER VE
        "\xF8" => "\xD8",     # CYRILLIC CAPITAL LETTER SOFT SIGN --> CYRILLIC SMALL LETTER SOFT SIGN
        "\xF9" => "\xD9",     # CYRILLIC CAPITAL LETTER YERU --> CYRILLIC SMALL LETTER YERU
        "\xFA" => "\xDA",     # CYRILLIC CAPITAL LETTER ZE --> CYRILLIC SMALL LETTER ZE
        "\xFB" => "\xDB",     # CYRILLIC CAPITAL LETTER SHA --> CYRILLIC SMALL LETTER SHA
        "\xFC" => "\xDC",     # CYRILLIC CAPITAL LETTER E --> CYRILLIC SMALL LETTER E
        "\xFD" => "\xDD",     # CYRILLIC CAPITAL LETTER SHCHA --> CYRILLIC SMALL LETTER SHCHA
        "\xFE" => "\xDE",     # CYRILLIC CAPITAL LETTER CHE --> CYRILLIC SMALL LETTER CHE
        "\xFF" => "\xDF",     # CYRILLIC CAPITAL LETTER HARD SIGN --> CYRILLIC SMALL LETTER HARD SIGN
    );
}

else {
    croak "Don't know my package name '@{[__PACKAGE__]}'";
}

#
# Prototypes of subroutines
#
sub import() {}
sub unimport() {}
sub Ekoi8r::split(;$$$);
sub Ekoi8r::tr($$$$;$);
sub Ekoi8r::chop(@);
sub Ekoi8r::index($$;$);
sub Ekoi8r::rindex($$;$);
sub Ekoi8r::lcfirst(@);
sub Ekoi8r::lcfirst_();
sub Ekoi8r::lc(@);
sub Ekoi8r::lc_();
sub Ekoi8r::ucfirst(@);
sub Ekoi8r::ucfirst_();
sub Ekoi8r::uc(@);
sub Ekoi8r::uc_();
sub Ekoi8r::fc(@);
sub Ekoi8r::fc_();
sub Ekoi8r::ignorecase(@);
sub Ekoi8r::classic_character_class($);
sub Ekoi8r::capture($);
sub Ekoi8r::chr(;$);
sub Ekoi8r::chr_();
sub Ekoi8r::glob($);
sub Ekoi8r::glob_();

sub KOI8R::ord(;$);
sub KOI8R::ord_();
sub KOI8R::reverse(@);
sub KOI8R::length(;$);
sub KOI8R::substr($$;$$);
sub KOI8R::index($$;$);
sub KOI8R::rindex($$;$);

#
# Character class
#
use vars qw(
    @anchor
    @dot
    @dot_s
    @eD
    @eS
    @eW
    @eH
    @eV
    @eR
    @eN
    @not_alnum
    @not_alpha
    @not_ascii
    @not_blank
    @not_cntrl
    @not_digit
    @not_graph
    @not_lower
    @not_lower_i
    @not_print
    @not_punct
    @not_space
    @not_upper
    @not_upper_i
    @not_word
    @not_xdigit
    @eb
    @eB
);
@{Ekoi8r::anchor}      = qr{\G(?:[\x00-\xFF])*?};
@{Ekoi8r::dot}         = qr{(?:[^\x0A])};
@{Ekoi8r::dot_s}       = qr{(?:[\x00-\xFF])};
@{Ekoi8r::eD}          = qr{(?:[^0-9])};
@{Ekoi8r::eS}          = qr{(?:[^\x09\x0A\x0C\x0D\x20])};
@{Ekoi8r::eW}          = qr{(?:[^0-9A-Z_a-z])};
@{Ekoi8r::eH}          = qr{(?:[^\x09\x20])};
@{Ekoi8r::eV}          = qr{(?:[^\x0A\x0B\x0C\x0D])};
@{Ekoi8r::eR}          = qr{(?:\x0D\x0A|[\x0A\x0D])};
@{Ekoi8r::eN}          = qr{(?:[^\x0A])};
@{Ekoi8r::not_alnum}   = qr{(?:[^\x30-\x39\x41-\x5A\x61-\x7A])};
@{Ekoi8r::not_alpha}   = qr{(?:[^\x41-\x5A\x61-\x7A])};
@{Ekoi8r::not_ascii}   = qr{(?:[^\x00-\x7F])};
@{Ekoi8r::not_blank}   = qr{(?:[^\x09\x20])};
@{Ekoi8r::not_cntrl}   = qr{(?:[^\x00-\x1F\x7F])};
@{Ekoi8r::not_digit}   = qr{(?:[^\x30-\x39])};
@{Ekoi8r::not_graph}   = qr{(?:[^\x21-\x7F])};
@{Ekoi8r::not_lower}   = qr{(?:[^\x61-\x7A])};
@{Ekoi8r::not_lower_i} = qr{(?:[\x00-\xFF])};
@{Ekoi8r::not_print}   = qr{(?:[^\x20-\x7F])};
@{Ekoi8r::not_punct}   = qr{(?:[^\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])};
@{Ekoi8r::not_space}   = qr{(?:[^\x09\x0A\x0B\x0C\x0D\x20])};
@{Ekoi8r::not_upper}   = qr{(?:[^\x41-\x5A])};
@{Ekoi8r::not_upper_i} = qr{(?:[\x00-\xFF])};
@{Ekoi8r::not_word}    = qr{(?:[^\x30-\x39\x41-\x5A\x5F\x61-\x7A])};
@{Ekoi8r::not_xdigit}  = qr{(?:[^\x30-\x39\x41-\x46\x61-\x66])};
@{Ekoi8r::eb}          = qr{(?:\A(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[0-9A-Z_a-z])|(?<=[0-9A-Z_a-z])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]|\z))};
@{Ekoi8r::eB}          = qr{(?:(?<=[0-9A-Z_a-z])(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]))};

#
# @ARGV wildcard globbing
#
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    if ($ENV{'ComSpec'} =~ / (?: COMMAND\.COM | CMD\.EXE ) \z /oxmsi) {
        my @argv = ();
        for (@ARGV) {
            if (m/\A ' ((?:$q_char)*) ' \z/oxms) {
                push @argv, $1;
            }
            elsif (m/\A (?:$q_char)*? [*?] /oxms and (my @glob = Ekoi8r::glob($_))) {
                push @argv, @glob;
            }
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }
}

#
# KOI8-R split
#
sub Ekoi8r::split(;$$$) {

    # P.794 29.2.161. split
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.951 split
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    my $pattern = $_[0];
    my $string  = $_[1];
    my $limit   = $_[2];

    # if $string is omitted, the function splits the $_ string
    if (not defined $string) {
        if (defined $_) {
            $string = $_;
        }
        else {
            $string = '';
        }
    }

    my @split = ();

    # when string is empty
    if ($string eq '') {

        # resulting list value in list context
        if (wantarray) {
            return @split;
        }

        # count of substrings in scalar context
        else {
            carp "Use of implicit split to \@_ is deprecated" if $^W;
            @_ = @split;
            return scalar @_;
        }
    }

    # if $limit is negative, it is treated as if an arbitrarily large $limit has been specified
    if ((not defined $limit) or ($limit <= 0)) {

        # if $pattern is also omitted or is the literal space, " ", the function splits
        # on whitespace, /\s+/, after skipping any leading whitespace
        # (and so on)

        if ((not defined $pattern) or ($pattern eq ' ')) {
            $string =~ s/ \A \s+ //oxms;

            # P.1024 Appendix W.10 Multibyte Processing
            # of ISBN 1-56592-224-7 CJKV Information Processing
            # (and so on)

            # the //m modifier is assumed when you split on the pattern /^/
            # (and so on)

            while ($string =~ s/\A((?:$q_char)*?)\s+//m) {

                # if the $pattern contains parentheses, then the substring matched by each pair of parentheses
                # is included in the resulting list, interspersed with the fields that are ordinarily returned
                # (and so on)

                local $@;
                for (my $digit=1; $digit <= 1; $digit++) {
                    push @split, eval('$' . $digit);
                }
            }
        }

        # a pattern capable of matching either the null string or something longer than the
        # null string will split the value of $string into separate characters wherever it
        # matches the null string between characters
        # (and so on)

        elsif ('' =~ m/ \A $pattern \z /xms) {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                local $@;
                for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                    push @split, eval('$' . $digit);
                }
            }
        }

        else {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                local $@;
                for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                    push @split, eval('$' . $digit);
                }
            }
        }
    }

    else {
        if ((not defined $pattern) or ($pattern eq ' ')) {
            $string =~ s/ \A \s+ //oxms;
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)*?)\s+//m) {
                    local $@;
                    for (my $digit=1; $digit <= 1; $digit++) {
                        push @split, eval('$' . $digit);
                    }
                }
            }
        }
        elsif ('' =~ m/ \A $pattern \z /xms) {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                    local $@;
                    for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                        push @split, eval('$' . $digit);
                    }
                }
            }
        }
        else {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ((--$limit > 0) and (CORE::length($string) > 0)) {
                if ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                    local $@;
                    for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                        push @split, eval('$' . $digit);
                    }
                }
            }
        }
    }

    push @split, $string;

    # if $limit is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $limit) or ($limit == 0)) {
        while ((scalar(@split) >= 1) and ($split[-1] eq '')) {
            pop @split;
        }
    }

    # resulting list value in list context
    if (wantarray) {
        return @split;
    }

    # count of substrings in scalar context
    else {
        carp "Use of implicit split to \@_ is deprecated" if $^W;
        @_ = @split;
        return scalar @_;
    }
}

#
# get last subexpression offsets
#
sub _last_subexpression_offsets {
    my $pattern = $_[0];

    # remove comment
    $pattern =~ s/\(\?\# .*? \)//oxmsg;

    my $modifier = '';
    if ($pattern =~ m/\(\?\^? ([\-A-Za-z]+) :/oxms) {
        $modifier = $1;
        $modifier =~ s/-[A-Za-z]*//;
    }

    # with /x modifier
    my @char = ();
    if ($modifier =~ m/x/oxms) {
        @char = $pattern =~ m{\G(
            \\ (?:$q_char)                  |
            \# (?:$q_char)*? $              |
            \[ (?: \\\] | (?:$q_char))+? \] |
            \(\?                            |
            (?:$q_char)
        )}oxmsg;
    }

    # without /x modifier
    else {
        @char = $pattern =~ m{\G(
            \\ (?:$q_char)                  |
            \[ (?: \\\] | (?:$q_char))+? \] |
            \(\?                            |
            (?:$q_char)
        )}oxmsg;
    }

    return scalar grep { $_ eq '(' } @char;
}

#
# KOI8-R transliteration (tr///)
#
sub Ekoi8r::tr($$$$;$) {

    my $bind_operator   = $_[1];
    my $searchlist      = $_[2];
    my $replacementlist = $_[3];
    my $modifier        = $_[4] || '';

    if ($modifier =~ m/r/oxms) {
        if ($bind_operator =~ m/ !~ /oxms) {
            croak "Using !~ with tr///r doesn't make sense";
        }
    }

    my @char            = $_[0] =~ m/\G ($q_char) /oxmsg;
    my @searchlist      = _charlist_tr($searchlist);
    my @replacementlist = _charlist_tr($replacementlist);

    my %tr = ();
    for (my $i=0; $i <= $#searchlist; $i++) {
        if (not exists $tr{$searchlist[$i]}) {
            if (defined $replacementlist[$i] and ($replacementlist[$i] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[$i];
            }
            elsif ($modifier =~ m/d/oxms) {
                $tr{$searchlist[$i]} = '';
            }
            elsif (defined $replacementlist[-1] and ($replacementlist[-1] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[-1];
            }
            else {
                $tr{$searchlist[$i]} = $searchlist[$i];
            }
        }
    }

    my $tr = 0;
    my $replaced = '';
    if ($modifier =~ m/c/oxms) {
        while (defined(my $char = shift @char)) {
            if (not exists $tr{$char}) {
                if (defined $replacementlist[0]) {
                    $replaced .= $replacementlist[0];
                }
                $tr++;
                if ($modifier =~ m/s/oxms) {
                    while (@char and (not exists $tr{$char[0]})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $replaced .= $char;
            }
        }
    }
    else {
        while (defined(my $char = shift @char)) {
            if (exists $tr{$char}) {
                $replaced .= $tr{$char};
                $tr++;
                if ($modifier =~ m/s/oxms) {
                    while (@char and (exists $tr{$char[0]}) and ($tr{$char[0]} eq $tr{$char})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $replaced .= $char;
            }
        }
    }

    if ($modifier =~ m/r/oxms) {
        return $replaced;
    }
    else {
        $_[0] = $replaced;
        if ($bind_operator =~ m/ !~ /oxms) {
            return not $tr;
        }
        else {
            return $tr;
        }
    }
}

#
# KOI8-R chop
#
sub Ekoi8r::chop(@) {

    my $chop;
    if (@_ == 0) {
        my @char = m/\G ($q_char) /oxmsg;
        $chop = pop @char;
        $_ = join '', @char;
    }
    else {
        for (@_) {
            my @char = m/\G ($q_char) /oxmsg;
            $chop = pop @char;
            $_ = join '', @char;
        }
    }
    return $chop;
}

#
# KOI8-R index by octet
#
sub Ekoi8r::index($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;

    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ m/\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#
# KOI8-R reverse index
#
sub Ekoi8r::rindex($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;

    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ m/\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#
# KOI8-R lower case first with parameter
#
sub Ekoi8r::lcfirst(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return Ekoi8r::lc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
        }
        else {
            return Ekoi8r::lc(CORE::substr($s,0,1)) . CORE::substr($s,1);
        }
    }
    else {
        return Ekoi8r::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }
}

#
# KOI8-R lower case first without parameter
#
sub Ekoi8r::lcfirst_() {
    return Ekoi8r::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
}

#
# KOI8-R lower case with parameter
#
sub Ekoi8r::lc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg));
        }
    }
    else {
        return Ekoi8r::lc_();
    }
}

#
# KOI8-R lower case without parameter
#
sub Ekoi8r::lc_() {
    my $s = $_;
    return join '', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg);
}

#
# KOI8-R upper case first with parameter
#
sub Ekoi8r::ucfirst(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return Ekoi8r::uc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
        }
        else {
            return Ekoi8r::uc(CORE::substr($s,0,1)) . CORE::substr($s,1);
        }
    }
    else {
        return Ekoi8r::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }
}

#
# KOI8-R upper case first without parameter
#
sub Ekoi8r::ucfirst_() {
    return Ekoi8r::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
}

#
# KOI8-R upper case with parameter
#
sub Ekoi8r::uc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg));
        }
    }
    else {
        return Ekoi8r::uc_();
    }
}

#
# KOI8-R upper case without parameter
#
sub Ekoi8r::uc_() {
    my $s = $_;
    return join '', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg);
}

#
# KOI8-R fold case with parameter
#
sub Ekoi8r::fc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg));
        }
    }
    else {
        return Ekoi8r::fc_();
    }
}

#
# KOI8-R fold case lower case without parameter
#
sub Ekoi8r::fc_() {
    my $s = $_;
    return join '', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ m/\G ($q_char) /oxmsg);
}

#
# KOI8-R regexp capture
#
{
    sub Ekoi8r::capture($) {
        return $_[0];
    }
}

#
# KOI8-R regexp ignore case modifier
#
sub Ekoi8r::ignorecase(@) {

    my @string = @_;
    my $metachar = qr/[\@\\|[\]{]/oxms;

    # ignore case of $scalar or @array
    for my $string (@string) {

        # split regexp
        my @char = $string =~ m{\G(
            \[\^ |
                \\? (?:$q_char)
        )}oxmsg;

        # unescape character
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # open character class [...]
            if ($char[$i] eq '[') {
                my $left = $i;

                # [] make die "unmatched [] in regexp ..."

                if ($char[$i+1] eq ']') {
                    $i++;
                }

                while (1) {
                    if (++$i > $#char) {
                        croak "Unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = $1 . '\\' . $char;
                            }
                        }

                        # [...]
                        splice @char, $left, $right-$left+1, '(?:' . join('|', @charlist) . ')';

                        $i = $left;
                        last;
                    }
                }
            }

            # open character class [^...]
            elsif ($char[$i] eq '[^') {
                my $left = $i;

                # [^] make die "unmatched [] in regexp ..."

                if ($char[$i+1] eq ']') {
                    $i++;
                }

                while (1) {
                    if (++$i > $#char) {
                        croak "Unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_not_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [^...]
                        splice @char, $left, $right-$left+1, '(?!' . join('|', @charlist) . ")(?:$your_char)";

                        $i = $left;
                        last;
                    }
                }
            }

            # rewrite classic character class or escape character
            elsif (my $char = classic_character_class($char[$i])) {
                $char[$i] = $char;
            }

            # /i modifier
            elsif ($char[$i] =~ m/\A [\x00-\xFF] \z/oxms) {
                my $uc = Ekoi8r::uc($char[$i]);
                my $fc = Ekoi8r::fc($char[$i]);
                if ($uc ne $fc) {
                    if (CORE::length($fc) == 1) {
                        $char[$i] = '['   . $uc       . $fc . ']';
                    }
                    else {
                        $char[$i] = '(?:' . $uc . '|' . $fc . ')';
                    }
                }
            }
        }

        # characterize
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # escape last octet of multiple-octet
            if ($char[$i] =~ m/\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                $char[$i] = $1 . '\\' . $2;
            }

            # quote character before ? + * {
            elsif (($i >= 1) and ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms)) {
                if ($char[$i-1] !~ m/\A [\x00-\xFF] \z/oxms) {
                    $char[$i-1] = '(?:' . $char[$i-1] . ')';
                }
            }
        }

        $string = join '', @char;
    }

    # make regexp string
    return @string;
}

#
# classic character class ( \D \S \W \d \s \w \C \X \H \V \h \v \R \N \b \B )
#
sub classic_character_class($) {
    my($char) = @_;

    return {
        '\D' => '@{Ekoi8r::eD}',
        '\S' => '@{Ekoi8r::eS}',
        '\W' => '@{Ekoi8r::eW}',
        '\d' => '[0-9]',
                 # \t  \n  \f  \r space
        '\s' => '[\x09\x0A\x0C\x0D\x20]',
        '\w' => '[0-9A-Z_a-z]',
        '\C' => '[\x00-\xFF]',
        '\X' => 'X',

        # \h \v \H \V

        # P.114 Character Class Shortcuts
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        # P.357 13.2.3 Whitespace
        # in Chapter 13: perlrecharclass: Perl Regular Expression Character Classes
        # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)
        #
        # 0x00009   CHARACTER TABULATION  h s
        # 0x0000a         LINE FEED (LF)   vs
        # 0x0000b        LINE TABULATION   v
        # 0x0000c         FORM FEED (FF)   vs
        # 0x0000d   CARRIAGE RETURN (CR)   vs
        # 0x00020                  SPACE  h s

        # P.196 Table 5-9. Alphanumeric regex metasymbols
        # in Chapter 5. Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # (and so on)

        '\H' => '@{Ekoi8r::eH}',
        '\V' => '@{Ekoi8r::eV}',
        '\h' => '[\x09\x20]',
        '\v' => '[\x0A\x0B\x0C\x0D]',
        '\R' => '@{Ekoi8r::eR}',

        # \N
        #
        # http://perldoc.perl.org/perlre.html
        # Character Classes and other Special Escapes
        # Any character but \n (experimental). Not affected by /s modifier

        '\N' => '@{Ekoi8r::eN}',

        # \b \B

        # P.180 Boundaries: The \b and \B Assertions
        # in Chapter 5: Pattern Matching
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.219 Boundaries: The \b and \B Assertions
        # in Chapter 5: Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # '\b' => '(?:(?<=\A|\W)(?=\w)|(?<=\w)(?=\W|\z))',
        '\b' => '@{Ekoi8r::eb}',

        # '\B' => '(?:(?<=\w)(?=\w)|(?<=\W)(?=\W))',
        '\B' => '@{Ekoi8r::eB}',

    }->{$char} || '';
}

#
# prepare KOI8-R characters per length
#

# 1 octet characters
my @chars1 = ();
sub chars1 {
    if (@chars1) {
        return @chars1;
    }
    if (exists $range_tr{1}) {
        my @ranges = @{ $range_tr{1} };
        while (my @range = splice(@ranges,0,1)) {
            for my $oct0 (@{$range[0]}) {
                push @chars1, pack 'C', $oct0;
            }
        }
    }
    return @chars1;
}

# 2 octets characters
my @chars2 = ();
sub chars2 {
    if (@chars2) {
        return @chars2;
    }
    if (exists $range_tr{2}) {
        my @ranges = @{ $range_tr{2} };
        while (my @range = splice(@ranges,0,2)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    push @chars2, pack 'CC', $oct0,$oct1;
                }
            }
        }
    }
    return @chars2;
}

# 3 octets characters
my @chars3 = ();
sub chars3 {
    if (@chars3) {
        return @chars3;
    }
    if (exists $range_tr{3}) {
        my @ranges = @{ $range_tr{3} };
        while (my @range = splice(@ranges,0,3)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    for my $oct2 (@{$range[2]}) {
                        push @chars3, pack 'CCC', $oct0,$oct1,$oct2;
                    }
                }
            }
        }
    }
    return @chars3;
}

# 4 octets characters
my @chars4 = ();
sub chars4 {
    if (@chars4) {
        return @chars4;
    }
    if (exists $range_tr{4}) {
        my @ranges = @{ $range_tr{4} };
        while (my @range = splice(@ranges,0,4)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    for my $oct2 (@{$range[2]}) {
                        for my $oct3 (@{$range[3]}) {
                            push @chars4, pack 'CCCC', $oct0,$oct1,$oct2,$oct3;
                        }
                    }
                }
            }
        }
    }
    return @chars4;
}

# minimum value of each octet
my @minchar = ();
sub minchar {
    if (defined $minchar[$_[0]]) {
        return $minchar[$_[0]];
    }
    $minchar[$_[0]] = (&{(sub {}, \&chars1, \&chars2, \&chars3, \&chars4)[$_[0]]})[0];
}

# maximum value of each octet
my @maxchar = ();
sub maxchar {
    if (defined $maxchar[$_[0]]) {
        return $maxchar[$_[0]];
    }
    $maxchar[$_[0]] = (&{(sub {}, \&chars1, \&chars2, \&chars3, \&chars4)[$_[0]]})[-1];
}

#
# KOI8-R open character list for tr
#
sub _charlist_tr {

    local $_ = shift @_;

    # unescape character
    my @char = ();
    while (not m/\G \z/oxmsgc) {
        if (m/\G (\\0?55|\\x2[Dd]|\\-) /oxmsgc) {
            push @char, '\-';
        }
        elsif (m/\G \\ ([0-7]{2,3}) /oxmsgc) {
            push @char, CORE::chr(oct $1);
        }
        elsif (m/\G \\x ([0-9A-Fa-f]{1,2}) /oxmsgc) {
            push @char, CORE::chr(hex $1);
        }
        elsif (m/\G \\c ([\x40-\x5F]) /oxmsgc) {
            push @char, CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif (m/\G (\\ [0nrtfbae]) /oxmsgc) {
            push @char, {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
            }->{$1};
        }
        elsif (m/\G \\ ($q_char) /oxmsgc) {
            push @char, $1;
        }
        elsif (m/\G ($q_char) /oxmsgc) {
            push @char, $1;
        }
    }

    # join separated multiple-octet
    @char = join('',@char) =~ m/\G (\\-|$q_char) /oxmsg;

    # unescape '-'
    my @i = ();
    for my $i (0 .. $#char) {
        if ($char[$i] eq '\-') {
            $char[$i] = '-';
        }
        elsif ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                push @i, $i;
            }
        }
    }

    # open character list (reverse for splice)
    for my $i (CORE::reverse @i) {
        my @range = ();

        # range error
        if ((length($char[$i-1]) > length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
            croak "Invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
        }

        # range of multiple-octet code
        if (length($char[$i-1]) == 1) {
            if (length($char[$i+1]) == 1) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars1();
            }
            elsif (length($char[$i+1]) == 2) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range, grep {$_ le $char[$i+1]}                           chars2();
            }
            elsif (length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range,                                                    chars2();
                push @range, grep {$_ le $char[$i+1]}                           chars3();
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range,                                                    chars2();
                push @range,                                                    chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
        }
        elsif (length($char[$i-1]) == 2) {
            if (length($char[$i+1]) == 2) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars2();
            }
            elsif (length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           chars2();
                push @range, grep {$_ le $char[$i+1]}                           chars3();
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars2();
                push @range,                                                    chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
        }
        elsif (length($char[$i-1]) == 3) {
            if (length($char[$i+1]) == 3) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars3();
            }
            elsif (length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
        }
        elsif (length($char[$i-1]) == 4) {
            if (length($char[$i+1]) == 4) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars4();
            }
        }

        splice @char, $i-1, 3, @range;
    }

    return @char;
}

#
# KOI8-R octet range
#
sub _octets {

    my $modifier = pop @_;
    my $length = shift;

    my($a) = unpack 'C', $_[0];
    my($z) = unpack 'C', $_[1];

    # single octet code
    if ($length == 1) {

        # single octet and ignore case
        if (((caller(1))[3] ne 'Ekoi8r::_octets') and ($modifier =~ m/i/oxms)) {
            if ($a == $z) {
                return sprintf('(?i:\x%02X)',          $a);
            }
            elsif (($a+1) == $z) {
                return sprintf('(?i:[\x%02X\x%02X])',  $a, $z);
            }
            else {
                return sprintf('(?i:[\x%02X-\x%02X])', $a, $z);
            }
        }

        # not ignore case or one of multiple-octet
        else {
            if ($a == $z) {
                return sprintf('\x%02X',          $a);
            }
            elsif (($a+1) == $z) {
                return sprintf('[\x%02X\x%02X]',  $a, $z);
            }
            else {
                return sprintf('[\x%02X-\x%02X]', $a, $z);
            }
        }
    }
}

#
# KOI8-R open character list for qr and not qr
#
sub _charlist {

    my $modifier = pop @_;
    my @char = @_;

    my $ignorecase = ($modifier =~ m/i/oxms) ? 1 : 0;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }

        # octal escape sequence
        elsif ($char[$i] =~ m/\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = hexchr($1);
        }

        # \N{CHARNAME} --> N{CHARNAME}
        elsif ($char[$i] =~ m/\A \\ ( N\{ ([^0-9\}][^\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        # \p{PROPERTY} --> p{PROPERTY}
        elsif ($char[$i] =~ m/\A \\ ( p\{ ([^0-9\}][^\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        # \P{PROPERTY} --> P{PROPERTY}
        elsif ($char[$i] =~ m/\A \\ ( P\{ ([^0-9\}][^\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        # \p, \P, \X --> p, P, X
        elsif ($char[$i] =~ m/\A \\ ( [pPX] ) \z/oxms) {
            $char[$i] = $1;
        }

        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = CORE::chr oct $1;
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{1,2}) \z/oxms) {
            $char[$i] = CORE::chr hex $1;
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedswDSWHVhvR]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '[0-9]',
                '\s' => '[\x09\x0A\x0C\x0D\x20]',
                '\w' => '[0-9A-Z_a-z]',
                '\D' => '@{Ekoi8r::eD}',
                '\S' => '@{Ekoi8r::eS}',
                '\W' => '@{Ekoi8r::eW}',

                '\H' => '@{Ekoi8r::eH}',
                '\V' => '@{Ekoi8r::eV}',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0A\x0B\x0C\x0D]',
                '\R' => '@{Ekoi8r::eR}',

            }->{$1};
        }

        # POSIX-style character classes
        elsif ($ignorecase and ($char[$i] =~ m/\A ( \[\: \^? (?:lower|upper) :\] ) \z/oxms)) {
            $char[$i] = {

                '[:lower:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:upper:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:^lower:]'  => '@{Ekoi8r::not_lower_i}',
                '[:^upper:]'  => '@{Ekoi8r::not_upper_i}',

            }->{$1};
        }
        elsif ($char[$i] =~ m/\A ( \[\: \^? (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] ) \z/oxms) {
            $char[$i] = {

                '[:alnum:]'   => '[\x30-\x39\x41-\x5A\x61-\x7A]',
                '[:alpha:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:ascii:]'   => '[\x00-\x7F]',
                '[:blank:]'   => '[\x09\x20]',
                '[:cntrl:]'   => '[\x00-\x1F\x7F]',
                '[:digit:]'   => '[\x30-\x39]',
                '[:graph:]'   => '[\x21-\x7F]',
                '[:lower:]'   => '[\x61-\x7A]',
                '[:print:]'   => '[\x20-\x7F]',
                '[:punct:]'   => '[\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E]',
                '[:space:]'   => '[\x09\x0A\x0B\x0C\x0D\x20]',
                '[:upper:]'   => '[\x41-\x5A]',
                '[:word:]'    => '[\x30-\x39\x41-\x5A\x5F\x61-\x7A]',
                '[:xdigit:]'  => '[\x30-\x39\x41-\x46\x61-\x66]',
                '[:^alnum:]'  => '@{Ekoi8r::not_alnum}',
                '[:^alpha:]'  => '@{Ekoi8r::not_alpha}',
                '[:^ascii:]'  => '@{Ekoi8r::not_ascii}',
                '[:^blank:]'  => '@{Ekoi8r::not_blank}',
                '[:^cntrl:]'  => '@{Ekoi8r::not_cntrl}',
                '[:^digit:]'  => '@{Ekoi8r::not_digit}',
                '[:^graph:]'  => '@{Ekoi8r::not_graph}',
                '[:^lower:]'  => '@{Ekoi8r::not_lower}',
                '[:^print:]'  => '@{Ekoi8r::not_print}',
                '[:^punct:]'  => '@{Ekoi8r::not_punct}',
                '[:^space:]'  => '@{Ekoi8r::not_space}',
                '[:^upper:]'  => '@{Ekoi8r::not_upper}',
                '[:^word:]'   => '@{Ekoi8r::not_word}',
                '[:^xdigit:]' => '@{Ekoi8r::not_xdigit}',

            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ($q_char) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    for (my $i=0; $i <= $#char; ) {

        # escaped -
        if (defined($char[$i+1]) and ($char[$i+1] eq '...')) {
            $i += 1;
            next;
        }
        elsif ($char[$i] eq '...') {

            # range error
            if ((length($char[$i-1]) > length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
                croak "Invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            # range of single octet code and not ignore case
            if ((length($char[$i-1]) == 1) and (length($char[$i+1]) == 1) and ($modifier !~ m/i/oxms)) {
                my $a = unpack 'C', $char[$i-1];
                my $z = unpack 'C', $char[$i+1];

                if ($a == $z) {
                    push @singleoctet, sprintf('\x%02X',        $a);
                }
                elsif (($a+1) == $z) {
                    push @singleoctet, sprintf('\x%02X\x%02X',  $a, $z);
                }
                else {
                    push @singleoctet, sprintf('\x%02X-\x%02X', $a, $z);
                }
            }

            # range of multiple-octet code
            elsif (length($char[$i-1]) == length($char[$i+1])) {
                push @charlist, _octets(length($char[$i-1]), $char[$i-1], $char[$i+1], $modifier);
            }
            elsif (length($char[$i-1]) == 1) {
                if (length($char[$i+1]) == 2) {
                    push @charlist,
                        _octets(1, $char[$i-1], maxchar(1),  $modifier),
                        _octets(2, minchar(2),  $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 3) {
                    push @charlist,
                        _octets(1, $char[$i-1], maxchar(1),  $modifier),
                        _octets(2, minchar(2),  maxchar(2),  $modifier),
                        _octets(3, minchar(3),  $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(1, $char[$i-1], maxchar(1),  $modifier),
                        _octets(2, minchar(2),  maxchar(2),  $modifier),
                        _octets(3, minchar(3),  maxchar(3),  $modifier),
                        _octets(4, minchar(4),  $char[$i+1], $modifier);
                }
            }
            elsif (length($char[$i-1]) == 2) {
                if (length($char[$i+1]) == 3) {
                    push @charlist,
                        _octets(2, $char[$i-1], maxchar(2),  $modifier),
                        _octets(3, minchar(3),  $char[$i+1], $modifier);
                }
                elsif (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(2, $char[$i-1], maxchar(2),  $modifier),
                        _octets(3, minchar(3),  maxchar(3),  $modifier),
                        _octets(4, minchar(4),  $char[$i+1], $modifier);
                }
            }
            elsif (length($char[$i-1]) == 3) {
                if (length($char[$i+1]) == 4) {
                    push @charlist,
                        _octets(3, $char[$i-1], maxchar(3),  $modifier),
                        _octets(4, minchar(4),  $char[$i+1], $modifier);
                }
            }
            else {
                croak "Invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            $i += 2;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A [\x00-\xFF] \z/oxms) {
            if ($modifier =~ m/i/oxms) {
                my $uc = Ekoi8r::uc($char[$i]);
                my $fc = Ekoi8r::fc($char[$i]);
                if ($uc ne $fc) {
                    if (CORE::length($fc) == 1) {
                        push @singleoctet, $uc, $fc;
                    }
                    else {
                        push @singleoctet, $uc;
                        push @charlist,    $fc;
                    }
                }
                else {
                    push @singleoctet, $char[$i];
                }
            }
            else {
                push @singleoctet, $char[$i];
            }
            $i += 1;
        }

        # single character of single octet code
        elsif ($char[$i] =~ m/\A (?: \\h ) \z/oxms) {
            push @singleoctet, "\t", "\x20";
            $i += 1;
        }
        elsif ($char[$i] =~ m/\A (?: \\v ) \z/oxms) {
            push @singleoctet, "\x0A", "\x0B", "\x0C", "\x0D";
            $i += 1;
        }
        elsif ($char[$i] =~ m/\A (?: \\d | \\s | \\w ) \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }

        # single character of multiple-octet code
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (m/\A ([\x00-\x20\x7F-\xFF]) \z/oxms) {
            $_ = sprintf('\x%02X', CORE::ord $1);
        }
        elsif (m/\A [\x00-\xFF] \z/oxms) {
            $_ = quotemeta $_;
        }
    }

    # return character list
    return \@singleoctet, \@charlist;
}

#
# KOI8-R octal escape sequence
#
sub octchr {
    my($octdigit) = @_;

    my @binary = ();
    for my $octal (split(//,$octdigit)) {
        push @binary, {
            '0' => '000',
            '1' => '001',
            '2' => '010',
            '3' => '011',
            '4' => '100',
            '5' => '101',
            '6' => '110',
            '7' => '111',
        }->{$octal};
    }
    my $binary = join '', @binary;

    my $octchr = {
        #                1234567
        1 => pack('B*', "0000000$binary"),
        2 => pack('B*', "000000$binary"),
        3 => pack('B*', "00000$binary"),
        4 => pack('B*', "0000$binary"),
        5 => pack('B*', "000$binary"),
        6 => pack('B*', "00$binary"),
        7 => pack('B*', "0$binary"),
        0 => pack('B*', "$binary"),

    }->{CORE::length($binary) % 8};

    return $octchr;
}

#
# KOI8-R hexadecimal escape sequence
#
sub hexchr {
    my($hexdigit) = @_;

    my $hexchr = {
        1 => pack('H*', "0$hexdigit"),
        0 => pack('H*', "$hexdigit"),

    }->{CORE::length($_[0]) % 2};

    return $hexchr;
}

#
# KOI8-R open character list for qr
#
sub charlist_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $charlist) = _charlist(@char, $modifier);
    my @singleoctet = @$singleoctet;
    my @charlist    = @$charlist;

    # return character list
    if (scalar(@singleoctet) == 0) {
    }
    elsif (scalar(@singleoctet) >= 2) {
        push @charlist, '[' . join('',@singleoctet) . ']';
    }
    elsif ($singleoctet[0] =~ m/ . - . /oxms) {
        push @charlist, '[' . $singleoctet[0] . ']';
    }
    else {
        push @charlist, $singleoctet[0];
    }
    if (scalar(@charlist) >= 2) {
        return '(?:' . join('|', @charlist) . ')';
    }
    else {
        return $charlist[0];
    }
}

#
# KOI8-R open character list for not qr
#
sub charlist_not_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $charlist) = _charlist(@char, $modifier);
    my @singleoctet = @$singleoctet;
    my @charlist    = @$charlist;

    # return character list
    if (scalar(@charlist) >= 1) {
        if (scalar(@singleoctet) >= 1) {

            # any character other than multiple-octet and single octet character class
            return '(?!' . join('|', @charlist) . ')(?:[^'. join('', @singleoctet) . '])';
        }
        else {

            # any character other than multiple-octet character class
            return '(?!' . join('|', @charlist) . ")(?:$your_char)";
        }
    }
    else {
        if (scalar(@singleoctet) >= 1) {

            # any character other than single octet character class
            return                                 '(?:[^'. join('', @singleoctet) . '])';
        }
        else {

            # any character
            return                                 "(?:$your_char)";
        }
    }
}

#
# KOI8-R order to character (with parameter)
#
sub Ekoi8r::chr(;$) {

    my $c = @_ ? $_[0] : $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# KOI8-R order to character (without parameter)
#
sub Ekoi8r::chr_() {

    my $c = $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# KOI8-R path globbing (with parameter)
#
sub Ekoi8r::glob($) {

    if (wantarray) {
        my @glob = _dosglob(@_);
        for my $glob (@glob) {
            $glob =~ s{ \A (?:\./)+ }{}oxms;
        }
        return @glob;
    }
    else {
        my $glob = _dosglob(@_);
        $glob =~ s{ \A (?:\./)+ }{}oxms;
        return $glob;
    }
}

#
# KOI8-R path globbing (without parameter)
#
sub Ekoi8r::glob_() {

    if (wantarray) {
        my @glob = _dosglob();
        for my $glob (@glob) {
            $glob =~ s{ \A (?:\./)+ }{}oxms;
        }
        return @glob;
    }
    else {
        my $glob = _dosglob();
        $glob =~ s{ \A (?:\./)+ }{}oxms;
        return $glob;
    }
}

#
# KOI8-R path globbing from File::DosGlob module
#
my %iter;
my %entries;
sub _dosglob {

    # context (keyed by second cxix argument provided by core)
    my($expr,$cxix) = @_;

    # glob without args defaults to $_
    $expr = $_ if not defined $expr;

    # represents the current user's home directory
    #
    # 7.3. Expanding Tildes in Filenames
    # in Chapter 7. File Access
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
    #
    # and File::HomeDir, File::HomeDir::Windows module

    # DOS-like system
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        $expr =~ s{ \A ~ (?= [^/\\] ) }
                  { $ENV{'HOME'} || $ENV{'USERPROFILE'} || "$ENV{'HOMEDRIVE'}$ENV{'HOMEPATH'}" }oxmse;
    }

    # UNIX-like system
    else {
        $expr =~ s{ \A ~ ( (?:[^/])* ) }
                  { $1 ? (getpwnam($1))[7] : ($ENV{'HOME'} || $ENV{'LOGDIR'} || (getpwuid($<))[7]) }oxmse;
    }

    # assume global context if not provided one
    $cxix = '_G_' if not defined $cxix;
    $iter{$cxix} = 0 if not exists $iter{$cxix};

    # if we're just beginning, do it all first
    if ($iter{$cxix} == 0) {
            $entries{$cxix} = [ _do_glob(1, _parse_line($expr)) ];
    }

    # chuck it all out, quick or slow
    if (wantarray) {
        delete $iter{$cxix};
        return @{delete $entries{$cxix}};
    }
    else {
        if ($iter{$cxix} = scalar @{$entries{$cxix}}) {
            return shift @{$entries{$cxix}};
        }
        else {
            # return undef for EOL
            delete $iter{$cxix};
            delete $entries{$cxix};
            return undef;
        }
    }
}

#
# KOI8-R path globbing subroutine
#
sub _do_glob {

    my($cond,@expr) = @_;
    my @glob = ();
    my $fix_drive_relative_paths = 0;

OUTER:
    for my $expr (@expr) {
        next OUTER if not defined $expr;
        next OUTER if $expr eq '';

        my @matched = ();
        my @globdir = ();
        my $head    = '.';
        my $pathsep = '/';
        my $tail;

        # if argument is within quotes strip em and do no globbing
        if ($expr =~ m/\A " ((?:$q_char)*) " \z/oxms) {
            $expr = $1;
            if ($cond eq 'd') {
                if (-d $expr) {
                    push @glob, $expr;
                }
            }
            else {
                if (-e $expr) {
                    push @glob, $expr;
                }
            }
            next OUTER;
        }

        # wildcards with a drive prefix such as h:*.pm must be changed
        # to h:./*.pm to expand correctly
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            if ($expr =~ s# \A ((?:[A-Za-z]:)?) ([^/\\]) #$1./$2#oxms) {
                $fix_drive_relative_paths = 1;
            }
        }

        if (($head, $tail) = _parse_path($expr,$pathsep)) {
            if ($tail eq '') {
                push @glob, $expr;
                next OUTER;
            }
            if ($head =~ m/ \A (?:$q_char)*? [*?] /oxms) {
                if (@globdir = _do_glob('d', $head)) {
                    push @glob, _do_glob($cond, map {"$_$pathsep$tail"} @globdir);
                    next OUTER;
                }
            }
            if ($head eq '' or $head =~ m/\A [A-Za-z]: \z/oxms) {
                $head .= $pathsep;
            }
            $expr = $tail;
        }

        # If file component has no wildcards, we can avoid opendir
        if ($expr !~ m/ \A (?:$q_char)*? [*?] /oxms) {
            if ($head eq '.') {
                $head = '';
            }
            if ($head ne '' and ($head =~ m/ \G ($q_char) /oxmsg)[-1] ne $pathsep) {
                $head .= $pathsep;
            }
            $head .= $expr;
            if ($cond eq 'd') {
                if (-d $head) {
                    push @glob, $head;
                }
            }
            else {
                if (-e $head) {
                    push @glob, $head;
                }
            }
            next OUTER;
        }
        opendir(*DIR, $head) or next OUTER;
        my @leaf = readdir DIR;
        closedir DIR;

        if ($head eq '.') {
            $head = '';
        }
        if ($head ne '' and ($head =~ m/ \G ($q_char) /oxmsg)[-1] ne $pathsep) {
            $head .= $pathsep;
        }

        my $pattern = '';
        while ($expr =~ m/ \G ($q_char) /oxgc) {
            my $char = $1;
            if ($char eq '*') {
                $pattern .= "(?:$your_char)*",
            }
            elsif ($char eq '?') {
                $pattern .= "(?:$your_char)?",  # DOS style
#               $pattern .= "(?:$your_char)",   # UNIX style
            }
            elsif ((my $fc = Ekoi8r::fc($char)) ne $char) {
                $pattern .= $fc;
            }
            else {
                $pattern .= quotemeta $char;
            }
        }
        my $matchsub = sub { Ekoi8r::fc($_[0]) =~ m{\A $pattern \z}xms };

#       if ($@) {
#           print STDERR "$0: $@\n";
#           next OUTER;
#       }

INNER:
        for my $leaf (@leaf) {
            if ($leaf eq '.' or $leaf eq '..') {
                next INNER;
            }
            if ($cond eq 'd' and not -d "$head$leaf") {
                next INNER;
            }

            if (&$matchsub($leaf)) {
                push @matched, "$head$leaf";
                next INNER;
            }

            # [DOS compatibility special case]
            # Failed, add a trailing dot and try again, but only...

            if (Ekoi8r::index($leaf,'.') == -1 and   # if name does not have a dot in it *and*
                CORE::length($leaf) <= 8 and        # name is shorter than or equal to 8 chars *and*
                Ekoi8r::index($pattern,'\\.') != -1  # pattern has a dot.
            ) {
                if (&$matchsub("$leaf.")) {
                    push @matched, "$head$leaf";
                    next INNER;
                }
            }
        }
        if (@matched) {
            push @glob, @matched;
        }
    }
    if ($fix_drive_relative_paths) {
        for my $glob (@glob) {
            $glob =~ s# \A ([A-Za-z]:) \./ #$1#oxms;
        }
    }
    return @glob;
}

#
# KOI8-R parse line
#
sub _parse_line {

    my($line) = @_;

    $line .= ' ';
    my @piece = ();
    while ($line =~ m{
        " ( (?: [^"]   )*  ) " \s+ |
          ( (?: [^"\s] )*  )   \s+
        }oxmsg
    ) {
        push @piece, defined($1) ? $1 : $2;
    }
    return @piece;
}

#
# KOI8-R parse path
#
sub _parse_path {

    my($path,$pathsep) = @_;

    $path .= '/';
    my @subpath = ();
    while ($path =~ m{
        ((?: [^/\\] )+?) [/\\] }oxmsg
    ) {
        push @subpath, $1;
    }

    my $tail = pop @subpath;
    my $head = join $pathsep, @subpath;
    return $head, $tail;
}

#
# ${^PREMATCH}, $PREMATCH, $` the string preceding what was matched
#
sub Ekoi8r::PREMATCH {
    return $`;
}

#
# ${^MATCH}, $MATCH, $& the string that matched
#
sub Ekoi8r::MATCH {
    return $&;
}

#
# ${^POSTMATCH}, $POSTMATCH, $' the string following what was matched
#
sub Ekoi8r::POSTMATCH {
    return $';
}

#
# KOI8-R character to order (with parameter)
#
sub KOI8R::ord(;$) {

    local $_ = shift if @_;

    if (m/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# KOI8-R character to order (without parameter)
#
sub KOI8R::ord_() {

    if (m/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# KOI8-R reverse
#
sub KOI8R::reverse(@) {

    if (wantarray) {
        return CORE::reverse @_;
    }
    else {
        return join '', CORE::reverse(join('',@_) =~ m/\G ($q_char) /oxmsg);
    }
}

#
# KOI8-R length by character
#
sub KOI8R::length(;$) {

    local $_ = shift if @_;

    local @_ = m/\G ($q_char) /oxmsg;
    return scalar @_;
}

#
# KOI8-R substr by character
#
sub KOI8R::substr($$;$$) {

    my @char = $_[0] =~ m/\G ($q_char) /oxmsg;

    # substr($string,$offset,$length,$replacement)
    if (@_ == 4) {
        my(undef,$offset,$length,$replacement) = @_;
        my $substr = join '', splice(@char, $offset, $length, $replacement);
        $_[0] = join '', @char;
        return $substr;
    }

    # substr($string,$offset,$length)
    elsif (@_ == 3) {
        my(undef,$offset,$length) = @_;
        if ($length == 0) {
            return '';
        }
        if ($offset >= 0) {
            return join '', (@char[$offset            .. $#char])[0 .. $length-1];
        }
        else {
            return join '', (@char[($#char+$offset+1) .. $#char])[0 .. $length-1];
        }
    }

    # substr($string,$offset)
    else {
        my(undef,$offset) = @_;
        if ($offset >= 0) {
            return join '', @char[$offset            .. $#char];
        }
        else {
            return join '', @char[($#char+$offset+1) .. $#char];
        }
    }
}

#
# KOI8-R index by character
#
sub KOI8R::index($$;$) {

    my $index;
    if (@_ == 3) {
        $index = Ekoi8r::index($_[0], $_[1], CORE::length(KOI8R::substr($_[0], 0, $_[2])));
    }
    else {
        $index = Ekoi8r::index($_[0], $_[1]);
    }

    if ($index == -1) {
        return -1;
    }
    else {
        return KOI8R::length(CORE::substr $_[0], 0, $index);
    }
}

#
# KOI8-R rindex by character
#
sub KOI8R::rindex($$;$) {

    my $rindex;
    if (@_ == 3) {
        $rindex = Ekoi8r::rindex($_[0], $_[1], CORE::length(KOI8R::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = Ekoi8r::rindex($_[0], $_[1]);
    }

    if ($rindex == -1) {
        return -1;
    }
    else {
        return KOI8R::length(CORE::substr $_[0], 0, $rindex);
    }
}

#
# instead of Carp::carp
#
sub carp(@) {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
}

#
# instead of Carp::croak
#
sub croak(@) {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
    die "\n";
}

#
# instead of Carp::cluck
#
sub cluck(@) {
    my $i = 0;
    my @cluck = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @cluck, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR reverse @cluck;
    print STDERR "\n";
    carp @_;
}

#
# instead of Carp::confess
#
sub confess(@) {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR reverse @confess;
    print STDERR "\n";
    croak @_;
}

1;

__END__

=pod

=head1 NAME

Ekoi8r - Run-time routines for KOI8R.pm

=head1 SYNOPSIS

  use Ekoi8r;

    Ekoi8r::split(...);
    Ekoi8r::tr(...);
    Ekoi8r::chop(...);
    Ekoi8r::index(...);
    Ekoi8r::rindex(...);
    Ekoi8r::lc(...);
    Ekoi8r::lc_;
    Ekoi8r::lcfirst(...);
    Ekoi8r::lcfirst_;
    Ekoi8r::uc(...);
    Ekoi8r::uc_;
    Ekoi8r::ucfirst(...);
    Ekoi8r::ucfirst_;
    Ekoi8r::fc(...);
    Ekoi8r::fc_;
    Ekoi8r::ignorecase(...);
    Ekoi8r::capture(...);
    Ekoi8r::chr(...);
    Ekoi8r::chr_;
    Ekoi8r::glob(...);
    Ekoi8r::glob_;

  # "no Ekoi8r;" not supported

=head1 ABSTRACT

This module is a run-time routines of the KOI8R.pm.
Because the KOI8R.pm automatically uses this module, you need not use directly.

=head1 BUGS AND LIMITATIONS

I have tested and verified this software using the best of my ability.
However, a software containing much regular expression is bound to contain
some bugs. Thus, if you happen to find a bug that's in KOI8R software and not
your own program, you can try to reduce it to a minimal test case and then
report it to the following author's address. If you have an idea that could
make this a more useful tool, please let everyone share it.

=head1 HISTORY

This Ekoi8r module first appeared in ActivePerl Build 522 Built under
MSWin32 Compiled at Nov 2 1999 09:52:28

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 EXAMPLES

=over 2

=item Split string

  @split = Ekoi8r::split(/pattern/,$string,$limit);
  @split = Ekoi8r::split(/pattern/,$string);
  @split = Ekoi8r::split(/pattern/);
  @split = Ekoi8r::split('',$string,$limit);
  @split = Ekoi8r::split('',$string);
  @split = Ekoi8r::split('');
  @split = Ekoi8r::split();
  @split = Ekoi8r::split;

  This function scans a string given by $string for separators, and splits the
  string into a list of substring, returning the resulting list value in list
  context or the count of substring in scalar context. Scalar context also causes
  split to write its result to @_, but this usage is deprecated. The separators
  are determined by repeated pattern matching, using the regular expression given
  in /pattern/, so the separators may be of any size and need not be the same
  string on every match. (The separators are not ordinarily returned; exceptions
  are discussed later in this section.) If the /pattern/ doesn't match the string
  at all, Ekoi8r::split returns the original string as a single substring, If it
  matches once, you get two substrings, and so on. You may supply regular
  expression modifiers to the /pattern/, like /pattern/i, /pattern/x, etc. The
  //m modifier is assumed when you split on the pattern /^/.

  If $limit is specified and positive, the function splits into no more than that
  many fields (though it may split into fewer if it runs out of separators). If
  $limit is negative, it is treated as if an arbitrarily large $limit has been
  specified If $limit is omitted or zero, trailing null fields are stripped from
  the result (which potential users of pop would do wel to remember). If $string
  is omitted, the function splits the $_ string. If /pattern/ is also omitted or
  is the literal space, " ", the function split on whitespace, /\s+/, after
  skipping any leading whitespace.

  A /pattern/ of /^/ is secretly treated if it it were /^/m, since it isn't much
  use otherwise.

  String of any length can be split:

  @chars  = Ekoi8r::split(//,  $word);
  @fields = Ekoi8r::split(/:/, $line);
  @words  = Ekoi8r::split(" ", $paragraph);
  @lines  = Ekoi8r::split(/^/, $buffer);

  A pattern capable of matching either the null string or something longer than
  the null string (for instance, a pattern consisting of any single character
  modified by a * or ?) will split the value of $string into separate characters
  wherever it matches the null string between characters; nonnull matches will
  skip over the matched separator characters in the usual fashion. (In other words,
  a pattern won't match in one spot more than once, even if it matched with a zero
  width.) For example:

  print join(":" => Ekoi8r::split(/ */, "hi there"));

  produces the output "h:i:t:h:e:r:e". The space disappers because it matches
  as part of the separator. As a trivial case, the null pattern // simply splits
  into separate characters, and spaces do not disappear. (For normal pattern
  matches, a // pattern would repeat the last successfully matched pattern, but
  Ekoi8r::split's pattern is exempt from that wrinkle.)

  The $limit parameter splits only part of a string:

  my ($login, $passwd, $remainder) = Ekoi8r::split(/:/, $_, 3);

  We encourage you to split to lists of names like this to make your code
  self-documenting. (For purposes of error checking, note that $remainder would
  be undefined if there were fewer than three fields.) When assigning to a list,
  if $limit is omitted, Perl supplies a $limit one larger than the number of
  variables in the list, to avoid unneccessary work. For the split above, $limit
  would have been 4 by default, and $remainder would have received only the third
  field, not all the rest of the fields. In time-critical applications, it behooves
  you not to split into more fields than you really need. (The trouble with
  powerful languages it that they let you be powerfully stupid at times.)

  We said earlier that the separators are not returned, but if the /pattern/
  contains parentheses, then the substring matched by each pair of parentheses is
  included in the resulting list, interspersed with the fields that are ordinarily
  returned. Here's a simple example:

  Ekoi8r::split(/([-,])/, "1-10,20");

  which produces the list value:

  (1, "-", 10, ",", 20)

  With more parentheses, a field is returned for each pair, even if some pairs
  don't match, in which case undefined values are returned in those positions. So
  if you say:

  Ekoi8r::split(/(-)|(,)/, "1-10,20");

  you get the value:

  (1, "-", undef, 10, undef, ",", 20)

  The /pattern/ argument may be replaced with an expression to specify patterns
  that vary at runtime. As with ordinary patterns, to do run-time compilation only
  once, use /$variable/o.

  As a special case, if the expression is a single space (" "), the function
  splits on whitespace just as Ekoi8r::split with no arguments does. Thus,
  Ekoi8r::split(" ") can be used to emulate awk's default behavior. In contrast,
  Ekoi8r::split(/ /) will give you as many null initial fields as there are
  leading spaces. (Other than this special case, if you supply a string instead
  of a regular expression, it'll be interpreted as a regular expression anyway.)
  You can use this property to remove leading and trailing whitespace from a
  string and to collapse intervaning stretches of whitespace into a single
  space:

  $string = join(" ", Ekoi8r::split(" ", $string));

  The following example splits an RFC822 message header into a hash containing
  $head{'Date'}, $head{'Subject'}, and so on. It uses the trick of assigning a
  list of pairs to a hash, because separators altinate with separated fields, It
  users parentheses to return part of each separator as part of the returned list
  value. Since the split pattern is guaranteed to return things in pairs by virtue
  of containing one set of parentheses, the hash assignment is guaranteed to
  receive a list consisting of key/value pairs, where each key is the name of a
  header field. (Unfortunately, this technique loses information for multiple lines
  with the same key field, such as Received-By lines. Ah well)

  $header =~ s/\n\s+/ /g; # Merge continuation lines.
  %head = ("FRONTSTUFF", Ekoi8r::split(/^(\S*?):\s*/m, $header));

  The following example processes the entries in a Unix passwd(5) file. You could
  leave out the chomp, in which case $shell would have a newline on the end of it.

  open(PASSWD, "/etc/passwd");
  while (<PASSWD>) {
      chomp; # remove trailing newline.
      ($login, $passwd, $uid, $gid, $gcos, $home, $shell) =
          Ekoi8r::split(/:/);
      ...
  }

  Here's how process each word of each line of each file of input to create a
  word-frequency hash.

  while (<>) {
      for my $word (Ekoi8r::split()) {
          $count{$word}++;
      }
  }

  The inverse of Ekoi8r::split is join, except that join can only join with the
  same separator between all fields. To break apart a string with fixed-position
  fields, use unpack.

=item Transliteration

  $tr = Ekoi8r::tr($variable,$bind_operator,$searchlist,$replacementlist,$modifier);
  $tr = Ekoi8r::tr($variable,$bind_operator,$searchlist,$replacementlist);

  This is the transliteration (sometimes erroneously called translation) operator,
  which is like the y/// operator in the Unix sed program, only better, in
  everybody's humble opinion.

  This function scans a KOI8-R string character by character and replaces all
  occurrences of the characters found in $searchlist with the corresponding character
  in $replacementlist. It returns the number of characters replaced or deleted.
  If no KOI8-R string is specified via =~ operator, the $_ variable is translated.
  $modifier are:

  ---------------------------------------------------------------------------
  Modifier   Meaning
  ---------------------------------------------------------------------------
  c          Complement $searchlist.
  d          Delete found but unreplaced characters.
  s          Squash duplicate replaced characters.
  r          Return transliteration and leave the original string untouched.
  ---------------------------------------------------------------------------

  To use with a read-only value without raising an exception, use the /r modifier.

  print Ekoi8r::tr('bookkeeper','=~','boep','peob','r'); # prints 'peekkoobor'

=item Chop string

  $chop = Ekoi8r::chop(@list);
  $chop = Ekoi8r::chop();
  $chop = Ekoi8r::chop;

  This fubction chops off the last character of a string variable and returns the
  character chopped. The Ekoi8r::chop function is used primary to remove the newline
  from the end of an input recoed, and it is more efficient than using a
  substitution. If that's all you're doing, then it would be safer to use chomp,
  since Ekoi8r::chop always shortens the string no matter what's there, and chomp
  is more selective. If no argument is given, the function chops the $_ variable.

  You cannot Ekoi8r::chop a literal, only a variable. If you Ekoi8r::chop a list of
  variables, each string in the list is chopped:

  @lines = `cat myfile`;
  Ekoi8r::chop(@lines);

  You can Ekoi8r::chop anything that is an lvalue, including an assignment:

  Ekoi8r::chop($cwd = `pwd`);
  Ekoi8r::chop($answer = <STDIN>);

  This is different from:

  $answer = Ekoi8r::chop($tmp = <STDIN>); # WRONG

  which puts a newline into $answer because Ekoi8r::chop returns the character
  chopped, not the remaining string (which is in $tmp). One way to get the result
  intended here is with substr:

  $answer = substr <STDIN>, 0, -1;

  But this is more commonly written as:

  Ekoi8r::chop($answer = <STDIN>);

  In the most general case, Ekoi8r::chop can be expressed using substr:

  $last_code = Ekoi8r::chop($var);
  $last_code = substr($var, -1, 1, ""); # same thing

  Once you understand this equivalence, you can use it to do bigger chops. To
  Ekoi8r::chop more than one character, use substr as an lvalue, assigning a null
  string. The following removes the last five characters of $caravan:

  substr($caravan, -5) = '';

  The negative subscript causes substr to count from the end of the string instead
  of the beginning. To save the removed characters, you could use the four-argument
  form of substr, creating something of a quintuple Ekoi8r::chop;

  $tail = substr($caravan, -5, 5, '');

  This is all dangerous business dealing with characters instead of graphemes. Perl
  doesn't really have a grapheme mode, so you have to deal with them yourself.

=item Index string

  $byte_pos = Ekoi8r::index($string,$substr,$byte_offset);
  $byte_pos = Ekoi8r::index($string,$substr);

  This function searches for one string within another. It returns the byte position
  of the first occurrence of $substring in $string. The $byte_offset, if specified,
  says how many bytes from the start to skip before beginning to look. Positions are
  based at 0. If the substring is not found, the function returns one less than the
  base, ordinarily -1. To work your way through a string, you might say:

  $byte_pos = -1;
  while (($byte_pos = Ekoi8r::index($string, $lookfor, $byte_pos)) > -1) {
      print "Found at $byte_pos\n";
      $byte_pos++;
  }

=item Reverse index string

  $byte_pos = Ekoi8r::rindex($string,$substr,$byte_offset);
  $byte_pos = Ekoi8r::rindex($string,$substr);

  This function works just like Ekoi8r::index except that it returns the byte
  position of the last occurrence of $substring in $string (a reverse Ekoi8r::index).
  The function returns -1 if $substring is not found. $byte_offset, if specified,
  is the rightmost byte position that may be returned. To work your way through a
  string backward, say:

  $byte_pos = length($string);
  while (($byte_pos = KOI8R::rindex($string, $lookfor, $byte_pos)) >= 0) {
      print "Found at $byte_pos\n";
      $byte_pos--;
  }

=item Lower case string

  $lc = Ekoi8r::lc($string);
  $lc = Ekoi8r::lc_;

  This function returns a lowercased version of KOI8-R $string (or $_, if
  $string is omitted). This is the internal function implementing the \L escape
  in double-quoted strings.

  You can use the Ekoi8r::fc function for case-insensitive comparisons via KOI8R
  software.

=item Lower case first character of string

  $lcfirst = Ekoi8r::lcfirst($string);
  $lcfirst = Ekoi8r::lcfirst_;

  This function returns a version of KOI8-R $string with the first character
  lowercased (or $_, if $string is omitted). This is the internal function
  implementing the \l escape in double-quoted strings.

=item Upper case string

  $uc = Ekoi8r::uc($string);
  $uc = Ekoi8r::uc_;

  This function returns an uppercased version of KOI8-R $string (or $_, if
  $string is omitted). This is the internal function implementing the \U escape
  in interpolated strings. For titlecase, use Ekoi8r::ucfirst instead.

  You can use the Ekoi8r::fc function for case-insensitive comparisons via KOI8R
  software.

=item Upper case first character of string

  $ucfirst = Ekoi8r::ucfirst($string);
  $ucfirst = Ekoi8r::ucfirst_;

  This function returns a version of KOI8-R $string with the first character
  titlecased and other characters left alone (or $_, if $string is omitted).
  Titlecase is "Camel" for an initial capital that has (or expects to have)
  lowercase characters following it, not uppercase ones. Exsamples are the first
  letter of a sentence, of a person's name, of a newspaper headline, or of most
  words in a title. Characters with no titlecase mapping return the uppercase
  mapping instead. This is the internal function implementing the \u escape in
  double-quoted strings.

  To capitalize a string by mapping its first character to titlecase and the rest
  to lowercase, use:

  $titlecase = Ekoi8r::ucfirst(substr($word,0,1)) . Ekoi8r::lc(substr($word,1));

  or

  $string =~ s/(\w)(\w*)/\u$1\L$2/g;

  Do not use:

  $do_not_use = Ekoi8r::ucfirst(Ekoi8r::lc($word));

  or "\u\L$word", because that can produce a different and incorrect answer with
  certain characters. The titlecase of something that's been lowercased doesn't
  always produce the same thing titlecasing the original produces.

  Because titlecasing only makes sense at the start of a string that's followed
  by lowercase characters, we can't think of any reason you might want to titlecase
  every character in a string.

  See also P.287 A Case of Mistaken Identity
  in Chapter 6: Unicode
  of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

=item Fold case string

  P.860 fc
  in Chapter 27: Functions
  of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

  $fc = Ekoi8r::fc($string);
  $fc = Ekoi8r::fc_;

  New to KOI8R software, this function returns the full Unicode-like casefold of
  KOI8-R $string (or $_, if omitted). This is the internal function implementing
  the \F escape in double-quoted strings.

  Just as title-case is based on uppercase but different, foldcase is based on
  lowercase but different. In ASCII there is a one-to-one mapping between only
  two cases, but in other encoding there is a one-to-many mapping and between three
  cases. Because that's too many combinations to check manually each time, a fourth
  casemap called foldcase was invented as a common intermediary for the other three.
  It is not a case itself, but it is a casemap.

  To compare whether two strings are the same without regard to case, do this:

  Ekoi8r::fc($a) eq Ekoi8r::fc($b)

  The reliable way to compare string case-insensitively was with the /i pattern
  modifier, because KOI8R software has always used casefolding semantics for
  case-insensitive pattern matches. Knowing this, you can emulate equality
  comparisons like this:

  sub fc_eq ($$) {
      my($a,$b) = @_;
      return $a =~ /\A\Q$b\E\z/i;
  }

=item Make ignore case string

  @ignorecase = Ekoi8r::ignorecase(@string);

  This function is internal use to m/ /i, s/ / /i, split / /i and qr/ /i.

=item Make capture number

  $capturenumber = Ekoi8r::capture($string);

  This function is internal use to m/ /, s/ / /, split / / and qr/ /.

=item Make character

  $chr = Ekoi8r::chr($code);
  $chr = Ekoi8r::chr_;

  This function returns a programmer-visible character, character represented by
  that $code in the character set. For example, Ekoi8r::chr(65) is "A" in either
  ASCII or KOI8-R, not Unicode. For the reverse of Ekoi8r::chr, use KOI8R::ord.

=item Filename expansion (globbing)

  @glob = Ekoi8r::glob($string);
  @glob = Ekoi8r::glob_;

  This function returns the value of $string with filename expansions the way a
  shell would expand them, returning the next successive name on each call.
  If $string is omitted, $_ is globbed instead. This is the internal function
  implementing the <*> operator.
  This function function when the pathname ends with chr(0x5C) on MSWin32.

  For economic reasons, the algorithm matches the command.com or cmd.exe's style
  of expansion, not the UNIX-like shell's. An asterisk ("*") matches any sequence
  of any character (including none). A question mark ("?") matches any one
  character or none. A tilde ("~") expands to a home directory, as in "~/.*rc"
  for all the current user's "rc" files, or "~jane/Mail/*" for all of Jane's mail
  files.

  For example, C<<..\\l*b\\file/*glob.p?>> on MSWin32 or UNIX will work as
  expected (in that it will find something like '..\lib\File/DosGlob.pm' alright).

  Note that all path components are case-insensitive, and that backslashes and
  forward slashes are both accepted, and preserved. You may have to double the
  backslashes if you are putting them in literally, due to double-quotish parsing
  of the pattern by perl.

  The Ekoi8r::glob function grandfathers the use of whitespace to separate multiple
  patterns such as <*.c *.h>. If you want to glob filenames that might contain
  whitespace, you'll have to use extra quotes around the spacy filename to protect
  it. For example, to glob filenames that have an "e" followed by a space followed
  by an "f", use either of:

  @spacies = <"*e f*">;
  @spacies = Ekoi8r::glob('"*e f*"');
  @spacies = Ekoi8r::glob(q("*e f*"));

  If you had to get a variable through, you could do this:

  @spacies = Ekoi8r::glob("'*${var}e f*'");
  @spacies = Ekoi8r::glob(qq("*${var}e f*"));

  Hint: Programmer Efficiency

  "When I'm on Windows, I use split(/\n/,`dir /s /b *.* 2>NUL`) instead of glob('*.*')"
  -- ina

=cut

