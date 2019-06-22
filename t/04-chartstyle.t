use Test;
use Terminal::QuickCharts::ChartStyle;


plan 94;


# enum Terminal::QuickCharts::Background
ok Dark  ~~ Terminal::QuickCharts::Background, "Dark is a valid Background";
ok Light ~~ Terminal::QuickCharts::Background, "Light is a valid Background";


# Minimal type checks for ChartStyle instances
sub type-check($cs, $test-set) {
    ok $cs ~~ Terminal::QuickCharts::ChartStyle:D, "$test-set ChartStyle.new works";

    ok $cs.min-width     ~~ UInt:D, "$test-set min-width is a defined UInt";
    ok $cs.max-width     ~~ UInt:D, "$test-set max-width is a defined UInt";
    ok $cs.min-height    ~~ UInt:D, "$test-set min-height is a defined UInt";
    ok $cs.max-height    ~~ UInt:D, "$test-set max-height is a defined UInt";

    ok $cs.show-y-axis   ~~ Bool:D, "$test-set show-y-axis is a defined Bool";
    ok $cs.y-axis-unit   ~~ Str:D,  "$test-set y-axis-unit is a defined Str";
    ok $cs.y-axis-round  ~~ Real,   "$test-set y-axis-round is a Real";
    ok $cs.y-axis-scale  ~~ Real,   "$test-set y-axis-scale is a Real";

    ok $cs.lines-every   ~~ UInt,   "$test-set lines-every is a UInt";
    ok $cs.show-overflow ~~ Bool:D, "$test-set show-overflow is a defined Bool";
    ok $cs.show-legend   ~~ Bool:D, "$test-set show-legend is a defined Bool";

    ok $cs.background    ~~ Terminal::QuickCharts::Background:D,
                            "$test-set background is a defined Background";
}


# class Terminal::QuickCharts::ChartStyle -- defaults
my $cs = Terminal::QuickCharts::ChartStyle.new;
type-check($cs, 'default');

ok $cs.min-width  == 1,              "default min-width  == 1";
ok $cs.min-height == 1,              "default min-height == 1";
ok $cs.max-width  >= $cs.min-width,  "default max-width  >= min-width";
ok $cs.max-height >= $cs.min-height, "default max-height == min-height";

ok $cs.show-y-axis,           "default show-y-axis is True";
ok $cs.show-legend,           "default show-legend is True";
ok $cs.show-overflow,         "default show-overflow is True";

is $cs.y-axis-unit, '',       "default y-axis-unit is ''";
ok $cs.background == Dark,    "default background is Dark";

nok $cs.y-axis-round.defined, "default y-axis-round is undefined";
nok $cs.y-axis-scale.defined, "default y-axis-scale is undefined";
nok $cs.lines-every.defined,  "default lines-every is undefined";


# style-with-defaults($style, %defaults)
my %defaults = show-y-axis => False, y-axis-unit => 'z',
               y-axis-round => 10,  y-axis-scale => 0;
my $cs2 = style-with-defaults($cs, %defaults);
type-check($cs2, 'clone');

ok  $cs2.show-y-axis, "clone of true value is unchanged";
nok $cs2.y-axis-unit, "clone of false defined value is unchanged";

ok  $cs2.y-axis-round == 10, "clone replacing undefined with a true value succeeds";
ok  $cs2.y-axis-scale == 0,  "clone replacing undefined with a false value succeeds";


# style-with-defaults(%style, %defaults)
my %style = y-axis-unit => 's', y-axis-scale => .1, show-overflow => False;
my $cs3 = style-with-defaults(%style, %defaults);
type-check($cs3, 'two-hash');

ok $cs3.show-overflow == False, "style overrided true class defaults";
ok $cs3.y-axis-unit   eq 's',   "style overrides false class defaults";
ok $cs3.y-axis-scale  == .1,    "style overrides hash defaults";


# style-with-defaults(%defaults)
my $cs4 = style-with-defaults(%defaults);
type-check($cs4, 'defaults-only');

nok $cs4.show-y-axis,        "new overriding true value succeeds";
is  $cs4.y-axis-unit, 'z',   "new overriding defined false value succeeds";
ok  $cs4.y-axis-round == 10, "new overriding undefined with a true value succeeds";
ok  $cs4.y-axis-scale == 0,  "new overriding undefined with a false value succeeds";


# style-with-defaults($style)
my $cs5 = style-with-defaults($cs4);
type-check($cs5, 'pass-through');

nok $cs5.show-y-axis,        "overriden true value remains";
is  $cs5.y-axis-unit, 'z',   "overriden defined false value remains";
ok  $cs5.y-axis-round == 10, "overriden undefined with a true value remains";
ok  $cs5.y-axis-scale == 0,  "overriden undefined with a false value remains";


done-testing;
