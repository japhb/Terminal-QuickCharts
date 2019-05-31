use v6.c;
unit module Terminal::QuickCharts:ver<0.0.1>;

use Terminal::ANSIColor;


#| Background hint for color maps
enum Background is export < Black White >;

#| Collect general chart style info in a unified structure
class ChartStyle {
    # Size attributes
    has UInt:D $.min-width      = 1;
    has UInt:D $.max-width      = screen-width;
    has UInt:D $.min-height     = 1;
    has UInt:D $.max-height     = screen-height;

    # Y Axis attributes
    has Bool:D $.show-y-axis    = True;
    has Str:D  $.y-axis-unit    = '';
    has Real:D $.y-axis-round   = 1;     # Round axis labels to nearest unit
    has Int    $.y-axis-scale;           # Not defined => auto

    # Misc attributes
    has UInt   $.lines-every;            # Chart lines every N cells if true
    has Bool:D $.show-overflow  = True;  # Add arrows to indicate overflowed data
    has Bool:D $.show-legend    = True;  # Show color legend if needed
    has Background $.background = Black;
}


sub screen-height(--> UInt:D) {
    if ::("Terminal::Print") -> \TP {
        (PROCESS::<$TERMINAL> || TP.new).rows
    }
    else {
        +qx/tput lines/ || 24
    }
}

sub screen-width(--> UInt:D) {
    if ::("Terminal::Print") -> \TP {
        (PROCESS::<$TERMINAL> || TP.new).columns
    }
    else {
        +qx/tput cols/ || 80
    }
}


sub pick-color($color-rule, $item) {
    given $color-rule {
        when Seq         { .flat[$item]             } # e.g. < red white > xx *
        when Positional  { .[$item] // .[*-1] // '' } # last color auto-repeats
        when Associative { .{$item}                 } # no default!
        when Callable    { .($item)                 } # calculate color
        default          { $_                       } # fixed (or no) color
    }
}


multi colorize(Str:D $text, $color --> Str:D) {
    $color ?? colored($text, $color) !! $text
}

multi colorize(Str:D $text, $color-rule, $item --> Str:D) {
    colorize($text, pick-color($color-rule, $item))
}


sub hpad(Int:D $pad-length, UInt :$lines-every, UInt :$pos = 0 --> Str:D) {
    return '' unless $pad-length > 0;

    my $pad = ' ' x $pad-length;
    if $pad-length && $lines-every {
        my $start = $lines-every - $pos % $lines-every;
        for $start, $start + $lines-every ... * {
            last if $_ > $pad-length - 1;
            $pad.substr-rw($_, 1) = '▏';
        }
    }

    $pad
}

sub numeric-label(Real:D $value, ChartStyle:D $style) {
    my $val = ($value * ($style.y-axis-scale || 1)).round($style.y-axis-round);
    $style.y-axis-unit ?? "$val $style.y-axis-unit()" !! $val
}


my %frame-time-style-defaults =
    lines-every  => 2,
    y-axis-scale => 1000,
    y-axis-unit  => 'ms';

multi auto-chart('frame-time', @data,
                 ChartStyle:D :$style = ChartStyle.new(|%frame-time-style-defaults),
                 UInt:D :$target-fps = 60, Bool:D :$stats = True) is export {

    return unless @data && $target-fps;

    # XXXX: This feels hackish.  Probably worth a rethink.
    my $s = $style.lines-every.defined ?? $style !! $style.clone(:lines-every(2));

    my @graph;

    my $max       = @data.max;
    my $row-delta = 1 / $target-fps;
    my $width     = screen-width;
    if $s.show-y-axis {
        my $max-label   = numeric-label($max, $style);
        my $label-width = ($max-label ~ '▕').chars;
        $width -= $label-width;
    }

    if @data <= $width {
        my @colors = < 34 226 202 160 white >;
        @graph = area-graph(@data, :$row-delta, :@colors, :style($s), :min(0), :$max);
        if $s.show-legend {
            my @fps    = (1 ..^ @colors).map: { floor $target-fps / $_ };
            my @ranges = "{@fps[0]}+",
                         |(^(@colors-2) .map: { "{@fps[$_+1]}-{@fps[$_]-1}" }),
                         "< {@fps[*-1]}";
            my @labels = @ranges.map: { "$_ fps" };
            my @key    = color-key(:@colors, :@labels);
            @graph.append: '', '   ' ~ join '  ', @key;
        }
    }
    else {
        @graph = smoke-chart(@data, :$width, :$row-delta, :style($s), :min(0), :$max);
    }

    if $stats {
        my ($frames, $min, $sum) = +@data, @data.min, @data.sum;
        if 0 < all($frames, $min, $max, $sum) {
            my $ave-time = $sum / $frames;
            my $ave-fps  = $frames / $sum;
            @graph.append: '', sprintf("Average: %.1f ms (%.3f fps)",
                                       $ave-time * 1000, $ave-fps);
        }
    }

    @graph
}


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


#| Render a single horizontal bar (presumably from a bar chart), padded out to
#| $width, optionally with chart lines drawn at an interval of $lines-every
#| character cells.  $min is the value at the left end, and $max the value at
#| the far right (including the padding).  The solid bar segment can be
#| optionally colored $color.
sub hbar(Real:D $value, :$color, UInt :$lines-every,
         Real:D :$min!, Real:D :$max! where $max > $min,
         UInt:D :$width! where * > 0 --> Str:D) is export {

    return ' ' x $width if $value <= $min;
    return '█' x $width if $value >= $max;

    my $cell  = ($max - $min) / $width;
    my $pos   = ($value - $min) / $cell;
    my $frac8 = (($pos - $pos.floor) * 8).floor;
    my $bar   = '█' x $pos.floor
              ~ ((0x2590 - $frac8).chr if $frac8);
    my $pad   = hpad($width - $pos.ceiling, :$lines-every, :pos($bar.chars));

    colorize($bar, $color) ~ $pad
}


#| Render a single stacked horizontal bar (presumably from a bar chart), made
#| from a series of bar segments colored in order of @colors and padded out to
#| $width, optionally with chart lines drawn at an interval of $lines-every
#| character cells.  $min is the value at the left end, and $max the value at
#| the far right (including the padding).
sub stacked-hbar(@values, :@colors, UInt :$lines-every,
                 Real:D :$min!, Real:D :$max! where $max > $min,
                 UInt:D :$width! where * > 0 --> Str:D) is export {

    my $cell      = ($max - $min) / $width;
    my $old-val   = $min;
    my $cur-val   = 0;
    my $cur-frac  = 0;
    my $pos       = 0;
    my $bar       = '';
    my $sliver    = '';
    my $old-color = '';

    for @values.kv -> $i, $value {
        # Make sure new bar isn't hidden behind other bars or the borders
        $cur-val = min($cur-val + $value, $max);
        next unless $cur-val > $old-val;

        my $color = pick-color(@colors, $i);

        # Finish off left-over sliver from previous bar
        #
        # Note: Because a unicode block can only have two colors, it is
        #       possible for a second very narrow bar in the block to take more
        #       space than it should have, possibly even hiding a third very
        #       narrow bar that should appear right after it.
        if $cur-frac {
            my $colors  = $color ?? "$old-color on_$color" !! $old-color;
            $bar       ~= colorize($sliver, $colors);
            $old-val   += $cell - $cur-frac;
            $cur-frac   = 0;
            $pos++;
            next unless $cur-val > $old-val;
        }

        # $old-val already corrected for piece that fit in the previous block
        my $cells = ($cur-val - $old-val) / $cell;
        my $floor = $cells.floor;
        my $frac  = $cells - $floor;
        my $chunk = '█' x $floor;
        $bar ~= colorize($chunk, $color) if $chunk;
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
        $bar ~= colorize($sliver, $old-color);
        $pos++;
    }

    # If bar is too short, pad it
    my $pad-length = $width - $pos;
    my $pad = hpad($pad-length, :$lines-every, :$pos);

    $bar ~ $pad
}


#| Render the bars for a horizontal bar chart, padded out to $width, and
#| optionally with chart lines drawn at an interval of $lines-every character
#| cells.  $min is the value at the left end of each bar, and $max the value at
#| the far right (including the padding).
#|
#| hbar-chart() works in four modes, depending on whether the data is one- or
#| two-dimensional, and whether $stacked is True or not.  If the data is
#| one-dimensional, then hbar-chart() will either produced a single stacked
#| horizontal bar made from all data points (if $stacked is True), or one
#| simple bar per data point (if $stacked is False), separated by $bar-spacing
#| rows containing only chart lines.
#|
#| If the data is two-dimensional, then hbar-chart() produces either a series
#| of stacked bars (if $stacked is True), each separated by $bar-spacing lines,
#| or groups of simple bars packed together (if $stacked is False), with each
#| group separated by $bar-spacing lines containing only chart lines.
sub hbar-chart(@data, :@colors, Bool :$stacked, UInt :$lines-every,
               Real:D :$min!, Real:D :$max! where $max > $min,
               UInt:D :$width! where * > 0, UInt :$bar-spacing = 0) is export {

    return unless @data;

    # A padded line to place between bars, with proper chart lines if requested
    my $blank-line = stacked-hbar([], :$lines-every, :$min, :$max, :$width);

    # Data is two dimensional
    if @data[0] ~~ Iterable {
        # Stacked bar per @data subarray
        if $stacked {
            my @bars = gather for @data.kv -> $i, @values {
                take stacked-hbar(@values, :@colors, :$lines-every, :$min, :$max, :$width);
                last if $i == @data.end;
                take $blank-line for ^$bar-spacing;
            }
        }
        # Group of simple bars per @data subarray
        else {
            my @bars = gather for @data.kv -> $i, @values {
                for @values.kv -> $j, $value {
                    take hbar($value, :$min, :$max, :$width, :$lines-every,
                              :color(pick-color(@colors, $j)));
                }
                last if $i == @data.end;
                take $blank-line for ^$bar-spacing;
            }
        }
    }
    # Data is one dimensional
    else {
        # A single stacked bar
        if $stacked {
            stacked-hbar(@data, :@colors, :$lines-every, :$min, :$max, :$width),;
        }
        # Ungrouped simple bars
        else {
            my @bars = gather for @data.kv -> $i, $value {
                take hbar($value, :$min, :$max, :$width, :$lines-every,
                          :color(pick-color(@colors, $i)));
                last if $i == @data.end;
                take $blank-line for ^$bar-spacing;
            }
        }
    }
}


# Calculate the heatmap color ramp once
# Default ramp is for white backround; reverse for black background
my @heatmap-colors =
    (5, 5, 5),                                              # White
    (5, 5, 4), (5, 5, 3), (5, 5, 2), (5, 5, 1), (5, 5, 0),  # Pale to bright yellow
    (5, 4, 0), (5, 3, 0), (5, 2, 0), (5, 1, 0), (5, 0, 0),  # Yellow-orange to red
    (4, 0, 0), (3, 0, 0), (2, 0, 0), (1, 0, 0), (0, 0, 0);  # Brick red to black

my @heatmap-ramp = @heatmap-colors.map: { ~(16 + 36 * .[0] + 6 * .[1] + .[2]) }


sub smoke-chart(@data, Real:D :$row-delta!, UInt:D :$width,
                Real:D :$min = min(0, @data.min), Real:D :$max = @data.max,
                ChartStyle:D :$style = ChartStyle.new) is export {
    my $delta   = $max - $min;
    my $rows    = max 1, min $style.max-height, max $style.min-height,
                                                    ceiling($delta / $row-delta);
    my @pixels  = [] xx 2 * $rows;
    my $x-scale =    $width / (@data  || 1);
    my $y-scale = 2 * $rows / ($delta || 1);

    for @data.kv -> $i, $value {
        my $x = floor $x-scale * $i;
        my $y = floor $y-scale * ($value - $min);
        @pixels[$y][$x]++;
    }

    my @colors = $style.background == Black ?? @heatmap-ramp.reverse !! @heatmap-ramp;
    my $scale  = @colors * $width < @data ?? @colors * $width / @data !! 1;

    my @rows;
    my @cell-cache;
    for ^$rows .reverse -> int $y {
        my $top  = @pixels[$y * 2 + 1];
        my $bot  = @pixels[$y * 2];
        my $rule = +($style.lines-every && $y %% $style.lines-every);
        my $line = $rule ?? 'underline ' !! '';

        @rows.push: join '', ^$width .map: -> int $x {
            my int $v1 = ceiling ($top[$x] // 0) * $scale;
            my int $v2 = ceiling ($bot[$x] // 0) * $scale;
            @cell-cache[$rule][$v1][$v2] //=
                $v1 == $v2 ?? colored(' ', "{$line}on_" ~ pick-color(@colors, $v1)) !!
                              colored('▀',       $line  ~ pick-color(@colors, $v1) ~
                                                 ' on_' ~ pick-color(@colors, $v2))
        }
    }

    @rows
}


sub general-vertical-chart(@data, Real:D :$row-delta!, :$colors!, Real:D :$min!,
                           Real:D :$max!, ChartStyle:D :$style!, :&content!) {
    # Basic sizing
    my $delta = $max - $min;
    my $width = max 1, min $style.max-width,  max $style.min-width, +@data;
    my $rows  = max 1, min $style.max-height, max $style.min-height,
                                                  ceiling($delta / $row-delta);
    my $cap   = $rows * $row-delta + $min;

    # Determine whether overflow indicator row is needed and correct for it
    my $do-overflow = False;
    if $style.show-overflow && $max > $cap {
        $rows--;
        $cap -= $row-delta;
        $do-overflow = True;
    }

    # Determine max label width, if y-axis labels are actually desired
    my $label-width = max numeric-label($cap, $style).chars,
                          numeric-label($min, $style).chars;

    if $style.show-y-axis {
        # Make room for labels and axis line
        $width = max 1, $width - ($label-width + 1);
    }

    # Actually generate the graph content
    my @rows := content(@data, :$rows, :$row-delta, :$min, :$max, :$cap,
                        :$width, :$colors, :$style, :$do-overflow);

    # Add the y-axis and labels if desired
    if $style.show-y-axis {
        for ^@rows {
            my $row   = $rows - 1 - $_;
            my $value = $row * $row-delta + $min;
            my $show  = $row %% ($style.lines-every || 2);
            my $label = $show ?? numeric-label($value, $style) !! '';
            @rows[$_] = sprintf("%{$label-width}s▕", $label) ~ @rows[$_];
        }
    }

    @rows;
}


sub area-graph(@data, Real:D :$row-delta!, :$colors,
               Real:D :$min = min(0, @data.min), Real:D :$max = @data.max,
               ChartStyle:D :$style = ChartStyle.new) is export {

    general-vertical-chart(@data, :$row-delta, :$colors, :$min, :$max, :$style,
                           :content(&area-graph-content))
}


# Internal sub, generating just the inner content of the chart (no axes or key)
sub area-graph-content(@data, UInt:D :$rows!, Real:D :$row-delta!,
                       Real:D :$min!, Real:D :$max!, Real:D :$cap!,
                       UInt:D :$width!, :$colors!, ChartStyle:D :$style!,
                       Bool:D :$do-overflow!) {
    my @rows;

    # If data spikes are too tall to fit in graph, use top row to indicate that
    if $do-overflow {
        my $top-row = @data.map({ $_ > $cap ?? '↑' !! ' '}).join;
        @rows.push: colorize($top-row, $colors, $rows);
    }

    for ^$rows .reverse -> $row {
        my $bot = $row * $row-delta + $min;
        my $top = $bot + $row-delta;

        my $rule = $style.lines-every && $row %% $style.lines-every ?? '_' !! ' ';
        my $bars = @data.map({
            $_ >= $top ?? '█'   !!
            $_ <= $bot ?? $rule !! (0x2581 + floor(($_ - $bot) / $row-delta * 8)).chr;
        }).join;
        @rows.push: colorize($bars, $colors, $row);
    }

    @rows
}


=begin pod

=head1 NAME

Terminal::QuickCharts - Simple charts for CLI tools

=head1 SYNOPSIS

=begin code :lang<perl6>

use Terminal::QuickCharts;

=end code

=head1 DESCRIPTION

Terminal::QuickCharts provides a small library of simple text-output charts,
suitable for spruicing up command-line reporting and quick analysis tools.  The
emphasis here is more on whipuptitude, and less on manipulexity.

=head1 AUTHOR

Geoffrey Broadwell <gjb@sonic.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
