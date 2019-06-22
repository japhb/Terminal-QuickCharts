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
    has UInt:D $.max-height     = screen-height() - 1;

    # Y Axis attributes
    has Bool:D $.show-y-axis    = True;
    has Str:D  $.y-axis-unit    = '';
    has Real   $.y-axis-round;           # 0 or undefined => auto
    has Real   $.y-axis-scale;           # 0 or undefined => auto

    # Misc attributes
    has UInt   $.lines-every;            # Chart lines every N cells if true
    has Bool:D $.show-overflow  = True;  # Add arrows to indicate overflowed data
    has Bool:D $.show-legend    = True;  # Show color legend if needed
    has Terminal::QuickCharts::Background:D $.background = Dark;
}


#| Coerce to a ChartStyle instance, setting defaults if needed
proto style-with-defaults(| --> Terminal::QuickCharts::ChartStyle) is export {*}

#| Clone a ChartStyle instance, setting defaults if needed
multi style-with-defaults(Terminal::QuickCharts::ChartStyle:D $style, %defaults) {
    my @attribs = Terminal::QuickCharts::ChartStyle.^attributes.map: { .name.substr(2) };
    my %def;
    for %defaults.keys {
        next unless $_ ∈ @attribs;
        next if $style."$_"().defined;
        %def{$_} = %defaults{$_};
    }

    $style.clone(|%def)
}

#| Construct a ChartStyle instance using %defaults, with overrides from %style
multi style-with-defaults(%style, %defaults) {
    Terminal::QuickCharts::ChartStyle.new(|%defaults, |%style)
}

#| Construct a ChartStyle instance using just %defaults
multi style-with-defaults(%defaults) {
    Terminal::QuickCharts::ChartStyle.new(|%defaults)
}

#| Base case: return the provided ChartStyle instance
multi style-with-defaults(Terminal::QuickCharts::ChartStyle:D $style) {
    $style
}
