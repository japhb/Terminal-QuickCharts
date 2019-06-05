use Test;
use Terminal::QuickCharts::Pieces;


plan 45;


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


done-testing;
