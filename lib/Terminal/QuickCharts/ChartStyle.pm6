# ABSTRACT: Style classes and associated enums

use Terminal::QuickCharts::Helpers;


#| Background hint for color maps
enum Terminal::QuickCharts::Background is export < Dark Light >;

#| Collect general chart style info in a unified structure
class Terminal::QuickCharts::ChartStyle {
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
    has Terminal::QuickCharts::Background $.background = Dark;
}
