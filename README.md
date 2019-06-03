### sub hbar-chart

```perl6
sub hbar-chart(
    @data,
    :@colors,
    Bool :$stacked,
    Int :$lines-every where { ... },
    Real:D :$min!,
    Real:D :$max! where { ... },
    Int:D :$width! where { ... },
    Int :$bar-spacing where { ... } = 0
) returns Mu
```

Render the bars for a horizontal bar chart, padded out to $width, and optionally with chart lines drawn at an interval of $lines-every character cells. $min is the value at the left end of each bar, and $max the value at the far right (including the padding). hbar-chart() works in four modes, depending on whether the data is one- or two-dimensional, and whether $stacked is True or not. If the data is one-dimensional, then hbar-chart() will either produced a single stacked horizontal bar made from all data points (if $stacked is True), or one simple bar per data point (if $stacked is False), separated by $bar-spacing rows containing only chart lines. If the data is two-dimensional, then hbar-chart() produces either a series of stacked bars (if $stacked is True), each separated by $bar-spacing lines, or groups of simple bars packed together (if $stacked is False), with each group separated by $bar-spacing lines containing only chart lines.

NAME
====

Terminal::QuickCharts - Simple charts for CLI tools

SYNOPSIS
========

```perl6
use Terminal::QuickCharts;
```

DESCRIPTION
===========

Terminal::QuickCharts provides a small library of simple text-output charts, suitable for spruicing up command-line reporting and quick analysis tools. The emphasis here is more on whipuptitude, and less on manipulexity.

AUTHOR
======

Geoffrey Broadwell <gjb@sonic.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

