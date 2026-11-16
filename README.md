# ChartstKit

Native iOS charts for the [p1-charts](https://github.com/mathematica-ai/p1-charts) feature set.

ChartstKit is a SwiftUI library. It draws time series, candles, category bars, scatter, polar, heatmaps, pies, sparklines, panes, and timelines with the P1 theme. The layout math follows p1-charts 0.2.0.

Maintained by [Mathematica](mailto:info@mathematica.ai).

## Install

Add the package in Xcode, or in `Package.swift`:

```swift
.package(url: "https://github.com/mathematica-ai/chartstkit.git", from: "0.1.0")
```

The library links as `ChartstKit` and needs iOS 17 or macOS 14. Release `0.1.0` is commit `828ff86`.

In an XcodeGen project:

```yaml
packages:
  ChartstKit:
    url: https://github.com/mathematica-ai/chartstkit.git
    from: 0.1.0
targets:
  App:
    dependencies:
      - package: ChartstKit
```

Pass `chrome: .embedded` when the screen already has its own range control and readout. On `0.1.0`, embedded chrome draws the series only. It does not pan, zoom, draw axes, or draw a scrub rule. This branch, after that tag, draws a vertical rule and a dot on the active value. `chrome: .inspect` is that same chart, and a drag reads the close under the finger. The rule stays. The page does not scroll while the finger is on the plot. Bind `selection` when the host wants the scrubbed values. Resolve the host palette to `rgba(...)` strings and put them on a `ChartTheme`. ChartstKit does not read system colours itself. `.terminal` is the default and keeps pan, pinch, axes, and the tooltip.

`chrome: .press` reads a value on press and hold. After a quarter of a second a callout over the line shows the value and the date, and it follows the finger. Lifting the finger clears it. A swipe that starts on the chart before the hold still scrolls the page, because on iOS 18 and later the hold is the system long-press recogniser. Earlier systems fall back to a SwiftUI gesture. Pass `formatValue` and `formatTime` to `LineChart` or `CandlestickChart` to word the callout, and set `theme.callout` for its colours. Unset callout colours use the palette. Any chrome can opt in with `activation: .press`.

From this release, a chart whose chrome turns zoom or range select off no longer attaches those gestures, so they cannot hold a drag the page needs.

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
| Wheel and ctrl-wheel | Pinch, anchored where the gesture starts, when zoom is on |
| Drag | Pan, and the crosshair follows, when pan is on |
| Scrub inside a scroll view | Editorial time series and embedded chrome do not pan. A sideways drag, or a 0.2s long-press then a drag, moves the rule. Lifting clears the selection unless `sticky` is on |
| Shift-drag range select | Long-press, then drag, when range select is on. The chart zooms to that window |
| Double-click reset | Double-tap, when double-tap reset is on |
| Arrow keys, Enter, Space, Escape | Hardware keyboard, once the chart is focused. VoiceOver's adjustable action moves the same crosshair |
| Hover tooltip | Terminal chrome draws the tooltip. Embedded chrome leaves the readout to the host |

`TimeSeriesChart` defaults to the editorial profile. Pan, pinch, range select, double-tap reset, price flash, follow-live, range presets, and the live button are off. A scrub draws a rule and a dot. `profile: .terminal` turns on pan, pinch, the magnet crosshair, range select, double-tap reset, and a tooltip. Price flash, follow-live, range presets, and the live button stay on `LineChart`, `BarChart`, `HistogramChart`, and `CandlestickChart`.

An area fills from `areaTop` down to `areaBottom`. An explicit colour is used as given. A missing top uses the line colour at `theme.line.areaOpacity` (0.22). A missing bottom fades to clear. A baseline fades each side to clear at the base. Loading, empty, and failed charts draw a dotted baseline and no series. `.ready` with no rows is treated as empty. `.partial` fades the last mark to 45% opacity.

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

The tests cover the ported math and the surface helpers: time, binning, candles, presets, bands, colour, pie, heatmap, category layout, scatter, polar, sparkline, ribbons, timelines, area fills, axis ticks, the live window, and the VoiceOver summary. Rendering is exercised by building every chart view.

## License

[Apache-2.0](LICENSE). ChartstKit is a native port of p1-charts. See [NOTICE](NOTICE).
