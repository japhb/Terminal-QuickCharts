# ABSTRACT: Chart pieces that depend on style info

unit module Terminal::QuickCharts::StyledPieces;

use Terminal::QuickCharts::ChartStyle;


#| Figure out reasonable defaults for y-axis unit/rounding/scaling
sub default-y-scaling(Real:D :$min!, Real:D :$max!,
                      Terminal::QuickCharts::ChartStyle:D :$style!) is export {
    my $scale-by = 1000;
    my $max-abs  = max $min.abs, $max.abs;
    my $delta    = $max - $min;
    my $scale    = $style.y-axis-scale;

    my @prefixes = |< y z a f p n μ m >, '', |< k M G T P E Z Y >;
    my $index    = @prefixes.first: !*, :k;
    unless $scale {
        $scale = 1;
        while $max-abs > $scale-by {
            $max-abs /= $scale-by;
            $scale   /= $scale-by;
            $index++;
            last if $index >= @prefixes - 1;
        }
        while $max-abs < 1 {
            $max-abs *= $scale-by;
            $scale   *= $scale-by;
            $index--;
            last if $index <= 0;
        }
    }

    my $round = $style.y-axis-round || ($delta * $scale > 10 ?? 1 !! .1);
    my $unit  = @prefixes[$index] ~ $style.y-axis-unit;

    { y-axis-unit => $unit, y-axis-round => $round, y-axis-scale => $scale }
}


#| Render the text for a numeric Y-axis label, including scaling and rounding
#| the value, and appending a unit if any.
sub numeric-label(Real:D $value,
                  Terminal::QuickCharts::ChartStyle:D $style) is export {
    my $val = ($value * ($style.y-axis-scale || 1)).round($style.y-axis-round);
    $style.y-axis-unit ?? "$val $style.y-axis-unit()" !! $val
}
