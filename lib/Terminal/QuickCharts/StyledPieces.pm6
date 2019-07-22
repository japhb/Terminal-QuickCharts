# ABSTRACT: Chart pieces that depend on style info

unit module Terminal::QuickCharts::StyledPieces;

use Terminal::QuickCharts::Pieces;
use Terminal::QuickCharts::ChartStyle;


#| Figure out reasonable defaults for y-axis unit/rounding/scaling
sub default-y-scaling(Real:D :$min!, Real:D :$max!,
                      Terminal::QuickCharts::ChartStyle:D :$style!) is export {
    my %default = default-numeric-scaling(:$min, :$max,
                                          :scale($style.y-axis-scale),
                                          :round($style.y-axis-round),
                                          :unit( $style.y-axis-unit));
    { y-axis-unit  => %default<unit>,
      y-axis-round => %default<round>,
      y-axis-scale => %default<scale> }
}


#| Render the text for a numeric Y-axis label, including scaling and rounding
#| the value, and appending a unit if any.
multi y-axis-numeric-label(Real:D $value,
                           Terminal::QuickCharts::ChartStyle:D $style) is export {
    numeric-label($value,
                  :scale($style.y-axis-scale),
                  :round($style.y-axis-round),
                  :unit( $style.y-axis-unit))
}
