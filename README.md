# ChartstKit

Native iOS charts for the [p1-charts](https://github.com/mathematica-ai/p1-charts) feature set.

ChartstKit is a SwiftUI library. It draws time series, candles, category bars, scatter, polar, heatmaps, pies, sparklines, panes, and timelines with the P1 theme. The layout math follows p1-charts 0.2.0.

Maintained by [Mathematica](mailto:info@mathematica.ai).

## Install

Add the package in Xcode, or in `Package.swift`:

```swift
.package(url: "https://github.com/mathematica-ai/chartstkit.git", branch: "main")
```

The library links as `ChartstKit` and needs iOS 17 or macOS 14.

```swift
import ChartstKit

TimeSeriesChart(
    series: [
        TimeSeriesSpec(id: "visitors", name: "Visitors", kind: .histogram, data: visitors),
        TimeSeriesSpec(id: "revenue", name: "Revenue", priceScale: .right, data: revenue),
    ],
    ribbons: [TimeSeriesRibbon(upper: p90, lower: p10)],
    ariaLabel: "Daily traffic"
)
.environment(\.chartTheme, p1Theme(.light))
```

Wrap a tree in `ChartThemeProvider` when several charts share a theme:

```swift
ChartThemeProvider(p1Theme(.dark, colourBlind: true)) {
    LineChart(data: prices, bands: regimes)
}
```

## Charts

| Job | View |
| --- | --- |
| Several series, two scales, lines, areas, columns | `TimeSeriesChart` |
| Fill between two value lines (P10–P90) | `TimeSeriesChart` `ribbons` |
| Full-height tint over a time range | `LineChart` `bands`, or `ranges` on a time series |
| One series, terminal chrome | `LineChart`, `BarChart`, `HistogramChart`, `CandlestickChart` |
| Grouped, stacked, or overlaid category columns | `CategoryBarChart` |
| Statistical histogram | `bin()`, then `CategoryBarChart` |
| Numeric x and y | `ScatterChart` |
| Wind rose, radar, or angle-radius points | `PolarChart` |
| Two categorical axes | `Heatmap` |
| Shares of a whole | `PieChart` |
| Tile-sized trend | `Sparkline` |
| Stacked histogram panes | `ChartPanes` |
| Lanes of time ranges | `TimelineChart` |

`Sparkline` is the chart for a stat tile. Three-dimensional scatters, maps, and diagrams stay in the app.

## Interaction on iOS

p1-charts uses a mouse. ChartstKit uses the same state machines with touch:

| Web | iOS |
| --- | --- |
| Wheel and ctrl-wheel | Pinch, on the terminal profile and on line, bar, histogram, and candlestick charts |
| Drag | Pan, and the crosshair follows the finger |
| Shift-drag range select | Long-press, then drag. The chart zooms to that window |
| Double-click reset | Double-tap |
| Arrow keys, Enter, Space, Escape | Hardware keyboard, once the chart is focused |
| Hover tooltip | The finger sets the active bar, slice, cell, or point |

`TimeSeriesChart` defaults to the editorial profile: pinch zoom off, crosshair on the bar, no price flash, no follow-live, no jump-to-live button. `profile: .terminal` turns pinch zoom and the magnet crosshair on. Price flash, follow-live, range presets, and the live button stay on `LineChart`, `BarChart`, `HistogramChart`, and `CandlestickChart`.

## Theme

`ChartTheme.default` is the neutral palette. `p1Theme(.light)` and `p1Theme(.dark)` are the P1 brand palettes. `colourBlind: true` swaps the up and down colours for blue and amber.

There is no DOM on iOS, so there is no `p1ThemeFromCss`. Pass `p1Theme` or edit the struct:

```swift
var theme = p1Theme(.dark)
theme.palette.up = "#16a34a"
```

`unstyled: true` on pie and heatmap skips the theme fills.

## Time

`ChartTime` is a number, text, or `Date`. A number larger than `1e11` in absolute value is milliseconds. Text is an ISO date, a numeric string, or, on an ordinal axis, a category label. `toUnixSeconds` matches the p1-charts rule.

An ordinal axis takes `categories`. Point time is the label or a 0-based index. Each step is one unix day (`86400` seconds).

## Development

```bash
swift test
```

The tests cover the ported math: time, binning, candles, presets, bands, colour, pie, heatmap, category layout, scatter, polar, sparkline, ribbons, and timelines. Rendering is exercised by building every chart view.

## License

[Apache-2.0](LICENSE). ChartstKit is a native port of p1-charts. See [NOTICE](NOTICE).
