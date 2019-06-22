use Test;
use Terminal::QuickCharts::StyledPieces;


plan 61;


# numeric-label($value, $style)
my $cs = Terminal::QuickCharts::ChartStyle.new;

is numeric-label(-1e1,  $cs), '-10',  "default numeric-label works with negative Num";
is numeric-label(-3.5,  $cs), '-3.5', "default numeric-label works with negative Rat";
is numeric-label(-77,   $cs), '-77',  "default numeric-label works with negative Int";

is numeric-label(-0e2,  $cs), '-0',   "default numeric-label works with negative zero Num";
is numeric-label(0e12,  $cs), '0',    "default numeric-label works with positive zero Num";
is numeric-label(0.0,   $cs), '0',    "default numeric-label works with zero Rat";
is numeric-label(0,     $cs), '0',    "default numeric-label works with zero Int";

is numeric-label(2.2e1, $cs), '22',   "default numeric-label works with negative Num";
is numeric-label(6.0,   $cs),  '6',   "default numeric-label works with negative Rat";
is numeric-label(42,    $cs), '42',   "default numeric-label works with negative Int";


my $cs2 = Terminal::QuickCharts::ChartStyle.new(y-axis-round => 10);

is numeric-label(-1e1,  $cs2), '-10', "rounded numeric-label works with negative Num";
is numeric-label(-3.5,  $cs2),   '0', "rounded numeric-label works with negative Rat";
is numeric-label(-80,   $cs2), '-80', "rounded numeric-label works with negative Int";

# Don't overdefine rounded negative zero Num
is numeric-label(-0e2,  $cs2), '-0'|'0', "rounded numeric-label works with negative zero Num";
is numeric-label(0e12,  $cs2), '0',   "rounded numeric-label works with positive zero Num";
is numeric-label(0.0,   $cs2), '0',   "rounded numeric-label works with zero Rat";
is numeric-label(0,     $cs2), '0',   "rounded numeric-label works with zero Int";

is numeric-label(2.2e1, $cs2), '20',  "rounded numeric-label works with negative Num";
is numeric-label(6.0,   $cs2), '10',  "rounded numeric-label works with negative Rat";
is numeric-label(42,    $cs2), '40',  "rounded numeric-label works with negative Int";


my $cs3 = Terminal::QuickCharts::ChartStyle.new(y-axis-scale => .1);

is numeric-label(-1e1,  $cs3), '-1',    "scaled numeric-label works with negative Num";
is numeric-label(-3.5,  $cs3), '-0.35', "scaled numeric-label works with negative Rat";
is numeric-label(-77,   $cs3), '-7.7',  "scaled numeric-label works with negative Int";

is numeric-label(-0e2,  $cs3), '-0',    "scaled numeric-label works with negative zero Num";
is numeric-label(0e12,  $cs3), '0',     "scaled numeric-label works with positive zero Num";
is numeric-label(0.0,   $cs3), '0',     "scaled numeric-label works with zero Rat";
is numeric-label(0,     $cs3), '0',     "scaled numeric-label works with zero Int";

is numeric-label(2.2e1, $cs3), '2.2',   "scaled numeric-label works with negative Num";
is numeric-label(6.0,   $cs3), '0.6',   "scaled numeric-label works with negative Rat";
is numeric-label(42,    $cs3), '4.2',   "scaled numeric-label works with negative Int";


my $cs4 = Terminal::QuickCharts::ChartStyle.new(y-axis-scale => 4, y-axis-round => 10);

is numeric-label(-1e1,  $cs4),  '-40', "scaled rounded numeric-label works with negative Num";
is numeric-label(-3.5,  $cs4),  '-10', "scaled rounded numeric-label works with negative Rat";
is numeric-label(-77,   $cs4), '-310', "scaled rounded numeric-label works with negative Int";

# Don't overdefine rounded negative zero Num
is numeric-label(-0e2,  $cs4), '-0'|'0', "scaled rounded numeric-label works with negative zero Num";
is numeric-label(0e12,  $cs4), '0',   "scaled rounded numeric-label works with positive zero Num";
is numeric-label(0.0,   $cs4), '0',   "scaled rounded numeric-label works with zero Rat";
is numeric-label(0,     $cs4), '0',   "scaled rounded numeric-label works with zero Int";

is numeric-label(2.2e1, $cs4), '90',  "scaled rounded numeric-label works with negative Num";
is numeric-label(6.0,   $cs4), '20',  "scaled rounded numeric-label works with negative Rat";
is numeric-label(42,    $cs4), '170', "scaled rounded numeric-label works with negative Int";


my $cs5 = Terminal::QuickCharts::ChartStyle.new(y-axis-scale => .1, y-axis-unit => 'm');

is numeric-label(-1e1,  $cs5), '-1 m',    "scaled numeric-label works with negative Num and unit";
is numeric-label(-3.5,  $cs5), '-0.35 m', "scaled numeric-label works with negative Rat and unit";
is numeric-label(-77,   $cs5), '-7.7 m',  "scaled numeric-label works with negative Int and unit";

is numeric-label(-0e2,  $cs5), '-0 m',    "scaled numeric-label works with negative zero Num and unit";
is numeric-label(0e12,  $cs5), '0 m',     "scaled numeric-label works with positive zero Num and unit";
is numeric-label(0.0,   $cs5), '0 m',     "scaled numeric-label works with zero Rat and unit";
is numeric-label(0,     $cs5), '0 m',     "scaled numeric-label works with zero Int and unit";

is numeric-label(2.2e1, $cs5), '2.2 m',   "scaled numeric-label works with negative Num and unit";
is numeric-label(6.0,   $cs5), '0.6 m',   "scaled numeric-label works with negative Rat and unit";
is numeric-label(42,    $cs5), '4.2 m',   "scaled numeric-label works with negative Int and unit";


my $cs6 = Terminal::QuickCharts::ChartStyle.new(y-axis-scale => 4, y-axis-round => 10, y-axis-unit => 's');

is numeric-label(-1e1,  $cs6),  '-40 s', "scaled rounded numeric-label works with negative Num and unit";
is numeric-label(-3.5,  $cs6),  '-10 s', "scaled rounded numeric-label works with negative Rat and unit";
is numeric-label(-77,   $cs6), '-310 s', "scaled rounded numeric-label works with negative Int and unit";

# Don't overdefine rounded negative zero Num
is numeric-label(-0e2,  $cs6), '-0 s'|'0 s', "scaled rounded numeric-label works with negative zero Num and unit";
is numeric-label(0e12,  $cs6), '0 s',   "scaled rounded numeric-label works with positive zero Num and unit";
is numeric-label(0.0,   $cs6), '0 s',   "scaled rounded numeric-label works with zero Rat and unit";
is numeric-label(0,     $cs6), '0 s',   "scaled rounded numeric-label works with zero Int and unit";

is numeric-label(2.2e1, $cs6), '90 s',  "scaled rounded numeric-label works with negative Num and unit";
is numeric-label(6.0,   $cs6), '20 s',  "scaled rounded numeric-label works with negative Rat and unit";
is numeric-label(42,    $cs6), '170 s', "scaled rounded numeric-label works with negative Int and unit";


# default-y-scaling(:$min!, :$max!, :$style!)
is-deeply default-y-scaling(:min(0), :max(0), :style($cs)),
          { y-axis-unit => '', y-axis-round => 1, y-axis-scale => 1 },
          "default-y-scaling(0..0) defaults are correct";

# XXXX: Lots more combos of default-y-scaling


done-testing;
