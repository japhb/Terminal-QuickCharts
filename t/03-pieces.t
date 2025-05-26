use Test;
use Terminal::QuickCharts::Pieces;


plan 79;


# hpad($pad-length, :$lines-every, :$pos)
is hpad(-5),                           '', 'hpad with negative length: no optional args';
is hpad(-5, :pos(10)),                 '', 'hpad with negative length: pos only';
is hpad(-5, :lines-every(2)),          '', 'hpad with negative length: lines-every only';
is hpad(-5, :pos(5), :lines-every(3)), '', 'hpad with negative length: both';

is hpad(0),                           '', 'hpad with zero length: no optional args';
is hpad(0, :pos(7)),                  '', 'hpad with zero length: pos only';
is hpad(0, :lines-every(1)),          '', 'hpad with zero length: lines-every only';
is hpad(0, :pos(3), :lines-every(4)), '', 'hpad with zero length: both';

is hpad(6),                           '      ', 'hpad with positive length: no optional args';
is hpad(6, :pos(0)),                  '      ', 'hpad with positive length: pos 0';
is hpad(6, :pos(3)),                  '      ', 'hpad with positive length: pos 3';
is hpad(6, :pos(7)),                  '      ', 'hpad with positive length: pos 7';

is hpad(6, :lines-every(0)),          '      ', 'hpad with positive length: lines-every 0';
is hpad(6, :lines-every(1)),          '▏▏▏▏▏▏', 'hpad with positive length: lines-every 1';
is hpad(6, :lines-every(2)),          '▏ ▏ ▏ ', 'hpad with positive length: lines-every 2';
is hpad(6, :lines-every(3)),          '▏  ▏  ', 'hpad with positive length: lines-every 3';
is hpad(6, :lines-every(4)),          '▏   ▏ ', 'hpad with positive length: lines-every 4';
is hpad(6, :lines-every(5)),          '▏    ▏', 'hpad with positive length: lines-every 5';
is hpad(6, :lines-every(6)),          '▏     ', 'hpad with positive length: lines-every 6';
is hpad(6, :lines-every(7)),          '▏     ', 'hpad with positive length: lines-every 7';

is hpad(3, :lines-every(0), :pos(0)), '   ', 'hpad with all: lines-every 0, pos 0';
is hpad(3, :lines-every(1), :pos(0)), '▏▏▏', 'hpad with all: lines-every 1, pos 0';
is hpad(3, :lines-every(2), :pos(0)), '▏ ▏', 'hpad with all: lines-every 2, pos 0';
is hpad(3, :lines-every(3), :pos(0)), '▏  ', 'hpad with all: lines-every 3, pos 0';
is hpad(3, :lines-every(4), :pos(0)), '▏  ', 'hpad with all: lines-every 4, pos 0';

is hpad(3, :lines-every(0), :pos(1)), '   ', 'hpad with all: lines-every 0, pos 1';
is hpad(3, :lines-every(1), :pos(1)), '▏▏▏', 'hpad with all: lines-every 1, pos 1';
is hpad(3, :lines-every(2), :pos(1)), ' ▏ ', 'hpad with all: lines-every 2, pos 1';
is hpad(3, :lines-every(3), :pos(1)), '  ▏', 'hpad with all: lines-every 3, pos 1';
is hpad(3, :lines-every(4), :pos(1)), '   ', 'hpad with all: lines-every 4, pos 1';

is hpad(3, :lines-every(0), :pos(2)), '   ', 'hpad with all: lines-every 0, pos 2';
is hpad(3, :lines-every(1), :pos(2)), '▏▏▏', 'hpad with all: lines-every 1, pos 2';
is hpad(3, :lines-every(2), :pos(2)), '▏ ▏', 'hpad with all: lines-every 2, pos 2';
is hpad(3, :lines-every(3), :pos(2)), ' ▏ ', 'hpad with all: lines-every 3, pos 2';
is hpad(3, :lines-every(4), :pos(2)), '  ▏', 'hpad with all: lines-every 4, pos 2';

is hpad(3, :lines-every(0), :pos(3)), '   ', 'hpad with all: lines-every 0, pos 3';
is hpad(3, :lines-every(1), :pos(3)), '▏▏▏', 'hpad with all: lines-every 1, pos 3';
is hpad(3, :lines-every(2), :pos(3)), ' ▏ ', 'hpad with all: lines-every 2, pos 3';
is hpad(3, :lines-every(3), :pos(3)), '▏  ', 'hpad with all: lines-every 3, pos 3';
is hpad(3, :lines-every(4), :pos(3)), ' ▏ ', 'hpad with all: lines-every 4, pos 3';

is hpad(3, :lines-every(0), :pos(4)), '   ', 'hpad with all: lines-every 0, pos 4';
is hpad(3, :lines-every(1), :pos(4)), '▏▏▏', 'hpad with all: lines-every 1, pos 4';
is hpad(3, :lines-every(2), :pos(4)), '▏ ▏', 'hpad with all: lines-every 2, pos 4';
is hpad(3, :lines-every(3), :pos(4)), '  ▏', 'hpad with all: lines-every 3, pos 4';
is hpad(3, :lines-every(4), :pos(4)), '▏  ', 'hpad with all: lines-every 4, pos 4';

# XXXX: hpad with color and/or line-color

# color-key(@pairs)
is-deeply color-key([]), (), 'color-key(empty @pairs)';
is-deeply color-key(['foo' => 'green']), ("\e[32m███\e[0m foo",), 'color-key(one item @pairs)';
is-deeply color-key(['foo' => 'green', 'bar' => 'red']), ("\e[32m███\e[0m foo", "\e[31m███\e[0m bar"), 'color-key(two @pairs)';


# color-key(%colors)
is-deeply color-key({}), (), 'color-key(empty %pairs)';
is-deeply color-key({ baz => 'white' }), ("\e[37m███\e[0m baz",), 'color-key(one-entry %colors)';
is-deeply color-key({ quux => 'yellow', bitz => 'blue' }), ("\e[34m███\e[0m bitz", "\e[33m███\e[0m quux"), 'color-key(two-entry %colors)';


# XXXX: What if @colors and @labels are different lengths?

# color-key(:@colors!, :@labels!)
is-deeply color-key(:labels([]), :colors([])), (), 'color-key(empty labels/colors)';
is-deeply color-key(:labels(['baz']), :colors(['white'])), ("\e[37m███\e[0m baz",), 'color-key(one each labels/colors)';
is-deeply color-key(:colors<yellow blue>, :labels<quux bitz>), ("\e[33m███\e[0m quux", "\e[34m███\e[0m bitz"), 'color-key(two each labels/colors)';


# hbar($value, :$color, :$lines-every, :$min!, :$max!, :$width!)
is hbar(-2, :min(1), :max(5), :width(10)), "          ", "hbar with value < min and no color";
is hbar( 1, :min(1), :max(5), :width(10)), "          ", "hbar with value == min and no color";
is hbar( 5, :min(1), :max(5), :width(10)), "██████████", "hbar with value == max and no color";
is hbar(12, :min(1), :max(5), :width(10)), "██████████", "hbar with value > max and no color";

is hbar(-2, :color<red>, :min(1), :max(5), :width(10)), "          ", "hbar with value < min";
is hbar( 1, :color<red>, :min(1), :max(5), :width(10)), "          ", "hbar with value == min";
is hbar( 5, :color<red>, :min(1), :max(5), :width(10)), "\e[31m██████████\e[0m", "hbar with value == max";
is hbar(12, :color<red>, :min(1), :max(5), :width(10)), "\e[31m██████████\e[0m", "hbar with value > max";

is hbar(-2, :color<red>, :min(1), :max(5), :width(10), :lines-every(0)), "          ", "hbar with value < min and lines-every == 0";
is hbar( 1, :color<red>, :min(1), :max(5), :width(10), :lines-every(0)), "          ", "hbar with value == min and lines-every == 0";
is hbar( 5, :color<red>, :min(1), :max(5), :width(10), :lines-every(0)), "\e[31m██████████\e[0m", "hbar with value == max and lines-every == 0";
is hbar(12, :color<red>, :min(1), :max(5), :width(10), :lines-every(0)), "\e[31m██████████\e[0m", "hbar with value > max and lines-every == 0";

is hbar(-2, :color<red>, :min(1), :max(5), :width(10), :lines-every(2)), "▏ ▏ ▏ ▏ ▏ ", "hbar with value < min and lines-every == 2";
is hbar( 1, :color<red>, :min(1), :max(5), :width(10), :lines-every(3)), "▏  ▏  ▏  ▏", "hbar with value == min and lines-every == 3";
is hbar( 5, :color<red>, :min(1), :max(5), :width(10), :lines-every(2)), "\e[31m██████████\e[0m", "hbar with value == max and lines-every == 2";
is hbar(12, :color<red>, :min(1), :max(5), :width(10), :lines-every(3)), "\e[31m██████████\e[0m", "hbar with value > max and lines-every == 3";


is-deeply gather { take hbar($_, :color<blue>, :min(-1), :max(3), :width(4), :lines-every(3)) for -1.3, -1.2 ... 3.3 }, (
"▏  ▏",
"▏  ▏",
"▏  ▏",
"▏  ▏",
"▏  ▏",
"\e[34m▏\e[0m  ▏",
"\e[34m▎\e[0m  ▏",
"\e[34m▍\e[0m  ▏",
"\e[34m▌\e[0m  ▏",
"\e[34m▌\e[0m  ▏",
"\e[34m▋\e[0m  ▏",
"\e[34m▊\e[0m  ▏",
"\e[34m▉\e[0m  ▏",
"\e[34m█\e[0m  ▏",
"\e[34m█\e[0m  ▏",
"\e[34m█▏\e[0m ▏",
"\e[34m█▎\e[0m ▏",
"\e[34m█▍\e[0m ▏",
"\e[34m█▌\e[0m ▏",
"\e[34m█▌\e[0m ▏",
"\e[34m█▋\e[0m ▏",
"\e[34m█▊\e[0m ▏",
"\e[34m█▉\e[0m ▏",
"\e[34m██\e[0m ▏",
"\e[34m██\e[0m ▏",
"\e[34m██▏\e[0m▏",
"\e[34m██▎\e[0m▏",
"\e[34m██▍\e[0m▏",
"\e[34m██▌\e[0m▏",
"\e[34m██▌\e[0m▏",
"\e[34m██▋\e[0m▏",
"\e[34m██▊\e[0m▏",
"\e[34m██▉\e[0m▏",
"\e[34m███\e[0m▏",
"\e[34m███\e[0m▏",
"\e[34m███▏\e[0m",
"\e[34m███▎\e[0m",
"\e[34m███▍\e[0m",
"\e[34m███▌\e[0m",
"\e[34m███▌\e[0m",
"\e[34m███▋\e[0m",
"\e[34m███▊\e[0m",
"\e[34m███▉\e[0m",
"\e[34m████\e[0m",
"\e[34m████\e[0m",
"\e[34m████\e[0m",
"\e[34m████\e[0m"),
"Correct hbar lengths for normal use";

# XXXX: hbar with bg-color and/or line-color

# stacked-hbar(@values, :@colors, :$lines-every, :$min!, :$max!, :$width!)
is stacked-hbar([], :min(-1), :max(17), :width(5)), hpad(5), "stacked-hbar([])";
is stacked-hbar([], :min( 5), :max(11), :width(6),
                :colors<red blue green>),           hpad(6), "stacked-hbar([], :colors)";
is stacked-hbar([], :min(2.1), :max(8), :width(7),
                :lines-every(2)),                   hpad(7, :lines-every(2)), "stacked-hbar([], :lines-every)";
is stacked-hbar([], :min(.1), :max(.2), :width(8),
                :colors('red',), :lines-every(3)),  hpad(8, :lines-every(3)), "stacked-hbar([], :colors, :lines-every)";

my %options = :min(0), :max(3), :width(3), :lines-every(2);
subtest "stacked-hbar(1 value, no color) eq hbar", {
    for 0, .1 ... 3.3 {
        is stacked-hbar([$_], |%options),
                   hbar( $_,  |%options),
           "stacked-hbar(1 value, no color) eq hbar: $_";
    }
}

subtest "stacked-hbar(1 value, 1 color) eq hbar", {
    for 0, .1 ... 3.3 {
        is stacked-hbar([$_], :colors('bold',), |%options),
                   hbar( $_,  :color<bold>,     |%options),
           "stacked-hbar(1 value, 1 color) eq hbar: $_";
    }
}

subtest "stacked-hbar(2 values, no color) eq hbar", {
    for 0, .1 ... 2.0 -> $i {
        for 0, .1 ... 2.5 -> $j {
            my $value = $j > 0 ?? $i + $j !! $i;
            is stacked-hbar([$i, $j], |%options),
                       hbar( $value,  |%options),
               "stacked-bar(2 values, no color) eq hbar: $i, $j ==> $value";
        }
    }
}

subtest "stacked-hbar(2 values, 1 color) eq hbar", {
    for 0, .1 ... 2.0 -> $i {
        for 0, .1 ... 2.5 -> $j {
            my $value = $j > 0 ?? $i + $j !! $i;
            is stacked-hbar([$i, $j], :colors('cyan',), |%options),
                       hbar( $value,  :color<cyan>,     |%options),
               "stacked-bar(2 values, 1 color) eq hbar: $i, $j ==> $value";
        }
    }
}

# XXXX: Test that stacked-hbar with 2 values and 2+ colors produces a sensible result

# XXXX: Test that stacked-hbar with 3+ values and 2+ colors produces a sensible result

# XXXX: stacked-hbar with bg-color and/or line-color


done-testing;
