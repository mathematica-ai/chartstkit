# ChartstKit features

This is the iOS surface for every chart in p1-charts. Behaviour that depends on a browser (CSS variables, canvas label patching, wheel events) has an iOS equivalent noted below.

Author: Mathematica, info@mathematica.ai.

## Time series

`TimeSeriesChart` plots one or more series.

| Field | Meaning |
| --- | --- |
| `series[].kind` | `.line` (default), `.area`, or `.histogram` |
| `series[].priceScale` | `.right` (default) or `.left` |
| `series[].lineStyle` | `.solid`, `.dashed`, or `.dotted` |
| `series[].lineWidth` | Line defaults to 2. Area and histogram default to 1 |
| `series[].color` | Falls back to `palette.categorical` in series order |
| `series[].includeInTooltip` | `false` keeps the series on the chart and out of the tooltip |
| `ribbons` | Fill between `upper` and `lower` where both share a time. Opacity defaults to 0.16 |
| `markers` | `seriesId` must match a series. Shapes are circle, square, arrow up, and arrow down |
| `ranges` | Full-height bands. `hatch` sets a hatch colour. `nil` is a fill only |
| `guides` | Dashed horizontal lines. The price scale includes them |
| `profile` | `.editorial` (default) or `.terminal` |
| `axis` | `.time` (default) or `.ordinal` |
| `categories` | Labels for an ordinal axis. Point time is the label or a 0-based index |
| `timeVisible` | Also prints the time of day |
| `formatTime` / `formatValue` | Replace the default `YYYY-MM-DD` label and the value text |
| `onPointClick` | Unix time and the values present at that time |
| `ariaLabel` | Default "Time series chart" |

Points are `TimeSeriesPoint(time:value:)`. Rows are sorted by time. A repeated time keeps the last finite value. A non-finite value is dropped.

Square axis labels from the web `patchSquareCanvasLabels` helper are drawn by the chart itself. Pass `theme.axis` for the font. The family string is stored on the theme. The drawn font is the system monospaced face at that size, because P1's webfonts are not bundled.

## Line, bar, histogram, candlestick

These four keep the terminal surface.

| Feature | Behaviour |
| --- | --- |
| Crosshair | Follows a drag. Arrow keys move it when the chart is focused |
| Pinch | Zooms around the centre of the visible window |
| Pan | Drag with one finger |
| Range select | Long-press, then drag. The chart zooms to the window and calls `onRangeSelect` |
| Reset | Double-tap calls `onReset` and fits the data |
| Range preset | `range: .oneDay`, `.oneWeek`, `.oneMonth`, `.threeMonths`, `.yearToDate`, `.oneYear`, `.threeYears`, `.fiveYears`, `.all` |
| Log scale | `logScale: true` on `LineChart`. Non-positive values stay on a linear scale |
| Auto bucket | `nextBucketSize` doubles until each bar is at least `minBarWidth` points. The public line, bar, histogram, and candlestick views fit every bar; call `nextBucketSize` and `aggregateCandles` or `aggregatePoints` when you want coarser buckets |
| Price flash | The last point flashes up or down when the latest close changes |
| Follow live | The view stays on the last bar until the user pans. A Live button jumps back |
| Chrome | `chrome: .terminal` (default) keeps pan, pinch, magnet, flash, follow-live, range select, axes, and the tooltip. `chrome: .embedded` draws the series only. A drag still reports `onPointClick`. `LineChart` also takes `markers` |
| Anchor | A dashed horizontal line at the close of the bar at or before `anchor` |
| Bands | `bands` plus `bandStyles`. A band covers `from` up to, not including, `to`. `bandAt` reports the hovered key |
| Overlays | Extra lines on `LineChart` |
| Baseline | `LineChart` `variant: .baseline` splits the fill at `baseValue` |
| Bar colours | Point colour wins, then the series colour, then up `#26a69a` and down `#ef5350` against `base` (default 0) |
| Histogram | `.plain`, `.threshold`, or `.diverging`. Diverging scales are symmetric. A threshold draws a guide |
| Candles | `.direction` fills up and down bars. `.trend` is hollow when close is above open, and coloured by the close against the previous close. Grey is an unchanged close |

`bin(samples, bins:min:max:edges:)` turns observations into counts. The count defaults to Sturges' rule. `edges` are explicit boundaries: a value lands in `[edge, next)`, and the last edge is inclusive.

## Category bars

`CategoryBarChart` uses the same layout as the web component.

| Field | Meaning |
| --- | --- |
| `mode` | `.group` (default), `.stack`, or `.overlay`. Overlay bars share a slot at opacity 0.72. Stack separates positive and negative runs |
| `orientation` | `.vertical` or `.horizontal`. Arrow keys follow that axis and stop at the ends |
| `series[].scale` | `.left` or `.right`. Each scale has its own extent |
| `series[].data` | A number, or `.styled(value, color:, label:)` |
| `domain` / `rightDomain` | Fix an extent instead of fitting the data |
| `reference` / `references` | Dashed lines across the plot |
| `bands` | A tint between two values, behind the bars |
| `onSelect` | Category label and index |

## Scatter and polar

`ScatterChart` plots `{ x, y }`. Arrow keys walk the finite points and stop at the ends. `line: true` connects a series. `markers: false` draws only the line.

`PolarChart` defaults to a wind rose (`mode: .bar`). Angle 0 is north. `direction` defaults to `.clockwise`. A value that is not greater than zero is omitted. Sector opacity is 0.72. `mode: .line` closes a polygon per series. `mode: .scatter` plots angle in degrees and radius. Arrow keys move the active index.

## Pie

`PieChart` sorts slices largest first. `maxSlices` folds the tail into one Other slice. `innerRadius` from 0 to 0.95 draws a donut and the visible total in the hole.

| Behaviour | Detail |
| --- | --- |
| Active | The finger, or arrow keys, set the active slice. `emphasis: .dim` fades the rest |
| Selection | Tap, Return, or Space. Escape clears. `.single` or `.multiple` |
| Legend | Tap hides a slice. Long-press shows only that slice. The last visible slice stays visible |
| Drill | `drillOther: true`. Tap Other to open its parts. Back, or Escape after the selection is clear, returns |
| Motion | 240 ms ease-in-out unless Reduce Motion is on |

`pieSlices`, `hideSlices`, `pieArcs`, and `PieChartState` are public for a custom renderer.

## Heatmap

`Heatmap` colours cells by a quantised step, not a gradient. `values[row][column]` may be `nil`. A gap is hatched, left out of the scale, and announced as no data.

| Field | Meaning |
| --- | --- |
| `steps` / `thresholds` | Equal-width bins, or your own cuts. `scale: .quantile` uses equal-count bins |
| `emphasis` | `.crosshair` (default), `.cell`, or `.none` |
| `selectionMode` | `.none`, `.single`, or `.range`. A drag extends a range. Escape clears |
| Legend | Tap a step to hide it. The last visible step stays visible |
| `markExtreme` | Reserved for min, max, or both marks |
| `showValues` | Draws the number when the cell is at least 18 points |

`heatmapGrid`, `rangeStats`, `extremes`, `stepColor`, `cellAt`, and `quantize` are public.

## Panes and timelines

`ChartPanes` stacks `HistogramPane` rows with a title, optional meta, histogram mode, and threshold. Each pane keeps its own time scale. `now` is placed on the union of those times across the full width, so it lines up with the bars when every pane uses the same times.

`TimelineChart` draws one lane per `TimelineLane`. An `eta` earlier than `start` adds an arrival hatch. Styles for `active`, `confirmed`, `tentative`, and `arrival` come from the P1 theme. `timeGrid` builds the axis.

## Shared math

These match the p1-charts helpers and are safe to call without a view:

`toUnixSeconds`, `presetRange`, `bin`, `aggregateCandles`, `aggregatePoints`, `normalizePoints`, `normalizeCandles`, `visibleStats`, `tickDirection`, `zoomRange`, `nextBucketSize`, `bandAt`, `resolveBandStyles`, `pieArcs`, `quantize`, `squarify`, `tidyTree`, `symmetricExtent`, `categoryFrame`, `scatterLayout`, `polarPoint`, `wedgeAngles`, `sparklinePaths`, `sparklineArea`, `seriesRows`, `ribbonSamples`, `timelineRanges`, `toSRGB`, `withAlpha`, `parseColor`.
