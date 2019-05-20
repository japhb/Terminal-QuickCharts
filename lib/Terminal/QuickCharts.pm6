use v6.c;
unit module Terminal::QuickCharts:ver<0.0.1>;

use Terminal::ANSIColor;


sub screen-height(--> UInt:D) {
    if ::("Terminal::Print") -> \TP {
        TP.new.rows
    }
    else {
        +qx/tput lines/ || 24
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


#| Render a single stacked horizontal bar (presumably from a bar chart).  $min
#| is the value at the left end, and $max the value at the right. The bar will
#| be padded out to $width, optionally with chart lines drawn at an interval of
#| $lines-every.  Bar segments will be colored in order of @colors.
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


sub area-graph(@data, Real:D :$row-delta!, :$color, UInt :$lines-every,
               UInt :$max-height = screen-height, UInt :$min-height = 1) is export {

    my $max  = @data.max;
    my $rows = max 1, min $max-height, max $min-height, ceiling($max / $row-delta);
    my @rows;

    # If data spikes are too tall to fit in graph, use top row to indicate that
    if $max > $rows * $row-delta {
        $rows--;
        my $cap = $rows * $row-delta;
        my $top-row = @data.map({ $_ > $cap ?? '↑' !! ' '}).join;
        @rows.push: colorize($top-row, $color, $rows);
    }

    for ^$rows .reverse -> $row {
        my $bot = $row * $row-delta;
        my $top = $bot + $row-delta;

        my $rule = $lines-every && $row %% $lines-every ?? '_' !! ' ';
        my $bars = @data.map({
            $_ >= $top ?? '█'   !!
            $_ <= $bot ?? $rule !! (0x2581 + floor(($_ - $bot) / $row-delta * 8)).chr;
        }).join;
        @rows.push: colorize($bars, $color, $row);
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
