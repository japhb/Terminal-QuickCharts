# ABSTRACT: Chart pieces with all params explicit (not using ChartStyle)

unit module Terminal::QuickCharts::Pieces;

use Terminal::ANSIColor;
use Terminal::QuickCharts::Helpers;


# XXXX: What about RTL (Right To Left) languages and charts?


#| Render a color key for the colors in a chart, returning a list of ANSI
#| colored strings, each with a colored bar and a label.  Several variants
#| exist for different ways of specifying the colors and their matching
#| labels.
proto color-key(| --> Iterable) is export {*}

#| Render a color key for the colors in a chart, returning a list of ANSI
#| colored strings, each with a colored bar and a label.  This variant takes
#| the colors and labels as separate arrays.
multi color-key(:@colors!, :@labels! --> Iterable) {
    my @pairs = @labels Z=> @colors;
    color-key(@pairs)
}

#| Render a color key for the colors in a chart, returning a list of ANSI
#| colored strings, each with a colored bar and a label.  This variant takes
#| a map of label => color and sorts the key lexicographically by label.
multi color-key(%colors --> Iterable) {
    color-key(%colors.sort)
}

#| Render a color key for the colors in a chart, returning a list of ANSI
#| colored strings, each with a colored bar and a label.  This variant takes
#| an ordered list of label => color pairs.
multi color-key(@pairs --> Iterable) {
    @pairs.map: { colored('███', .value) ~ ' ' ~ .key }
}


#| Render a single span of horizontal chart padding, optionally with chart
#| lines added every $lines-every columns, with chart line phase determined by
#| $pos (usually the visual width of whatever was to the left of the padding).
sub hpad(Int:D $pad-length, UInt :$lines-every, UInt :$pos = 0 --> Str:D) is export {
    return '' unless $pad-length > 0;

    my $pad = ' ' x $pad-length;
    if $pad-length && $lines-every {
        my $offset = $pos % $lines-every;
        my $start  = $offset ?? $lines-every - $offset !! 0;
        for $start, $start + $lines-every ... * {
            last if $_ > $pad-length - 1;
            $pad.substr-rw($_, 1) = '▏';
        }
    }

    $pad
}


#| Render a single horizontal bar (presumably from a bar chart), padded out to
#| $width, optionally with chart lines drawn at an interval of $lines-every
#| character cells.  $min is the value at the left end, and $max the value at
#| the far right (including the padding).  The solid bar segment can be
#| optionally colored $color.
sub hbar(Real:D $value, :$color, UInt :$lines-every,
         Real:D :$min!, Real:D :$max! where $max > $min,
         UInt:D :$width! where * > 0 --> Str:D) is export {

    return hpad($width, :$lines-every, :pos(0)) if $value <= $min;
    return colorize('█' x $width, $color)       if $value >= $max;

    my $cell  = ($max - $min) / $width;
    my $pos   = ($value - $min) / $cell;
    my $frac8 = (($pos - $pos.floor) * 8).floor;
    my $bar   = '█' x $pos.floor
              ~ ((0x2590 - $frac8).chr if $frac8);
    my $pad   = hpad($width - $bar.chars, :$lines-every, :pos($bar.chars));

    (colorize($bar, $color) if $bar) ~ $pad
}


#| Render a single stacked horizontal bar (presumably from a bar chart), made
#| from a series of bar segments colored in order of @colors and padded out to
#| $width, optionally with chart lines drawn at an interval of $lines-every
#| character cells.  $min is the value at the left end, and $max the value at
#| the far right (including the padding).
sub stacked-hbar(@values, :@colors, UInt :$lines-every,
                 Real:D :$min!, Real:D :$max! where $max > $min,
                 UInt:D :$width! where * > 0 --> Str:D) is export {

    # Filter out nonpositive values, and merge same-colored values
    my @vals;
    for @values.kv -> $i, $value {
        next unless $value > 0;
        my $color = pick-color(@colors, $i);
        if @vals && $color eq @vals[*-1][1] {
            @vals[*-1][0] += $value;
        }
        else {
            @vals.push: [$value, $color];
        }
    }

    # Main bar generation loop
    my $cell      = ($max - $min) / $width;
    my $old-val   = $min;
    my $cur-val   = 0;
    my $cur-frac  = 0;
    my $pos       = 0;
    my $sliver    = '';
    my $old-color = '';
    my @spans;

    for @vals -> [ $value, $color ] {
        # Make sure new bar isn't hidden behind other bars or the borders
        $cur-val = min($cur-val + $value, $max);
        next unless $cur-val > $old-val;

        # Finish off left-over sliver from previous bar
        #
        # Note: Because a unicode block can only have two colors, it is
        #       possible for a second very narrow bar in the block to take more
        #       space than it should have, possibly even hiding a third very
        #       narrow bar that should appear right after it.
        if $cur-frac {
            my $colors  = $color ?? "$old-color on_$color" !! $old-color;
            @spans.push:  $sliver => $colors;
            $old-val   += $cell * (1 - $cur-frac);
            $cur-frac   = 0;
            $pos++;
            next unless $cur-val > $old-val;
        }

        # $old-val already corrected for piece that fit in the previous block
        my $cells = ($cur-val - $old-val) / $cell;
        my $floor = $cells.floor;
        my $frac  = $cells - $floor;
        my $chunk = '█' x $floor;
        @spans.push: $chunk => $color;
        $pos += $floor;

        # If the leftover fraction is big enough to be visible, save the sliver
        # to be combined with the start of the next bar
        if $frac >= 1/8 {
            $cur-frac  = $frac;
            $old-val   = $cur-val;
            $old-color = $color;
            $sliver    = (0x2590 - ($frac * 8).floor).chr;
        }
        # Otherwise drop the remaining invisible fraction
        else {
            $old-val = $old-val + $floor * $cell;
        }
    }

    # Possibly a leftover sliver from last bar
    if $cur-frac {
        @spans.push: $sliver => $old-color;
        $pos++;
    }

    # If bar is too short, pad it
    my $pad-length = $width - $pos;
    my $pad = hpad($pad-length, :$lines-every, :$pos);

    join-colorized-spans(@spans) ~ $pad
}
