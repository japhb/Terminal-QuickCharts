use Test;
use Terminal::QuickCharts::Helpers;


plan 46;


# screen-width() and screen-height()
ok screen-height() ~~ UInt, 'screen-height fallback is still a UInt';
ok screen-width()  ~~ UInt, 'screen-width fallback is still a UInt';
ok screen-height() >= 1, 'screen-height fallback is positive';
ok screen-width()  >= 1, 'screen-width fallback is positive';


# pick-color($color-rule, $item)
is-deeply pick-color(Nil, Nil), '',  'pick-color pass-through: Nil, Nil --> empty Str';
is-deeply pick-color(Nil,  1 ), '',  'pick-color pass-through: Nil, Int --> empty Str';
is-deeply pick-color(Nil, 'a'), '',  'pick-color pass-through: Nil, Str --> empty Str';
is-deeply pick-color( 2 , Nil), '2', 'pick-color pass-through: Int, Nil --> ~Int';
is-deeply pick-color( 2 ,  1 ), '2', 'pick-color pass-through: Int, Int --> ~Int';
is-deeply pick-color( 2 , 'a'), '2', 'pick-color pass-through: Int, Str --> ~Int';
is-deeply pick-color('b', Nil), 'b', 'pick-color pass-through: Str, Nil --> Str';
is-deeply pick-color('b',  1 ), 'b', 'pick-color pass-through: Str, Int --> Str';
is-deeply pick-color('b', 'a'), 'b', 'pick-color pass-through: Str, Str --> Str';

my %colors = c => 'd', 3 => 4;
is-deeply pick-color(%colors, 'c'), 'd', 'pick-color Associative: Str --> Str';
is-deeply pick-color(%colors,  3 ), '4', 'pick-color Associative: Int --> ~Int';
is-deeply pick-color(%colors, 'q'), '',  'pick-color Associative: missing --> empty Str';

my @colors = 5, 'e';
is-deeply pick-color(@colors, 0), '5', 'pick-color Positional: --> ~Int';
is-deeply pick-color(@colors, 1), 'e', 'pick-color Positional: --> Str';
is-deeply pick-color(@colors, 2), 'e', 'pick-color Positional: repeat last color 1';
is-deeply pick-color(@colors, 3), 'e', 'pick-color Positional: repeat last color 2';

my $colors = (6, 'f') xx *;
is-deeply pick-color($colors, 0), '6', 'pick-color Seq: --> ~Int';
is-deeply pick-color($colors, 1), 'f', 'pick-color Seq: --> Str';
is-deeply pick-color($colors, 2), '6', 'pick-color Seq: handles repeats 1';
is-deeply pick-color($colors, 3), 'f', 'pick-color Seq: handles repeats 2';

sub colors($item) { $item.flip }
is-deeply pick-color(&colors, 'foo'), 'oof', 'pick-color Callable 1';
is-deeply pick-color(&colors, 'bar'), 'rab', 'pick-color Callable 2';


# colorize($text, $color)
is colorize('',     Nil), '',     'colorize pass-through: empty Str, Nil --> empty Str';
is colorize('blah', Nil), 'blah', 'colorize pass-through: Str, Nil --> Str';
is colorize('',     Any), '',     'colorize pass-through: empty Str, Any --> empty Str';
is colorize('blah', Any), 'blah', 'colorize pass-through: Str, Any --> Str';
is colorize('',     Str), '',     'colorize pass-through: empty Str, Str:U --> empty Str';
is colorize('blah', Str), 'blah', 'colorize pass-through: Str, Str:U --> Str';
is colorize('',     '' ), '',     'colorize pass-through: empty Str, empty Str --> empty Str';
is colorize('blah', '' ), 'blah', 'colorize pass-through: Str, empty Str --> Str';

is colorize('',     0),   "\e[38;5;0m\e[0m",       'colorize 0: empty Str, 0 --> 0-colored empty';
is colorize('blah', 0),   "\e[38;5;0mblah\e[0m",   'colorize 0: Str, 0 --> 0-colored text';
is colorize('',     196), "\e[38;5;196m\e[0m",     'colorize Int: empty Str, 196 --> 196-colored empty';
is colorize('blah', 196), "\e[38;5;196mblah\e[0m", 'colorize Int: Str, 196 --> 196-colored text';
is colorize('',     'red'), "\e[31m\e[0m",         'colorize Str: empty Str, red --> red-colored empty';
is colorize('blah', 'red'), "\e[31mblah\e[0m",     'colorize Str: Str, red --> red-colored text';


# colorize($text, $color-rule, $item)
is colorize('baz', '',                 7 ), 'baz',            'colorize by rule: empty Str';
is colorize('baz', 'blue',             12), "\e[34mbaz\e[0m", 'colorize by rule: Str';
is colorize('baz', { g => 'yellow' }, 'g'), "\e[33mbaz\e[0m", 'colorize by rule: Associative';
is colorize('baz', < red white >,       4), "\e[37mbaz\e[0m", 'colorize by rule: Positional';
is colorize('baz', < bold green > xx *, 4), "\e[1mbaz\e[0m",  'colorize by rule: Seq';
is colorize('baz', -> $i { 'cyan' },    3), "\e[36mbaz\e[0m", 'colorize by rule: Callable';


done-testing;
