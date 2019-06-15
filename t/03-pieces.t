use Test;
use Terminal::QuickCharts::Pieces;


plan 70;


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


done-testing;
