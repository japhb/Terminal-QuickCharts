unit module Terminal::QuickCharts:ver<0.0.2>;

use Terminal::ANSIColor;
use Terminal::QuickCharts::Helpers;
use Terminal::QuickCharts::Pieces;
use Terminal::QuickCharts::ChartStyle;
use Terminal::QuickCharts::StyledPieces;
use Terminal::QuickCharts::GeneralCharts;


# Render a chart variant that will best represent a frame time graph, based on
# details of the actual frame time data, and available screen size to render in
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
        my $max-label   = y-axis-numeric-label($max, $s);
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
                         "\x3C {@fps[*-1]}";
            my @labels = @ranges.map: { "$_ fps" };
            my @key    = color-key(:@colors, :@labels);
            @graph.append: '', '   ' ~ join '  ', @key;
        }
    }
    else {
        @graph = smoke-chart(@data, :$row-delta, :style($s), :min(0), :$max);
    }

    if $stats {
        # Min, mean, max
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

        # Percentiles
        my @sorted   = @data.sort;
        my @percents = .50, .75, .90, .95, .99;
        my @pctiles  = @percents.map({ @sorted[floor $_ * @sorted] });
        my @colored;
        for @percents Z @pctiles -> ($pct, $pctile) {
            my $fps   = 1 / ($pctile || 1);
            my $color = pick-color(@colors, floor($pctile * $target-fps));
            my $info  = sprintf('%d%%: %.1f ms', $pct * 100, $pctile * 1000);
            @colored.push: colored($info, $color);
        }
        my $percent-info = @colored.join(' - ');
        @graph.append: $percent-info;
    }

    @graph
}


# Render the bars for a horizontal bar chart, padded out to $width, and
# optionally with chart lines drawn at an interval of $lines-every character
# cells.  $min is the value at the left end of each bar, and $max the value at
# the far right (including the padding).
#
# hbar-chart() works in four modes, depending on whether the data is one- or
# two-dimensional, and whether $stacked is True or not.  If the data is
# one-dimensional, then hbar-chart() will either produce a single stacked
# horizontal bar made from all data points (if $stacked is True), or one
# simple bar per data point (if $stacked is False), separated by
# $style.bar-spacing rows containing only chart lines.
#
# If the data is two-dimensional, then hbar-chart() produces either a series
# of stacked bars (if $stacked is True), each separated by $style.bar-spacing
# lines, or groups of simple bars packed together (if $stacked is False), with
# each bar separated by $style.bar-spacing lines containing only chart lines,
# and each group separated by $style.group-spacing chart line only lines.
sub hbar-chart(@data, :@colors, :$bg-color is copy, :$line-color is copy,
               Bool :$stacked, :$style,
               Real :$min is copy, Real :$max is copy) is export {

    return unless @data;

    # Make sure we have a defined ChartStyle instance
    my $s = style-with-defaults($style);
    my $width = max 1, $s.max-width;

    # Default background and line colors depending on background style
    if $s.background == Light {
        $bg-color   //= 'white';
        $line-color //= 'black';
    }

    # A padded line to place between bars, with proper chart lines if requested
    my $blank-line = hpad($width, :lines-every($s.lines-every),
                          :color($bg-color), :$line-color);

    # Data is two dimensional
    if @data[0] ~~ Iterable {
        # Stacked bar per @data subarray
        if $stacked {
            $min //= 0;
            $max //= @data.map(*.grep(* > 0).sum).max;

            my @bars = gather for @data.kv -> $i, @values {
                take stacked-hbar(@values, :@colors, :$bg-color, :$line-color,
                                  :$min, :$max, :$width,
                                  :lines-every($s.lines-every));
                last if $i == @data.end;
                take $blank-line for ^$s.bar-spacing;
            }
        }
        # Group of simple bars per @data subarray
        else {
            $min //= min 0, @data.map(*.min).min;
            $max //= @data.map(*.max).max;

            my @bars = gather for @data.kv -> $i, @values {
                for @values.kv -> $j, $value {
                    take hbar($value, :$min, :$max, :$width,
                              :lines-every($s.lines-every),
                              :$bg-color, :$line-color,
                              :color(pick-color(@colors, $j)));
                    take $blank-line for ^$s.bar-spacing;
                }
                last if $i == @data.end;
                take $blank-line for ^$s.group-spacing;
            }
        }
    }
    # Data is one dimensional
    else {
        # A single stacked bar
        if $stacked {
            $min //= 0;
            $max //= @data.grep(* > 0).sum;
            stacked-hbar(@data, :@colors, :$bg-color, :$line-color,
                         :$min, :$max, :$width,
                         :lines-every($s.lines-every)),;
        }
        # Ungrouped simple bars
        else {
            $min //= min 0, @data.min;
            $max //= @data.max;

            my @bars = gather for @data.kv -> $i, $value {
                take hbar($value, :$min, :$max, :$width,
                          :lines-every($s.lines-every),
                          :$bg-color, :$line-color,
                          :color(pick-color(@colors, $i)));
                last if $i == @data.end;
                take $blank-line for ^$s.bar-spacing;
            }
        }
    }
}


# Calculate the heatmap color ramp once
# Default ramp is for white background; reverse for black background
my @heatmap-colors =
    (5, 5, 5),                                              # White
    (5, 5, 4), (5, 5, 3), (5, 5, 2), (5, 5, 1), (5, 5, 0),  # Pale to bright yellow
    (5, 4, 0), (5, 3, 0), (5, 2, 0), (5, 1, 0), (5, 0, 0),  # Yellow-orange to red
    (4, 0, 0), (3, 0, 0), (2, 0, 0), (1, 0, 0), (0, 0, 0);  # Brick red to black

my @heatmap-ramp = @heatmap-colors.map: { ~(16 + 36 * .[0] + 6 * .[1] + .[2]) }


# Render a smoke chart (good for getting general shape of a very dense dot plot)
sub smoke-chart(@data, Real :$row-delta, :@colors, :@labels, :$style,
                Real:D :$min = min(0, @data.min), Real:D :$max = @data.max) is export {

    my $s = style-with-defaults($style);
    @colors ||= $s.background == Dark ?? @heatmap-ramp.reverse !! @heatmap-ramp;

    general-vertical-chart(@data, :$row-delta, :@colors, :@labels, :$min, :$max, :style($s),
                           :content(&smoke-chart-content),
                           :labeler(&smoke-chart-labeler))
}

# Internal sub, generating just the X axis labels and label locations
sub smoke-chart-labeler(@data, :@labels, UInt:D :$width!, ChartStyle:D :$style!) {
    if @labels && @labels[0] ~~ Dateish {
        my $long-year  = @labels[0,*-1].map(*.year.chars).max;
        my $max-years  = ($width / ($long-year + 1)).floor;
        my $max-months = ($width / ($long-year + 4)).floor;
        my $max-dates  = ($width / ($long-year + 7)).floor;

        my $years  = @labels[*-1].year  - @labels[0].year;
        my $months = @labels[*-1].month - @labels[0].month + $years * 12;
        my $days   = @labels[*-1].Date  - @labels[0].Date;

        my $interval  = 1;
        my $unit      = 'days';
        my &formatter = *.yyyy-mm-dd;

        if $months / 6 >= $max-months {
            $unit      = 'years';
            &formatter = ~*.year;
            $interval *= 10 while $years / ($interval * 10) >= $max-years;
            $interval *=  5 if    $years / ($interval *  5) >= $max-years;

            my $int    = $interval;
            $interval += $int while $years / $interval > $max-years;
        }
        elsif $months / 3 >= $max-months {
            $unit      = 'months';
            $interval  = 6;
            &formatter = { .year ~ (.month < 7 ?? ' H1' !! ' H2') };
        }
        elsif $months >= $max-months {
            $unit      = 'months';
            $interval  = 3;
            &formatter = { .year ~ ' Q' ~ (.month / 3).ceiling };
        }
        elsif $days >= $max-dates {
            $unit      = 'months';
            &formatter = { .year ~ .month.fmt('-%02d') };
        }

        my $date = @labels[0].truncated-to($unit).Date;
        if $interval > 1 {
            if $unit eq 'years' {
                my $year  = $date.year - $date.year % $interval;
                $date     = Date.new(:$year);
            }
            else {
                my $month = $date.month - 1;
                $month   -= $month % $interval;
                $date     = Date.new(:year($date.year), :month($month + 1));
            }
        }

        my $start = @labels[0].Date;
        my $end   = @labels[*-1].Date;

        my @positioned = gather while $date <= $end {
            my $pos = floor $width * ($date - $start) / ($end - $start);
            take formatter($date) => $pos if $pos >= 0;
            $date .= later: |($unit => $interval);
        }
    }
    else {
        my $cell-delta   = @data / $width;
        my $labels-every = ($style.lines-every || 0) * 2 || min 12, ($width / 5).ceiling;
        my $label-delta  = $labels-every * $cell-delta;
        my $interval     = friendly-interval($label-delta);
        my $x-scale      = $width / (@data || 1);

        my @positioned   = (0, $interval ...^ * >= @data).map: {
            ~(@labels[$_] // $_) => ($_ * $x-scale).floor
        };

        @positioned
    }
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
    for ^@data -> int $i {
        my $x = ($x-scale * $i).floor;
        my $y = ($y-scale * (@data[$i] - $min) + .5).floor;
        @pixels[$y][$x]++;
    }

    # Compute color scaling to prevent washout with very many data points
    my $scale = @colors * $width < @data ?? @colors * $width / @data !! 1;

    # Convert pixels into rows of colored Unicode half-height blocks
    my @rows;
    my @cell-cache;
    my int $lines-every = $style.lines-every || $style.show-x-axis && 1_000_000 || 0;
    for ^$rows .reverse -> int $y {
        my $top  = @pixels[$y * 2 + 1];
        my $bot  = @pixels[$y * 2];
        my $rule = +($lines-every && $y %% $lines-every);
        my $line = $rule ?? 'underline ' !! '';

        @rows.push: (^$width .map: -> int $x {
            my int $v1 = ceiling ($top[$x] // 0) * $scale;
            my int $v2 = ceiling ($bot[$x] // 0) * $scale;
            @cell-cache[$rule][$v1][$v2] //=
                $v1 == $v2 ?? colored(' ', "{$line}on_" ~ pick-color(@colors, $v1)) !!
                              colored('▀',       $line  ~ pick-color(@colors, $v1) ~
                                                 ' on_' ~ pick-color(@colors, $v2))
        }).join;
    }

    @rows
}


# Render a vertical area graph, with optional horizontal color striping to
# indicate data bands
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

=begin code :lang<raku>

use Terminal::QuickCharts;

# Chart routines take an array of data points and return an array of
# rendered rows using ANSI terminal codes and Unicode block characters
.say for hbar-chart([5, 10, 15]);

# Horizontal bar charts support 2D data, grouping (default) or stacking the bars
.say for hbar-chart([(1, 2, 3), (4, 5, 6)], :colors< red yellow blue >);
.say for hbar-chart([(1, 2, 3), (4, 5, 6)], :colors< red yellow blue >, :stacked);

# You can also specify optional style and sizing info
.say for hbar-chart([17, 12, 16, 14], :min(10), :max(20));
.say for smoke-chart(@lots-of-data, :style{ lines-every => 5 });

# auto-chart() chooses a chart variant based on specified semantic domain,
# details of the actual data, and available screen size
.say for auto-chart('frame-time', @frame-times);

=end code

=head1 EXAMPLES

Comparing an animation's performance before and after a round of optimization:

V<![performance comparison charts](https://user-images.githubusercontent.com/63550/60478723-533b2f00-9c38-11e9-9462-2ef67d1840bf.png)>

Result of many small Rakudo optimizations on a standard benchmark's runtime:

V<![graph of Rakudo optimization results](https://user-images.githubusercontent.com/63550/60484089-0746b500-9c4d-11e9-87fe-4ac4c032ba5e.png)>

=head1 DESCRIPTION

Terminal::QuickCharts provides a small library of simple text-output charts,
suitable for sprucing up command-line reporting and quick analysis tools.  The
emphasis here is more on whipuptitude, and less on manipulexity.

This is a I<very> early release; expect further iteration on the APIs, and if
time permits, bug fixes and additional chart types.

=head1 AUTHOR

Geoffrey Broadwell <gjb@sonic.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2019-2021 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod
