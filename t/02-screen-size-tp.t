use Test;
use Terminal::QuickCharts::Helpers;


# Test auto-detection of available Terminal::Print for determining screen size

plan 4;


class Terminal::Print {
    method rows    { 1 + (self === PROCESS::<$TERMINAL>) }
    method columns { 5 + (self === PROCESS::<$TERMINAL>) }
}

is screen-height, 1, 'Height from non-globalized Terminal::Print';
is screen-width,  5, 'Width from non-globalized Terminal::Print';

PROCESS::<$TERMINAL> = Terminal::Print.new;

is screen-height, 2, 'Height from global Terminal::Print';
is screen-width,  6, 'Width from global Terminal::Print';


done-testing;
