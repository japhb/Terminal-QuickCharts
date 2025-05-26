# ABSTRACT: Chart pieces with all params explicit (not using ChartStyle)

unit module Terminal::QuickCharts::Pieces;

use Terminal::ANSIColor;
use Terminal::QuickCharts::Helpers;


# XXXX: What about RTL (Right To Left) languages and charts?


#| Figure out reasonable defaults for numeric axis unit/rounding/scaling.
sub default-numeric-scaling(Real:D :$min!, Real:D :$max!,
                            Real :$scale is copy, Real :$round is copy,
                            Str:D :$unit is copy = '',
                            Bool:D :$binary = False) is export {
    my $scale-by = $binary ?? 1024 !! 1000;
    my $max-abs  = max $min.abs, $max.abs;
    my $delta    = abs($max - $min);

    my @prefixes = |< y z a f p n μ m >, '', |< k M G T P E Z Y >;
    my $index    = @prefixes.first: !*, :k;
    @prefixes[$index + 1] .= uc if $binary;

    unless $scale {
        $scale = 1;
        while $max-abs * $scale > $scale-by {
            $scale /= $scale-by;
            $index++;
            last if $index >= @prefixes - 1;
        }
        while $max-abs && $max-abs * $scale < 1 {
            $scale *= $scale-by;
            $index--;
            last if $index <= 0;
        }
    }

    $round ||= $delta && $delta * $scale <= 20 ?? .1 !! 1;
    $unit    = @prefixes[$index] ~ ('i' if $binary) ~ $unit;

    { :$unit, :$round, :$scale }
}


#| Render the text for a numeric label, including scaling and rounding
#| the value, and appending a unit if any.
sub numeric-label(Real:D $value, Real :$scale, Real :$round, Str :$unit) is export {
    my $val = $value * ($scale || 1);

    if $round {
        $val .= round($round);
        if $round < 1 {
            my $digits = -($round.log10.floor);
            $val .= fmt("%.{$digits}f");
        }
    }

    $unit ?? "$val $unit" !! $val
}


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
sub hpad(Int:D $pad-length, :$color is copy, :$line-color,
         UInt :$lines-every, UInt :$pos = 0 --> Str:D) is export {
    return '' unless $pad-length > 0;

    $color = $color ?? ($line-color ?? "$line-color on_$color" !! "on_$color")
                    !! ($line-color ??  $line-color            !! '');

    my $pad = ' ' x $pad-length;
    if $pad-length && $lines-every {
        my $offset = $pos % $lines-every;
        my $start  = $offset ?? $lines-every - $offset !! 0;
        for $start, $start + $lines-every ... * {
            last if $_ > $pad-length - 1;
            $pad.substr-rw($_, 1) = '▏';
        }
    }

    colorize($pad, $color)
}


#| Render a single horizontal bar (presumably from a bar chart), padded out to
#| $width, optionally with chart lines drawn at an interval of $lines-every
#| character cells.  $min is the value at the left end, and $max the value at
#| the far right (including the padding).  The solid bar segment can be
#| optionally colored $color.
sub hbar(Real:D $value, :$color is copy, :$bg-color, :$line-color,
         UInt :$lines-every,
         Real:D :$min!, Real:D :$max! where $max > $min,
         UInt:D :$width! where * > 0 --> Str:D) is export {

    $value <= $min ?? hpad($width, :$lines-every, :pos(0),
                           :color($bg-color), :$line-color) !!
    $value >= $max ?? colorize('█' x $width, $color)        !!
    do {
        $color  //= '';
        $color    = "on_$bg-color $color" if $bg-color;
        my $cell  = ($max - $min) / $width;
        my $pos   = ($value - $min) / $cell;
        my $frac8 = (($pos - $pos.floor) * 8).floor;
        my $bar   = '█' x $pos.floor
                  ~ ((0x2590 - $frac8).chr if $frac8);
        my $pad   = hpad($width - $bar.chars, :color($bg-color), :$line-color,
                         :$lines-every, :pos($bar.chars));

        (colorize($bar, $color) if $bar) ~ $pad
    }
}


#| Render a single stacked horizontal bar (presumably from a bar chart), made
#| from a series of bar segments colored in order of @colors and padded out to
#| $width, optionally with chart lines drawn at an interval of $lines-every
#| character cells.  $min is the value at the left end, and $max the value at
#| the far right (including the padding).
sub stacked-hbar(@values, :@colors, :$bg-color, :$line-color, UInt :$lines-every,
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
        $old-color = "$old-color on_$bg-color" if $bg-color;
        @spans.push: $sliver => $old-color;
        $pos++;
    }

    # If bar is too short, pad it
    my $pad-length = $width - $pos;
    my $pad = hpad($pad-length, :$lines-every, :$pos,
                   :color($bg-color), :$line-color);

    join-colorized-spans(@spans) ~ $pad
}
