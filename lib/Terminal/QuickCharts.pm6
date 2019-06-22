unit module Terminal::QuickCharts:ver<0.0.1>;

use Terminal::ANSIColor;
use Terminal::QuickCharts::Helpers;
use Terminal::QuickCharts::Pieces;
use Terminal::QuickCharts::ChartStyle;
use Terminal::QuickCharts::StyledPieces;


multi auto-chart('frame-time', @data, :$style,
                 UInt:D :$target-fps = 60, Bool:D :$stats = True) is export {

    return unless @data && $target-fps;

    my %frame-time-style-defaults =
        lines-every  => 2,
        y-axis-scale => 1000,
        y-axis-unit  => 'ms',
        y-axis-round => 1;

    my $s = style-with-defaults($style, %frame-time-style-defaults);

    my @graph;

    my $max       = @data.max;
    my $row-delta = 1 / $target-fps;
    my $width     = screen-width;
    if $s.show-y-axis {
        my $max-label   = numeric-label($max, $s);
        my $label-width = ($max-label ~ '▕').chars;
        $width -= $label-width;
    }

    my @colors = < 34 226 202 160 white >;
    if @data <= $width {
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
        @graph = smoke-chart(@data, :$row-delta, :style($s), :min(0), :$max);
    }

    if $stats {
        my ($frames, $min, $sum) = +@data, @data.min, @data.sum;
        if 0 < all($frames, $min, $max, $sum) {
            my $ave       = $sum / $frames;
            my $ave-fps   = $frames / $sum;
            my $min-fps   = 1 / $max;
            my $max-fps   = 1 / $min;
            my $min-color = pick-color(@colors, floor($min * $target-fps));
            my $ave-color = pick-color(@colors, floor($ave * $target-fps));
            my $max-color = pick-color(@colors, floor($max * $target-fps));
            my $info = sprintf(colored('Min: %.1f ms (%.1f fps)', $min-color) ~ ' - ' ~
                               colored('Ave: %.1f ms (%.1f fps)', $ave-color) ~ ' - ' ~
                               colored('Max: %.1f ms (%.1f fps)', $max-color),
                               $min * 1000, $max-fps,
                               $ave * 1000, $ave-fps,
                               $max * 1000, $min-fps);
            @graph.append: '', $info;
        }
    }

    @graph
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


# Provide common functionality used by all vertically-oriented charts;
# actual chart content rendering is handed off to &content, while sizing
# computations and axis/label rendering is done in this common code.
sub general-vertical-chart(@data, Real :$row-delta! is copy, :$colors!, Real:D :$min!,
                           Real:D :$max!, :$style!, :&content!) {

    # Make sure we have a defined ChartStyle instance
    my $s = style-with-defaults($style);

    # Basic sizing
    my $delta = $max - $min;
    my $rows;
    if $row-delta {
        $rows = max 1, min $s.max-height, max $s.min-height,
                                              ceiling($delta / $row-delta);
    }
    else {
        $rows = max 1, $s.max-height;
        $row-delta = $delta / $rows;

        # Auto-adjust row-delta to make convenient labels
        if $s.show-y-axis {
            my $labels-every = $s.lines-every || min 8, ($rows / 5).ceiling;
            my $label-delta  = $labels-every * $row-delta;
            my $pow10        = $label-delta.log10.floor;
            my $scaled       = $label-delta * 10 ** -$pow10;
            my $nearest      = (1, 1.2, 1.5, 2, 3, 4, 5, 6, 8, 10).first(* >= $scaled);
            my $adjusted     = $nearest * 10 ** $pow10;
            $row-delta       = $adjusted / $labels-every;
        }
    }
    my $cap = $rows * $row-delta + $min;

    # Determine whether overflow indicator row is needed and correct for it
    my $do-overflow = False;
    if $s.show-overflow && $max > $cap {
        $rows--;
        $cap -= $row-delta;
        $do-overflow = True;
    }

    # Compute and apply scaling defaults
    $s = style-with-defaults($s, default-y-scaling(:$min, :max($cap), :style($s)));

    # Determine max label width, if y-axis labels are actually desired,
    # and set content width to match
    my $label-width = max numeric-label($cap, $s).chars,
                          numeric-label($min, $s).chars;
    my $max-width = $s.max-width - $s.show-y-axis * ($label-width + 1);
    my $width     = max 1, min $max-width, max $s.min-width, +@data;

    # Actually generate the graph content
    my @rows := content(@data, :$rows, :$row-delta, :$min, :$max, :$cap,
                        :$width, :$colors, :style($s), :$do-overflow);

    # Add the y-axis and labels if desired
    if $s.show-y-axis {
        my $labels-every = $s.lines-every || min 8, ($rows / 5).ceiling;
        for ^@rows {
            my $row   = $rows - 1 - $_;
            my $value = $row * $row-delta + $min;
            my $show  = $row %% $labels-every;
            my $label = $show ?? numeric-label($value, $s) !! '';
            @rows[$_] = sprintf("%{$label-width}s▕", $label) ~ @rows[$_];
        }
    }

    @rows;
}


# Calculate the heatmap color ramp once
# Default ramp is for white backround; reverse for black background
my @heatmap-colors =
    (5, 5, 5),                                              # White
    (5, 5, 4), (5, 5, 3), (5, 5, 2), (5, 5, 1), (5, 5, 0),  # Pale to bright yellow
    (5, 4, 0), (5, 3, 0), (5, 2, 0), (5, 1, 0), (5, 0, 0),  # Yellow-orange to red
    (4, 0, 0), (3, 0, 0), (2, 0, 0), (1, 0, 0), (0, 0, 0);  # Brick red to black

my @heatmap-ramp = @heatmap-colors.map: { ~(16 + 36 * .[0] + 6 * .[1] + .[2]) }


sub smoke-chart(@data, Real :$row-delta, :@colors, :$style,
                Real:D :$min = min(0, @data.min), Real:D :$max = @data.max) is export {

    my $s = style-with-defaults($style);
    @colors ||= $s.background == Dark ?? @heatmap-ramp.reverse !! @heatmap-ramp;

    general-vertical-chart(@data, :$row-delta, :@colors, :$min, :$max, :style($s),
                           :content(&smoke-chart-content))
}


# Internal sub, generating just the inner content of the chart (no axes or key)
sub smoke-chart-content(@data, UInt:D :$rows!, Real:D :$row-delta!,
                       Real:D :$min!, Real:D :$max!, Real:D :$cap!,
                       UInt:D :$width!, :@colors!, ChartStyle:D :$style!,
                       Bool:D :$do-overflow!) {

    # Compute scaling to fit data into content area
    my $x-scale = $width / (@data || 1);
    # Last half row of data should be centered in top row of pixels
    my $y-scale = (2 * $rows - 1) / (($rows - 1/4) * $row-delta || 1);

    # Convert data into pixel locations and count hits
    my @pixels = [] xx 2 * $rows;
    for @data.kv -> $i, $value {
        my $x = floor $x-scale * $i;
        my $y = floor $y-scale * ($value - $min) + .5;
        @pixels[$y][$x]++;
    }

    # Compute color scaling to prevent washout with very many data points
    my $scale = @colors * $width < @data ?? @colors * $width / @data !! 1;

    # Convert pixels into rows of colored Unicode half-height blocks
    my @rows;
    my @cell-cache;
    for ^$rows .reverse -> int $y {
        my $top  = @pixels[$y * 2 + 1];
        my $bot  = @pixels[$y * 2];
        my $rule = +($style.lines-every && $y %% $style.lines-every || 0);
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


sub area-graph(@data, Real :$row-delta, :$colors, :$style,
               Real:D :$min = min(0, @data.min), Real:D :$max = @data.max) is export {

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

    # Render rows from top, computing data bars that intersect each row
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
