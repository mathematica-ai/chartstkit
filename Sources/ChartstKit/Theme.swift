import SwiftUI

public enum P1Mode: String, Sendable { case light, dark }

public struct P1Accents: Equatable, Sendable {
    public var highlight: String
    public var wick: String
    public var ink: String
    public var lastPrice: String
}

public struct ChartTheme: Equatable, Sendable {
    public struct TextStyle: Equatable, Sendable {
        public var family: String?
        public var size: Double?
        public var weight: Int?
        public var color: String?
        public init(family: String? = nil, size: Double? = nil, weight: Int? = nil, color: String? = nil) {
            self.family = family
            self.size = size
            self.weight = weight
            self.color = color
        }
    }

    public struct Stroke: Equatable, Sendable {
        public var color: String?
        public var width: Double?
        public var style: Dash
        public init(color: String? = nil, width: Double? = nil, style: Dash = .solid) {
            self.color = color
            self.width = width
            self.style = style
        }
    }

    public enum Dash: String, Equatable, Sendable { case solid, dashed, dotted }

    public struct Palette: Equatable, Sendable {
        public var background: String
        public var text: String
        public var grid: String
        public var border: String
        public var crosshair: String
        public var crosshairLabel: String
        public var up: String
        public var down: String
        public var neutral: String
        public var now: String
        public var categorical: [String]
        public var sequential: [String]
        public var diverging: [String]
        public init(
            background: String, text: String, grid: String, border: String, crosshair: String,
            crosshairLabel: String, up: String, down: String, neutral: String, now: String,
            categorical: [String], sequential: [String], diverging: [String]
        ) {
            self.background = background
            self.text = text
            self.grid = grid
            self.border = border
            self.crosshair = crosshair
            self.crosshairLabel = crosshairLabel
            self.up = up
            self.down = down
            self.neutral = neutral
            self.now = now
            self.categorical = categorical
            self.sequential = sequential
            self.diverging = diverging
        }
    }

    public struct Line: Equatable, Sendable {
        public var color: String?
        public var width: Double?
        public var areaTop: String?
        public var areaBottom: String?
        public var baselineTopFill: String?
        public var baselineBottomFill: String?
        public var overlays: [String]
        public init(
            color: String? = nil, width: Double? = nil, areaTop: String? = nil, areaBottom: String? = nil,
            baselineTopFill: String? = nil, baselineBottomFill: String? = nil, overlays: [String] = []
        ) {
            self.color = color
            self.width = width
            self.areaTop = areaTop
            self.areaBottom = areaBottom
            self.baselineTopFill = baselineTopFill
            self.baselineBottomFill = baselineBottomFill
            self.overlays = overlays
        }
    }

    public struct Histogram: Equatable, Sendable {
        public var bar: String?
        public var over: String?
        public var positive: String?
        public var negative: String?
        public var threshold: Stroke
        public var zero: Stroke
        public init(bar: String? = nil, over: String? = nil, positive: String? = nil, negative: String? = nil, threshold: Stroke = Stroke(), zero: Stroke = Stroke()) {
            self.bar = bar
            self.over = over
            self.positive = positive
            self.negative = negative
            self.threshold = threshold
            self.zero = zero
        }
    }

    public struct Pie: Equatable, Sendable {
        public var dimOpacity: Double
        public var selectionColor: String
        public var selectionWidth: Double
        public var focusColor: String
        public var focusDash: String
        public var center: TextStyle
        public var centerUnit: TextStyle
        public init(dimOpacity: Double = 0.35, selectionColor: String = "#191919", selectionWidth: Double = 2, focusColor: String = "#2196f3", focusDash: String = "3 3", center: TextStyle = TextStyle(), centerUnit: TextStyle = TextStyle()) {
            self.dimOpacity = dimOpacity
            self.selectionColor = selectionColor
            self.selectionWidth = selectionWidth
            self.focusColor = focusColor
            self.focusDash = focusDash
            self.center = center
            self.centerUnit = centerUnit
        }
    }

    public struct Heatmap: Equatable, Sendable {
        public var gap: Double
        public var dimOpacity: Double
        public var filteredOpacity: Double
        public var missingFill: String
        public var missingHatch: String
        public var activeColor: String
        public var focusColor: String
        public var selectionColor: String
        public var extremeColor: String
        public var valueInk: [String]
        public init(gap: Double = 1, dimOpacity: Double = 0.3, filteredOpacity: Double = 0.1, missingFill: String = "#FFFFFF", missingHatch: String = "#787b86", activeColor: String = "#191919", focusColor: String = "#2196f3", selectionColor: String = "#191919", extremeColor: String = "#191919", valueInk: [String] = ["#191919", "#191919", "#191919", "#FFFFFF", "#FFFFFF"]) {
            self.gap = gap
            self.dimOpacity = dimOpacity
            self.filteredOpacity = filteredOpacity
            self.missingFill = missingFill
            self.missingHatch = missingHatch
            self.activeColor = activeColor
            self.focusColor = focusColor
            self.selectionColor = selectionColor
            self.extremeColor = extremeColor
            self.valueInk = valueInk
        }
    }

    public var palette: Palette
    public var axis: TextStyle
    public var label: TextStyle
    public var value: TextStyle
    public var title: TextStyle
    public var paneHeight: Double
    public var laneHeight: Double
    public var line: Line
    public var histogram: Histogram
    public var candlestickUp: String?
    public var candlestickDown: String?
    public var candlestickWick: String?
    public var panesNow: String?
    public var panesTitle: TextStyle
    public var panesMeta: TextStyle
    public var timelineBarHeight: Double
    public var timelineStyles: [String: BandStyle]
    public var bandsOpacity: Double
    public var bands: BandTheme
    public var anchorColor: String?
    public var pie: Pie
    public var heatmap: Heatmap

    public struct BandTheme: Equatable, Sendable {
        public var opacity: Double
        public var styles: [String: BandStyle]
        public init(opacity: Double = 0.15, styles: [String: BandStyle] = [:]) {
            self.opacity = opacity
            self.styles = styles
        }
    }

    public init(
        palette: Palette,
        axis: TextStyle = TextStyle(),
        label: TextStyle = TextStyle(),
        value: TextStyle = TextStyle(),
        title: TextStyle = TextStyle(),
        paneHeight: Double = 52,
        laneHeight: Double = 50,
        line: Line = Line(),
        histogram: Histogram = Histogram(),
        candlestickUp: String? = nil,
        candlestickDown: String? = nil,
        candlestickWick: String? = nil,
        panesNow: String? = nil,
        panesTitle: TextStyle = TextStyle(),
        panesMeta: TextStyle = TextStyle(),
        timelineBarHeight: Double = 18,
        timelineStyles: [String: BandStyle] = [:],
        bands: BandTheme = BandTheme(),
        anchorColor: String? = nil,
        pie: Pie = Pie(),
        heatmap: Heatmap = Heatmap()
    ) {
        self.palette = palette
        self.axis = axis
        self.label = label
        self.value = value
        self.title = title
        self.paneHeight = paneHeight
        self.laneHeight = laneHeight
        self.line = line
        self.histogram = histogram
        self.candlestickUp = candlestickUp
        self.candlestickDown = candlestickDown
        self.candlestickWick = candlestickWick
        self.panesNow = panesNow
        self.panesTitle = panesTitle
        self.panesMeta = panesMeta
        self.timelineBarHeight = timelineBarHeight
        self.timelineStyles = timelineStyles
        self.bandsOpacity = bands.opacity
        self.bands = bands
        self.anchorColor = anchorColor
        self.pie = pie
        self.heatmap = heatmap
    }

    public static let `default` = ChartTheme(
        palette: Palette(
            background: "#FFFFFF", text: "#191919", grid: "#D6DCDE", border: "#2B2B43",
            crosshair: "#9598A1", crosshairLabel: "#131722", up: "#26a69a", down: "#ef5350",
            neutral: "#787b86", now: "#787b86",
            categorical: ["#2196f3", "#ff9800", "#26a69a", "#ef5350", "#9c27b0"],
            sequential: ["#e3f2fd", "#90caf9", "#42a5f5", "#1e88e5", "#0d47a1"],
            diverging: ["#ef5350", "#f4a9a8", "#e0e0e0", "#9fd3cd", "#26a69a"]
        )
    )
}

private struct ChartThemeKey: EnvironmentKey {
    static let defaultValue = ChartTheme.default
}

extension EnvironmentValues {
    public var chartTheme: ChartTheme {
        get { self[ChartThemeKey.self] }
        set { self[ChartThemeKey.self] = newValue }
    }
}

public struct ChartThemeProvider<Content: View>: View {
    private let theme: ChartTheme
    private let content: Content

    public init(_ theme: ChartTheme, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    public var body: some View { content.environment(\.chartTheme, theme) }
}

public func p1Theme(_ mode: P1Mode, colourBlind: Bool = false) -> ChartTheme {
    let c = P1Swatch.colors(mode)
    let mono = "ui-monospace, SFMono-Regular, Menlo, monospace"
    let sans = "ui-sans-serif, system-ui, sans-serif"
    let up = colourBlind ? c.upAlt : c.up
    let down = colourBlind ? c.downAlt : c.down
    return ChartTheme(
        palette: .init(
            background: c.chartBg, text: c.chartText, grid: c.chartGrid, border: c.chartGrid,
            crosshair: c.chartCrosshair, crosshairLabel: c.neutral, up: up, down: down,
            neutral: c.chartThreshold, now: c.chartNow, categorical: c.cat, sequential: c.seq, diverging: c.div
        ),
        axis: .init(family: mono, size: 11, weight: 400),
        label: .init(family: mono, size: 14, weight: 500),
        value: .init(family: mono, size: 13, weight: 400),
        title: .init(family: sans, size: 14, weight: 500),
        line: .init(
            color: c.series1, width: 2, areaTop: c.areaTop, areaBottom: c.areaBottom,
            baselineTopFill: c.upFill, baselineBottomFill: c.downFill, overlays: [c.series2, c.series3]
        ),
        histogram: .init(
            bar: c.bar, over: c.barOver, positive: c.pos, negative: c.neg,
            threshold: .init(color: c.chartThreshold, style: .dashed),
            zero: .init(color: c.chartCrosshair, style: .solid)
        ),
        candlestickUp: up,
        candlestickDown: down,
        candlestickWick: c.wick,
        panesNow: c.chartNow,
        panesTitle: .init(family: sans, size: 14, weight: 500, color: c.ink),
        panesMeta: .init(family: mono, size: 11, weight: 400, color: c.inkMuted),
        timelineStyles: [
            "active": BandStyle(fill: c.laneActive, label: "active"),
            "confirmed": BandStyle(fill: c.lane, label: "confirmed"),
            "tentative": BandStyle(fill: nil, label: "tentative", hatch: c.laneTentative),
            "arrival": BandStyle(hatch: c.laneTentative),
        ],
        bands: .init(opacity: 0.15, styles: [
            "riskOff": BandStyle(fill: c.bandStrong, label: "Risk off", legendColor: c.bandChip),
            "trend": BandStyle(fill: c.band1, label: "Strong trend"),
            "riskOn": BandStyle(fill: c.band2, label: "Risk on"),
            "meanRevert": BandStyle(fill: c.bandNone, label: "Mean revert"),
        ]),
        anchorColor: c.chartThreshold,
        pie: .init(
            dimOpacity: 0.32, selectionColor: c.ink, selectionWidth: 3, focusColor: c.primary,
            center: .init(family: mono, size: 28, weight: 500),
            centerUnit: .init(family: mono, size: 11, weight: 400, color: c.chartText)
        ),
        heatmap: .init(
            gap: 2, dimOpacity: 0.28, filteredOpacity: 0.08, missingFill: c.chartBg, missingHatch: c.inkMuted,
            activeColor: c.ink, focusColor: c.primary, selectionColor: c.ink, extremeColor: c.ink, valueInk: c.seqInk
        )
    )
}

public func p1Accents(_ mode: P1Mode) -> P1Accents {
    let c = P1Swatch.colors(mode)
    return P1Accents(highlight: c.highlight, wick: c.wick, ink: c.ink, lastPrice: c.series1)
}

struct P1Swatch {
    var chartBg, chartGrid, chartText, chartCrosshair, up, down, upAlt, downAlt, wick, highlight: String
    var chartNow, chartThreshold, series1, series2, series3, areaTop, areaBottom, upFill, downFill: String
    var bar, barOver, pos, neg, lane, laneActive, laneTentative, ink, inkMuted, neutral, primary: String
    var bandStrong, band1, band2, bandNone, bandChip: String
    var cat, seq, div, seqInk: [String]

    static func colors(_ mode: P1Mode) -> P1Swatch {
        mode == .dark ? dark : light
    }

    static let dark = P1Swatch(
        chartBg: "#111111", chartGrid: "#2b2b2a", chartText: "#9d9d9d", chartCrosshair: "#8a837a",
        up: "#d4d0cb", down: "#ce5a3a", upAlt: "#0064fa", downAlt: "#f9a325", wick: "#8a837a", highlight: "#f9a325",
        chartNow: "#d9d9d9", chartThreshold: "#9d9d9d", series1: "#ce5a3a", series2: "#3a8bff", series3: "#f9a325",
        areaTop: "rgba(206, 90, 58, 0.32)", areaBottom: "rgba(206, 90, 58, 0)",
        upFill: "rgba(212, 208, 203, 0.16)", downFill: "rgba(206, 90, 58, 0.28)",
        bar: "#6e6e6c", barOver: "#f9a325", pos: "#f9a325", neg: "#3a8bff",
        lane: "#3a3a38", laneActive: "#ce5a3a", laneTentative: "#8a837a",
        ink: "#d9d9d9", inkMuted: "#9d9d9d", neutral: "#ffffff", primary: "#ce5a3a",
        bandStrong: "#3b211a", band1: "#30302f", band2: "#212020", bandNone: "#00000000", bandChip: "#ce5a3a",
        cat: ["#ce5a3a", "#3a8bff", "#f9a325", "#6e6e6c", "#d4d0cb"],
        seq: ["#2a2522", "#5c2a1a", "#9f4d35", "#e0703f", "#f9a325"],
        div: ["#3a8bff", "#22406b", "#2b2b2a", "#6b4416", "#f9a325"],
        seqInk: ["#ffffff", "#ffffff", "#ffffff", "#111111", "#111111"]
    )

    static let light = P1Swatch(
        chartBg: "#ffffff", chartGrid: "#e5e5e2", chartText: "#585858", chartCrosshair: "#8a837a",
        up: "#111111", down: "#9f4d35", upAlt: "#0064fa", downAlt: "#b36b00", wick: "#8a837a", highlight: "#f9a325",
        chartNow: "#111111", chartThreshold: "#585858", series1: "#9f4d35", series2: "#0050c8", series3: "#b36b00",
        areaTop: "rgba(159, 77, 53, 0.20)", areaBottom: "rgba(159, 77, 53, 0)",
        upFill: "rgba(17, 17, 17, 0.08)", downFill: "rgba(159, 77, 53, 0.18)",
        bar: "#8a837a", barOver: "#b36b00", pos: "#b36b00", neg: "#0050c8",
        lane: "#d4d0cb", laneActive: "#9f4d35", laneTentative: "#8a837a",
        ink: "#111111", inkMuted: "#585858", neutral: "#111111", primary: "#9f4d35",
        bandStrong: "#f0e3df", band1: "#e5e3e0", band2: "#f3f2f0", bandNone: "#00000000", bandChip: "#9f4d35",
        cat: ["#9f4d35", "#0050c8", "#b36b00", "#8a837a", "#3a3a38"],
        seq: ["#f0ede8", "#f2c9a0", "#e08a5c", "#b5502f", "#6b2210"],
        div: ["#0050c8", "#a9c4ef", "#f0ede8", "#f2cc8f", "#8f5500"],
        seqInk: ["#111111", "#111111", "#111111", "#ffffff", "#ffffff"]
    )
}
