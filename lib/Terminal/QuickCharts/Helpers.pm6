unit module Terminal::QuickCharts::Helpers;

use Terminal::ANSIColor;


#| Determine screen height in rows, first attempting to use Terminal::Print if
#| loaded, then falling back to `tput`, and finally hardcoded 24 rows.
sub screen-height(--> UInt:D) is export {
    if (my \TP = ::('Terminal::Print')) !~~ Failure {
        (PROCESS::<$TERMINAL> || TP.new).rows
    }
    else {
        TP.so;   # defang Failure
        +qx/tput lines/ || 24
    }
}


#| Determine screen width in character cell columns, first attempting to use
#| Terminal::Print if loaded, then falling back to `tput`, and finally hardcoded
#| 80 columns.
sub screen-width(--> UInt:D) is export {
    if (my \TP = ::('Terminal::Print')) !~~ Failure {
        (PROCESS::<$TERMINAL> || TP.new).columns
    }
    else {
        TP.so;   # defang Failure
        +qx/tput cols/ || 80
    }
}


#| Pick a color using a color rule and an item.  The color rule can be any of
#| the following:
#|
#|    * Seq (in which case it is flattened and indexed into),
#|    * Positional (in which case it is indexed into, repeating the last color
#|      if needed),
#|    * Associative (in which case it is keyed with the item, with no default),
#|    * Callable (in which case it is called with the item as its only
#|      positional argument),
#|    * any other type (in which case the color rule is used as the color, for
#|      fixed or no color)
#|
#| If the picked color is defined, it is stringified; otherwise '' is returned.
sub pick-color($color-rule, $item --> Str:D) is export {
    my $color = do given $color-rule {
        when Seq         { .cache.flat[$item] } # e.g. < red white > xx *
        when Positional  { .[$item] // .[*-1] } # last color auto-repeats
        when Associative { .{$item}           } # no default!
        when Callable    { .($item)           } # calculate color
        default          { $_                 } # fixed (or no) color
    }

    $color.defined ?? ~$color !! ''
}


#| Optionally (if $color is true) color text using Terminal::ANSIColor
multi colorize(Str:D $text, $color --> Str:D) is export {
    $color ~~ Str:D  ?? ($color ?? colored($text,  $color) !! $text) !!
    $color ~~ Cool:D ??            colored($text, ~$color) !! $text
}

#| Pick a color using pick-color and then colorize text as per previous multi
multi colorize(Str:D $text, $color-rule, $item --> Str:D) is export {
    colorize($text, pick-color($color-rule, $item))
}
