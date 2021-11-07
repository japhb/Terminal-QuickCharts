NAME
====

Terminal::QuickCharts - Simple charts for CLI tools

SYNOPSIS
========

```raku
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
```

EXAMPLES
========

Comparing an animation's performance before and after a round of optimization:

![performance comparison charts](https://user-images.githubusercontent.com/63550/60478723-533b2f00-9c38-11e9-9462-2ef67d1840bf.png)

Result of many small Rakudo optimizations on a standard benchmark's runtime:

![graph of Rakudo optimization results](https://user-images.githubusercontent.com/63550/60484089-0746b500-9c4d-11e9-87fe-4ac4c032ba5e.png)

DESCRIPTION
===========

Terminal::QuickCharts provides a small library of simple text-output charts, suitable for sprucing up command-line reporting and quick analysis tools. The emphasis here is more on whipuptitude, and less on manipulexity.

This is a *very* early release; expect further iteration on the APIs, and if time permits, bug fixes and additional chart types.

AUTHOR
======

Geoffrey Broadwell <gjb@sonic.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2019-2021 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

