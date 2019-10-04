# ABSTRACT: Common functionality for general chart classes

unit module Terminal::QuickCharts::GeneralCharts;

use Terminal::ANSIColor;
use Terminal::QuickCharts::Helpers;
use Terminal::QuickCharts::ChartStyle;
use Terminal::QuickCharts::StyledPieces;


#| Provide common functionality used by all vertically-oriented charts;
#| actual chart content rendering is handed off to &content, while sizing
#| computations and axis/label rendering is done in this common code.
sub general-vertical-chart(@data, Real :$row-delta! is copy, :$colors!, Real:D :$min!,
                           Real:D :$max!, :$style!, :&content!, :@labels, :&labeler) is export {

    # Make sure we have a defined ChartStyle instance
    my $s = style-with-defaults($style);

    # Basic sizing
    my $max-height = $s.max-height - $s.show-x-axis;
    my $delta      = $max - $min;
    my $rows;
    if $row-delta {
        $rows = max 1, min $max-height, max $s.min-height,
                                            ceiling($delta / $row-delta);
    }
    else {
        $rows = max 1, $max-height;
        $row-delta = $delta / $rows;

        # Auto-adjust row-delta to make convenient labels
        if $s.show-y-axis {
            my $labels-every = $s.lines-every || min 8, ($rows / 5).ceiling;
            my $label-delta  = $labels-every * $row-delta;
            $row-delta       = friendly-interval($label-delta) / $labels-every;
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
    $s .= clone(|default-y-scaling(:$min, :max($cap), :style($s)));

    # Determine max label width, if y-axis labels are actually desired,
    # and set content width to match
    my $label-width = max y-axis-numeric-label($cap, $s).chars,
                          y-axis-numeric-label($min, $s).chars;
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
            my $label = $show ?? y-axis-numeric-label($value, $s) !! '';
            @rows[$_] = sprintf("%{$label-width}s▕", $label) ~ @rows[$_];
        }
    }

    # Add the x-axis and labels if desired
    if $s.show-x-axis && &labeler {
        my $x-labels   = ' ' x $width;
        my @positioned = labeler(@data, :@labels, :$width, :style($s));

        for @positioned -> $ (:key($label), :value($pos)) {
            last if $pos >= $width;

            $x-labels.substr-rw($pos - 1, 1) = '…'
                if $pos && $x-labels.substr($pos, 1) ne ' ';
            $x-labels.substr-rw($pos, $label.chars + 1) = '└' ~ $label;
        }

        if $x-labels.chars > $width {
            $x-labels.substr-rw($width - 1, 1) = '…';
            $x-labels .= substr(0, $width);
        }

        $x-labels [R~]= ' ' x $s.show-y-axis * ($label-width + 1);
        @rows.push: $x-labels;
    }

    @rows;
}
