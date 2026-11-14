import SwiftUI

public enum PriceScale: String, Sendable { case left, right }
public enum LineVariant: String, Sendable { case line, area, baseline }
public enum TimeSeriesKind: String, Sendable { case line, area, histogram }
public enum TimeSeriesProfile: String, Sendable { case editorial, terminal }
public enum TimeSeriesAxis: String, Sendable { case time, ordinal }
public enum MarkerShape: String, Sendable { case circle, square, arrowUp, arrowDown }

public struct TimeSeriesSpec: Identifiable, Sendable {
    public var id: String
    public var name: String
    public var kind: TimeSeriesKind
    public var data: [TimeSeriesPoint]
    public var color: String?
    public var priceScale: PriceScale
    public var lineWidth: Double?
    public var lineStyle: ChartTheme.Dash
    public var includeInTooltip: Bool
    public init(id: String, name: String, kind: TimeSeriesKind = .line, data: [TimeSeriesPoint], color: String? = nil, priceScale: PriceScale = .right, lineWidth: Double? = nil, lineStyle: ChartTheme.Dash = .solid, includeInTooltip: Bool = true) {
        self.id = id
        self.name = name
        self.kind = kind
        self.data = data
        self.color = color
        self.priceScale = priceScale
        self.lineWidth = lineWidth
        self.lineStyle = lineStyle
        self.includeInTooltip = includeInTooltip
    }
}

public struct TimeSeriesRibbon: Sendable {
    public var upper: [TimeSeriesPoint]
    public var lower: [TimeSeriesPoint]
    public var color: String?
    public var opacity: Double
    public var priceScale: PriceScale
    public init(upper: [TimeSeriesPoint], lower: [TimeSeriesPoint], color: String? = nil, opacity: Double = 0.16, priceScale: PriceScale = .right) {
        self.upper = upper
        self.lower = lower
        self.color = color
        self.opacity = opacity
        self.priceScale = priceScale
    }
}

public struct TimeSeriesRange: Identifiable, Sendable {
    public var id: String
    public var from: ChartTime
    public var to: ChartTime
    public var fill: String?
    public var hatch: String?
    public var label: String?
    public init(id: String, from: ChartTime, to: ChartTime, fill: String? = nil, hatch: String? = nil, label: String? = nil) {
        self.id = id
        self.from = from
        self.to = to
        self.fill = fill
        self.hatch = hatch
        self.label = label
    }
}

public struct TimeSeriesGuide: Identifiable, Sendable {
    public var id: String
    public var value: Double
    public var label: String?
    public var color: String?
    public var scale: PriceScale
    public init(id: String, value: Double, label: String? = nil, color: String? = nil, scale: PriceScale = .right) {
        self.id = id
        self.value = value
        self.label = label
        self.color = color
        self.scale = scale
    }
}

public struct TimeSeriesMarker: Sendable {
    public var seriesId: String
    public var time: ChartTime
    public var text: String?
    public var color: String?
    public var shape: MarkerShape
    public init(seriesId: String, time: ChartTime, text: String? = nil, color: String? = nil, shape: MarkerShape = .circle) {
        self.seriesId = seriesId
        self.time = time
        self.text = text
        self.color = color
        self.shape = shape
    }
}

struct DrawnSeries {
    var id: String
    var name: String
    var kind: SeriesKind
    var rows: [PlotRow]
    var color: String
    var scale: PriceScale
    var lineWidth: CGFloat
    var dash: [CGFloat]
    var tooltip: Bool
    var base: Double
    var up: String
    var down: String
    var areaTop: String?
    var areaBottom: String?
}

enum SeriesKind { case line, area, baseline, histogram, bar, candle }

struct SeriesChrome {
    var zoom = true
    var magnet = true
    var flash = true
    var followLive = true
    var rangeSelect = true
    var doubleTapReset = true
    var autoBucket = false
    var minBarWidth: Double = 6
    var liveButton = true
    var profile: TimeSeriesProfile = .terminal

    init(zoom: Bool = true, magnet: Bool = true, flash: Bool = true, followLive: Bool = true, rangeSelect: Bool = true, doubleTapReset: Bool = true, autoBucket: Bool = false, minBarWidth: Double = 6, liveButton: Bool = true, profile: TimeSeriesProfile = .terminal) {
        self.zoom = zoom
        self.magnet = magnet
        self.flash = flash
        self.followLive = followLive
        self.rangeSelect = rangeSelect
        self.doubleTapReset = doubleTapReset
        self.autoBucket = autoBucket
        self.minBarWidth = minBarWidth
        self.liveButton = liveButton
        self.profile = profile
    }
}

struct SeriesPlot: View {
    var series: [DrawnSeries]
    var bands: [BandItem]
    var bandStyles: [String: BandStyleInput]
    var ribbons: [RibbonSample]
    var guides: [TimeSeriesGuide]
    var ranges: [TimeSeriesRange]
    var markers: [TimeSeriesMarker]
    var chrome: SeriesChrome
    var logScale: Bool
    var preset: RangePreset?
    var anchor: ChartTime?
    var histogramMode: HistogramMode
    var threshold: Double?
    var coloring: CandlestickColoring
    var height: CGFloat
    var ariaLabel: String
    var categories: [String]?
    var timeVisible: Bool
    var theme: ChartTheme
    var formatTime: ((Int) -> String)?
    var formatValue: ((String, Double) -> String)?
    var onPointClick: ((Int, [(String, Double)]) -> Void)?
    var onRangeSelect: ((VisibleStats) -> Void)?
    var onReset: (() -> Void)?
    var onVisibleStats: ((VisibleStats?) -> Void)?

    @State private var logical: LogicalRange?
    @State private var userAdjusted = false
    @State private var crosshair: Int?
    @State private var flash: TickDirection?
    @State private var previous: [PlotRow] = []
    @State private var selecting = false
    @State private var selection: (CGFloat, CGFloat)?
    @State private var panStart: LogicalRange?
    @State private var pinchStart: LogicalRange?
    @FocusState private var focused: Bool

    var body: some View {
        let prepared = prepare()
        VStack(spacing: 0) {
            GeometryReader { geo in
                let size = geo.size
                let pads = pads(for: prepared.series)
                let plot = CGRect(x: pads.left, y: pads.top, width: max(1, size.width - pads.left - pads.right), height: max(1, size.height - pads.top - pads.bottom))
                let range = logical ?? fit(prepared.times.count)
                Canvas { context, _ in
                    drawPlot(context, size: size, plot: plot, prepared: prepared, range: range)
                }
                .gesture(drag(plot: plot, prepared: prepared, range: range))
                .simultaneousGesture(zoomGesture(range: range))
                .simultaneousGesture(selectGesture(plot: plot, prepared: prepared))
                .onTapGesture(count: 2) { if chrome.doubleTapReset { logical = nil; userAdjusted = false; onReset?() } }
                .onTapGesture { location in
                    let index = indexAt(location.x, plot: plot, range: range, count: prepared.times.count)
                    crosshair = index
                    onPointClick?(prepared.times[safe: index] ?? 0, hits(prepared, index: index))
                }
                .overlay(alignment: .topLeading) { tooltip(prepared, plot: plot, range: range) }
                .overlay(alignment: .bottomTrailing) { liveButton(prepared) }
            }
            .frame(height: height)
        }
        .background(chartColor(theme.palette.background))
        .accessibilityLabel(ariaLabel)
        .focusable()
        .focused($focused)
        .onKeyPress(.leftArrow) { nudge(-1, prepared); return .handled }
        .onKeyPress(.rightArrow) { nudge(1, prepared); return .handled }
        .onKeyPress(.escape) { selection = nil; selecting = false; return .handled }
        .onAppear { applyPreset(prepared) }
        .onChange(of: preset) { _, _ in applyPreset(prepared) }
        .onChange(of: revision) { _, _ in
            let next = prepared.series.first?.rows ?? []
            if chrome.flash, let direction = tickDirection(previous: previous, next: next) { flash = direction }
            if chrome.followLive, !userAdjusted { logical = nil }
            previous = next
            report(prepared, range: logical ?? fit(prepared.times.count))
        }
        .task(id: flash) {
            guard flash != nil else { return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            flash = nil
        }
    }

    private var revision: String {
        series.map { "\($0.id):\($0.rows.count):\($0.rows.last?.close ?? 0)" }.joined(separator: "|")
    }

    private func prepare() -> Prepared {
        var source = series
        if chrome.autoBucket, source.count == 1, var only = source.first, only.rows.count > 2 {
            let px = 320 / Double(only.rows.count)
            let size = nextBucketSize(current: 1, pxPerRawBar: px, minBarWidth: chrome.minBarWidth, rawCount: only.rows.count)
            if size > 1 {
                only.rows = bucketedRows(only.rows, kind: only.kind, size: size)
                source[0] = only
            }
        }
        if histogramMode != .plain {
            for index in source.indices where source[index].kind == .histogram {
                source[index].rows = colorBars(source[index].rows, mode: histogramMode, threshold: threshold, colors: HistogramColors(bar: source[index].color, over: theme.histogram.over, positive: theme.histogram.positive, negative: theme.histogram.negative))
            }
        }
        let times = Array(Set(source.flatMap { $0.rows.map(\.time) })).sorted()
        return Prepared(series: source, times: times)
    }

    private func fit(_ count: Int) -> LogicalRange {
        LogicalRange(from: -halfBar, to: Double(max(count - 1, 0)) + halfBar)
    }

    private func pads(for series: [DrawnSeries]) -> (top: CGFloat, right: CGFloat, bottom: CGFloat, left: CGFloat) {
        let right: CGFloat = series.contains { $0.scale == .right } || series.isEmpty ? 48 : 12
        let left: CGFloat = series.contains { $0.scale == .left } ? 48 : 12
        return (12, right, 28, left == 12 && right == 48 ? 12 : left)
    }

    private func drawPlot(_ context: GraphicsContext, size: CGSize, plot: CGRect, prepared: Prepared, range: LogicalRange) {
        let leftDomain = domain(.left, prepared, range)
        let rightDomain = domain(.right, prepared, range)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(chartColor(theme.palette.background)))
        for tick in axisTicks(min: rightDomain.0, max: rightDomain.1) {
            let y = yPos(tick, domain: rightDomain, plot: plot)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: y))
            path.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.stroke(path, with: .color(chartColor(theme.palette.grid)), lineWidth: 1)
            context.draw(Text(formatChartNumber(tick)).font(chartFont(theme.axis, mono: true)).foregroundStyle(chartColor(theme.palette.text)), at: CGPoint(x: plot.maxX + 22, y: y))
        }
        for band in sortBands(bands) {
            guard let span = bandSpan(band.start, band.end, times: prepared.times, plot: plot, range: range) else { continue }
            let style = resolveBandStyles(keys: bandKeys(bands), theme: theme, bandStyles: bandStyles)[band.key]
            let rect = CGRect(x: span.0, y: plot.minY, width: max(1, span.1 - span.0), height: plot.height)
            context.fill(Path(rect), with: .color(chartColor(style?.fill, fallback: chartColor(theme.palette.categorical.first).opacity(theme.bands.opacity))))
        }
        for item in ranges {
            guard let start = toUnixSeconds(item.from), let end = toUnixSeconds(item.to) else { continue }
            guard let span = bandSpan(min(start, end), max(start, end), times: prepared.times, plot: plot, range: range) else { continue }
            let rect = CGRect(x: span.0, y: plot.minY, width: max(1, span.1 - span.0), height: plot.height)
            context.fill(Path(rect), with: .color(chartColor(item.fill, fallback: chartColor(theme.palette.neutral).opacity(0.12))))
            if let hatch = item.hatch { strokeHatch(context, rect: rect, color: chartColor(hatch)) }
        }
        if !ribbons.isEmpty {
            var path = Path()
            let domain = domain(.right, prepared, range)
            for (index, sample) in ribbons.enumerated() {
                guard let slot = prepared.times.firstIndex(of: sample.time) else { continue }
                let point = CGPoint(x: xPos(Double(slot), plot: plot, range: range), y: yPos(sample.upper, domain: domain, plot: plot))
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            for sample in ribbons.reversed() {
                guard let slot = prepared.times.firstIndex(of: sample.time) else { continue }
                path.addLine(to: CGPoint(x: xPos(Double(slot), plot: plot, range: range), y: yPos(sample.lower, domain: domain, plot: plot)))
            }
            path.closeSubpath()
            context.fill(path, with: .color(chartColor(theme.palette.categorical.first).opacity(0.16)))
        }
        for item in prepared.series {
            let values = aligned(item, times: prepared.times)
            let domain = domain(item.scale, prepared, range)
            switch item.kind {
            case .line, .area, .baseline:
                strokeLine(context, item: item, values: values, domain: domain, plot: plot, range: range)
            case .histogram, .bar:
                strokeColumns(context, item: item, values: values, domain: domain, plot: plot, range: range)
            case .candle:
                strokeCandles(context, item: item, values: values, domain: domain, plot: plot, range: range)
            }
        }
        drawMarkers(context, prepared: prepared, plot: plot, range: range)
        for guide in guides {
            let domain = domain(guide.scale, prepared, range)
            let y = yPos(guide.value, domain: domain, plot: plot)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: y))
            path.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.stroke(path, with: .color(chartColor(guide.color, fallback: chartColor(theme.palette.neutral))), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        if let anchor, let time = toUnixSeconds(anchor), let index = indexAtOrBefore(prepared.times, time: time), let row = prepared.series.first?.rows.last(where: { $0.time <= time }) {
            let domain = domain(prepared.series.first?.scale ?? .right, prepared, range)
            let y = yPos(row.close, domain: domain, plot: plot)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: y))
            path.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.stroke(path, with: .color(chartColor(theme.anchorColor, fallback: chartColor(theme.palette.neutral))), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            _ = index
        }
        if let crosshair, prepared.times.indices.contains(crosshair) {
            let x = chrome.magnet || chrome.profile == .terminal ? xPos(Double(crosshair), plot: plot, range: range) : xPos(Double(crosshair), plot: plot, range: range)
            var path = Path()
            path.move(to: CGPoint(x: x, y: plot.minY))
            path.addLine(to: CGPoint(x: x, y: plot.maxY))
            context.stroke(path, with: .color(chartColor(theme.palette.crosshair)), style: StrokeStyle(lineWidth: 1, dash: chrome.profile == .editorial ? [] : [3, 3]))
        }
        if let selection {
            let rect = CGRect(x: min(selection.0, selection.1), y: plot.minY, width: abs(selection.1 - selection.0), height: plot.height)
            context.fill(Path(rect), with: .color(chartColor(theme.palette.crosshair).opacity(0.15)))
        }
        let labelCount = min(4, prepared.times.count)
        if labelCount > 0 {
            for step in 0..<labelCount {
                let index = prepared.times.count == 1 ? 0 : Int((Double(step) / Double(labelCount - 1)) * Double(prepared.times.count - 1))
                let time = prepared.times[index]
                let text = categories.flatMap { ordinalLabel(time, categories: $0).isEmpty ? nil : ordinalLabel(time, categories: $0) } ?? formatTime?(time) ?? defaultTimeLabel(unix: time, timeVisible: timeVisible)
                context.draw(Text(text).font(chartFont(theme.axis, mono: true)).foregroundStyle(chartColor(theme.palette.text)), at: CGPoint(x: xPos(Double(index), plot: plot, range: range), y: plot.maxY + 14))
            }
        }
    }

    private func drawMarkers(_ context: GraphicsContext, prepared: Prepared, plot: CGRect, range: LogicalRange) {
        for marker in markers {
            guard let series = prepared.series.first(where: { $0.id == marker.seriesId }),
                  let time = seriesTime(marker.time, categories: categories),
                  let index = prepared.times.firstIndex(of: time),
                  let row = series.rows.last(where: { $0.time == time }) else { continue }
            let scaleDomain = domain(series.scale, prepared, range)
            let point = CGPoint(x: xPos(Double(index), plot: plot, range: range), y: yPos(row.close, domain: scaleDomain, plot: plot))
            let color = chartColor(marker.color ?? series.color)
            var path = Path()
            let radius: CGFloat = 5
            switch marker.shape {
            case .circle:
                path.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            case .square:
                path.addRect(CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            case .arrowUp:
                path.move(to: CGPoint(x: point.x, y: point.y - radius))
                path.addLine(to: CGPoint(x: point.x + radius, y: point.y + radius))
                path.addLine(to: CGPoint(x: point.x - radius, y: point.y + radius))
                path.closeSubpath()
            case .arrowDown:
                path.move(to: CGPoint(x: point.x, y: point.y + radius))
                path.addLine(to: CGPoint(x: point.x + radius, y: point.y - radius))
                path.addLine(to: CGPoint(x: point.x - radius, y: point.y - radius))
                path.closeSubpath()
            }
            context.fill(path, with: .color(color))
            if let text = marker.text {
                context.draw(Text(text).font(chartFont(theme.axis, mono: true)).foregroundStyle(color), at: CGPoint(x: point.x, y: point.y - 14))
            }
        }
    }

    private func strokeLine(_ context: GraphicsContext, item: DrawnSeries, values: [PlotRow?], domain: (Double, Double), plot: CGRect, range: LogicalRange) {
        var line = Path()
        var area = Path()
        var started = false
        var firstX: CGFloat = 0
        var lastX: CGFloat = 0
        for (index, row) in values.enumerated() {
            guard let row else { continue }
            let point = CGPoint(x: xPos(Double(index), plot: plot, range: range), y: yPos(row.close, domain: domain, plot: plot))
            if started { line.addLine(to: point) } else { line.move(to: point); area.move(to: point); firstX = point.x; started = true }
            area.addLine(to: point)
            lastX = point.x
        }
        if item.kind == .area || item.kind == .baseline, started {
            let baseY = yPos(item.kind == .baseline ? item.base : domain.0, domain: domain, plot: plot)
            area.addLine(to: CGPoint(x: lastX, y: baseY))
            area.addLine(to: CGPoint(x: firstX, y: baseY))
            area.closeSubpath()
            context.fill(area, with: .color(chartColor(item.areaTop ?? item.color).opacity(0.22)))
        }
        context.stroke(line, with: .color(chartColor(item.color)), style: StrokeStyle(lineWidth: item.lineWidth, lineCap: .round, lineJoin: .round, dash: item.dash))
        if let flash, let last = values.indices.last, let row = values[last] {
            let point = CGPoint(x: xPos(Double(last), plot: plot, range: range), y: yPos(row.close, domain: domain, plot: plot))
            let color = flash == .up ? chartColor(item.up) : chartColor(item.down)
            context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(color))
        }
    }

    private func strokeColumns(_ context: GraphicsContext, item: DrawnSeries, values: [PlotRow?], domain: (Double, Double), plot: CGRect, range: LogicalRange) {
        let slot = abs(xPos(1, plot: plot, range: range) - xPos(0, plot: plot, range: range))
        let width = max(1, slot * 0.72)
        for (index, row) in values.enumerated() {
            guard let row else { continue }
            let origin = item.kind == .bar ? item.base : 0
            let y0 = yPos(origin, domain: domain, plot: plot)
            let y1 = yPos(row.close, domain: domain, plot: plot)
            let rect = CGRect(x: xPos(Double(index), plot: plot, range: range) - width / 2, y: min(y0, y1), width: width, height: max(1, abs(y1 - y0)))
            let rising = row.close >= origin
            let color = row.color ?? (item.kind == .bar ? (rising ? item.up : item.down) : item.color)
            context.fill(Path(rect), with: .color(chartColor(color)))
            if flash != nil, index == values.count - 1 {
                context.stroke(Path(rect), with: .color(flash == .up ? chartColor(item.up) : chartColor(item.down)), lineWidth: 2)
            }
        }
    }

    private func strokeCandles(_ context: GraphicsContext, item: DrawnSeries, values: [PlotRow?], domain: (Double, Double), plot: CGRect, range: LogicalRange) {
        let slot = abs(xPos(1, plot: plot, range: range) - xPos(0, plot: plot, range: range))
        let width = max(3, slot * 0.62)
        var previous: PlotRow?
        for (index, row) in values.enumerated() {
            guard let row else { continue }
            let x = xPos(Double(index), plot: plot, range: range)
            var wick = Path()
            wick.move(to: CGPoint(x: x, y: yPos(row.high, domain: domain, plot: plot)))
            wick.addLine(to: CGPoint(x: x, y: yPos(row.low, domain: domain, plot: plot)))
            let up = row.close >= row.open
            let bodyColor: Color
            let hollow: Bool
            if coloring == .trend {
                hollow = row.close > row.open
                if let previous {
                    bodyColor = row.close > previous.close ? chartColor(item.up) : row.close < previous.close ? chartColor(item.down) : chartColor(theme.palette.neutral)
                } else {
                    bodyColor = chartColor(item.up)
                }
            } else {
                hollow = false
                bodyColor = chartColor(row.color ?? (up ? item.up : item.down))
            }
            context.stroke(wick, with: .color(chartColor(theme.candlestickWick, fallback: bodyColor)), lineWidth: 1)
            let rect = CGRect(x: x - width / 2, y: min(yPos(row.open, domain: domain, plot: plot), yPos(row.close, domain: domain, plot: plot)), width: width, height: max(1, abs(yPos(row.close, domain: domain, plot: plot) - yPos(row.open, domain: domain, plot: plot))))
            if hollow { context.stroke(Path(rect), with: .color(bodyColor), lineWidth: 1.5) }
            else { context.fill(Path(rect), with: .color(bodyColor)) }
            previous = row
        }
    }

    private func domain(_ scale: PriceScale, _ prepared: Prepared, _ range: LogicalRange) -> (Double, Double) {
        var values: [Double] = []
        for item in prepared.series where item.scale == scale || (scale == .right && !prepared.series.contains { $0.scale == .left } && item.scale == .right) || prepared.series.allSatisfy({ $0.scale == scale }) || (scale == .right && prepared.series.allSatisfy { $0.scale != .left }) {
            if item.scale != scale { continue }
            for row in item.rows {
                values.append(contentsOf: [row.low, row.high])
                if item.kind == .bar || item.kind == .histogram || item.kind == .baseline { values.append(item.base) }
            }
        }
        for guide in guides where guide.scale == scale { values.append(guide.value) }
        if scale == .right {
            for sample in ribbons { values.append(sample.upper); values.append(sample.lower) }
        }
        if histogramMode == .diverging {
            let pair = symmetricExtent(values)
            return (pair.min, pair.max == pair.min ? pair.max + 1 : pair.max)
        }
        let lo = values.min() ?? 0
        let hi = values.max() ?? 1
        return (lo, hi == lo ? hi + 1 : hi)
    }

    private func yPos(_ value: Double, domain: (Double, Double), plot: CGRect) -> CGFloat {
        let mapped = logScale && value > 0 ? log10(value) : value
        let span = domain.1 - domain.0
        let safe = span == 0 ? 1 : span
        return plot.minY + CGFloat((domain.1 - mapped) / safe) * plot.height
    }

    private func xPos(_ index: Double, plot: CGRect, range: LogicalRange) -> CGFloat {
        let span = range.span == 0 ? 1 : range.span
        return plot.minX + CGFloat((index - range.from) / span) * plot.width
    }

    private func aligned(_ item: DrawnSeries, times: [Int]) -> [PlotRow?] {
        let map = Dictionary(uniqueKeysWithValues: item.rows.map { ($0.time, $0) })
        return times.map { map[$0] }
    }

    private func bandSpan(_ start: Int, _ end: Int, times: [Int], plot: CGRect, range: LogicalRange) -> (CGFloat, CGFloat)? {
        guard let first = times.firstIndex(where: { $0 >= start }) else { return nil }
        let endIndex = times.firstIndex(where: { $0 >= end }) ?? times.count
        let last = endIndex - 1
        if last < first { return nil }
        return (xPos(Double(first) - 0.5, plot: plot, range: range), xPos(Double(last) + 0.5, plot: plot, range: range))
    }

    private func indexAt(_ x: CGFloat, plot: CGRect, range: LogicalRange, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let span = range.span == 0 ? 1 : range.span
        let raw = range.from + Double((x - plot.minX) / plot.width) * span
        return min(max(Int(raw.rounded()), 0), count - 1)
    }

    private func hits(_ prepared: Prepared, index: Int) -> [(String, Double)] {
        guard prepared.times.indices.contains(index) else { return [] }
        let time = prepared.times[index]
        return prepared.series.compactMap { item in
            guard item.tooltip, let row = item.rows.first(where: { $0.time == time }) else { return nil }
            return (item.id, row.close)
        }
    }

    private func drag(plot: CGRect, prepared: Prepared, range: LogicalRange) -> some Gesture {
        DragGesture(minimumDistance: 8).onChanged { value in
            if selecting { return }
            let base = panStart ?? range
            if panStart == nil { panStart = base }
            let shift = -Double(value.translation.width / max(plot.width, 1)) * base.span
            logical = LogicalRange(from: base.from + shift, to: base.to + shift)
            userAdjusted = true
            crosshair = indexAt(value.location.x, plot: plot, range: logical ?? range, count: prepared.times.count)
        }.onEnded { _ in panStart = nil }
    }

    private func zoomGesture(range: LogicalRange) -> some Gesture {
        MagnifyGesture().onChanged { value in
            guard chrome.zoom else { return }
            let base = pinchStart ?? range
            if pinchStart == nil { pinchStart = base }
            let delta = log(Double(value.magnification)) / 0.002
            logical = zoomRange(base, anchor: (base.from + base.to) / 2, delta: delta) ?? base
            userAdjusted = true
        }.onEnded { _ in pinchStart = nil }
    }

    private func selectGesture(plot: CGRect, prepared: Prepared) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3).sequenced(before: DragGesture(minimumDistance: 0)).onChanged { value in
            guard chrome.rangeSelect else { return }
            if case let .second(true, drag) = value, let drag {
                selecting = true
                selection = (drag.startLocation.x, drag.location.x)
            }
        }.onEnded { value in
            guard chrome.rangeSelect else { return }
            selecting = false
            if case let .second(true, drag) = value, let drag {
                let range = logical ?? fit(prepared.times.count)
                let a = indexAt(drag.startLocation.x, plot: plot, range: range, count: prepared.times.count)
                let b = indexAt(drag.location.x, plot: plot, range: range, count: prepared.times.count)
                logical = LogicalRange(from: Double(min(a, b)) - halfBar, to: Double(max(a, b)) + halfBar)
                userAdjusted = true
                if let stats = stats(prepared, range: logical!) { onRangeSelect?(stats) }
            }
            selection = nil
        }
    }

    private func stats(_ prepared: Prepared, range: LogicalRange) -> VisibleStats? {
        guard let rows = prepared.series.first?.rows, !prepared.times.isEmpty else { return nil }
        let start = min(max(Int(ceil(range.from)), 0), prepared.times.count - 1)
        let end = min(max(Int(floor(range.to)), 0), prepared.times.count - 1)
        let from = prepared.times[min(start, end)]
        let to = prepared.times[max(start, end)]
        let window = rows.filter { $0.time >= from && $0.time <= to }
        return visibleStats(window, from: 0, to: Double(window.count - 1))
    }

    private func report(_ prepared: Prepared, range: LogicalRange) {
        onVisibleStats?(stats(prepared, range: range))
    }

    private func applyPreset(_ prepared: Prepared) {
        guard !userAdjusted, let preset, let first = prepared.times.first, let last = prepared.times.last else { return }
        guard let window = presetRange(first: first, last: last, preset: preset) else { logical = nil; return }
        guard let start = prepared.times.firstIndex(where: { $0 >= window.from }), let end = prepared.times.lastIndex(where: { $0 <= window.to }) else { return }
        logical = LogicalRange(from: Double(start) - halfBar, to: Double(end) + halfBar)
    }

    private func nudge(_ delta: Int, _ prepared: Prepared) {
        let count = prepared.times.count
        guard count > 0 else { return }
        crosshair = min(max((crosshair ?? count - 1) + delta, 0), count - 1)
    }

    @ViewBuilder private func tooltip(_ prepared: Prepared, plot: CGRect, range: LogicalRange) -> some View {
        if let crosshair, prepared.times.indices.contains(crosshair) {
            let time = prepared.times[crosshair]
            let title = categories.flatMap { ordinalLabel(time, categories: $0).isEmpty ? nil : ordinalLabel(time, categories: $0) } ?? formatTime?(time) ?? defaultTimeLabel(unix: time, timeVisible: timeVisible)
            TooltipBox(title: title, rows: prepared.series.compactMap { item in
                guard item.tooltip, let row = item.rows.first(where: { $0.time == time }) else { return nil }
                let text = formatValue?(item.id, row.close) ?? formatChartNumber(row.close)
                return (item.name, text, chartColor(item.color))
            }, theme: theme)
            .padding(.leading, xPos(Double(crosshair), plot: plot, range: range))
            .padding(.top, 8)
        }
    }

    @ViewBuilder private func liveButton(_ prepared: Prepared) -> some View {
        if chrome.liveButton, chrome.followLive, !isLive(logical, lastIndex: prepared.times.count - 1) {
            Button("Live") { logical = nil; userAdjusted = false }
                .font(chartFont(theme.label, mono: true))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(chartColor(theme.palette.text), in: Capsule())
                .foregroundStyle(chartColor(theme.palette.background))
                .padding(8)
        }
    }
}

struct Prepared {
    var series: [DrawnSeries]
    var times: [Int]
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public struct LineChart: View {
    public var data: [LinePoint]
    public var variant: LineVariant
    public var bands: [BandItem]
    public var bandStyles: [String: BandStyleInput]
    public var overlays: [[LinePoint]]
    public var preset: RangePreset?
    public var anchor: ChartTime?
    public var logScale: Bool
    public var height: CGFloat
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var baseValue: Double
    public var onPointClick: ((Int, [(String, Double)]) -> Void)?
    public var onRangeSelect: ((VisibleStats) -> Void)?
    public var onReset: (() -> Void)?

    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [LinePoint], variant: LineVariant = .line, bands: [BandItem] = [], bandStyles: [String: BandStyleInput] = [:], overlays: [[LinePoint]] = [], range: RangePreset? = nil, anchor: ChartTime? = nil, logScale: Bool = false, height: CGFloat = 340, ariaLabel: String = "Line chart", theme: ChartTheme? = nil, baseValue: Double = 0, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil, onReset: (() -> Void)? = nil) {
        self.data = data
        self.variant = variant
        self.bands = bands
        self.bandStyles = bandStyles
        self.overlays = overlays
        self.preset = range
        self.anchor = anchor
        self.logScale = logScale
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.baseValue = baseValue
        self.onPointClick = onPointClick
        self.onRangeSelect = onRangeSelect
        self.onReset = onReset
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        SeriesPlot(series: lineSeries(theme), bands: bands, bandStyles: bandStyles, ribbons: [], guides: [], ranges: [], markers: [], chrome: SeriesChrome(), logScale: logScale, preset: preset, anchor: anchor, histogramMode: .plain, threshold: nil, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: onPointClick, onRangeSelect: onRangeSelect, onReset: onReset, onVisibleStats: nil)
    }

    private func lineSeries(_ theme: ChartTheme) -> [DrawnSeries] {
        let kind: SeriesKind = variant == .area ? .area : variant == .baseline ? .baseline : .line
        var drawn = [drawnSeries(id: "series", name: "Series", kind: kind, rows: normalizePoints(data), color: theme.line.color ?? theme.palette.down, theme: theme, base: baseValue)]
        for (index, overlay) in overlays.enumerated() {
            drawn.append(drawnSeries(id: "overlay-\(index)", name: "Overlay \(index + 1)", kind: .line, rows: normalizePoints(overlay), color: theme.line.overlays[safe: index] ?? categorical(theme, index + 1), theme: theme, base: 0))
        }
        return drawn
    }
}

public struct BarChart: View {
    public var data: [LinePoint]
    public var base: Double
    public var upColor: String
    public var downColor: String
    public var bands: [BandItem]
    public var height: CGFloat
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var preset: RangePreset?
    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [LinePoint], base: Double = 0, upColor: String = "#26a69a", downColor: String = "#ef5350", bands: [BandItem] = [], range: RangePreset? = nil, height: CGFloat = 340, ariaLabel: String = "Bar chart", theme: ChartTheme? = nil) {
        self.data = data
        self.base = base
        self.upColor = upColor
        self.downColor = downColor
        self.bands = bands
        self.preset = range
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        SeriesPlot(series: [barSeries(theme)], bands: bands, bandStyles: [:], ribbons: [], guides: [], ranges: [], markers: [], chrome: SeriesChrome(), logScale: false, preset: preset, anchor: nil, histogramMode: .plain, threshold: nil, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: nil, onRangeSelect: nil, onReset: nil, onVisibleStats: nil)
    }

    private func barSeries(_ theme: ChartTheme) -> DrawnSeries {
        var item = drawnSeries(id: "bars", name: "Bars", kind: .bar, rows: normalizePoints(data), color: upColor, theme: theme, base: base)
        item.up = upColor
        item.down = downColor
        return item
    }
}

public struct HistogramChart: View {
    public var data: [LinePoint]
    public var mode: HistogramMode
    public var threshold: Double?
    public var height: CGFloat
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [LinePoint], mode: HistogramMode = .plain, threshold: Double? = nil, height: CGFloat = 340, ariaLabel: String = "Histogram", theme: ChartTheme? = nil) {
        self.data = data
        self.mode = mode
        self.threshold = threshold
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let color = theme.histogram.bar ?? theme.palette.neutral
        let item = drawnSeries(id: "histogram", name: "Histogram", kind: .histogram, rows: normalizePoints(data), color: color, theme: theme, base: 0)
        SeriesPlot(series: [item], bands: [], bandStyles: [:], ribbons: [], guides: threshold.map { [TimeSeriesGuide(id: "threshold", value: $0, scale: .right)] } ?? [], ranges: [], markers: [], chrome: SeriesChrome(), logScale: false, preset: nil, anchor: nil, histogramMode: mode, threshold: threshold, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: nil, onRangeSelect: nil, onReset: nil, onVisibleStats: nil)
    }
}

public struct CandlestickChart: View {
    public var data: [OHLC]
    public var coloring: CandlestickColoring
    public var bands: [BandItem]
    public var preset: RangePreset?
    public var height: CGFloat
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var onRangeSelect: ((VisibleStats) -> Void)?
    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [OHLC], coloring: CandlestickColoring = .direction, bands: [BandItem] = [], range: RangePreset? = nil, height: CGFloat = 340, ariaLabel: String = "Candlestick chart", theme: ChartTheme? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil) {
        self.data = data
        self.coloring = coloring
        self.bands = bands
        self.preset = range
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.onRangeSelect = onRangeSelect
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        SeriesPlot(series: [candleSeries(theme)], bands: bands, bandStyles: [:], ribbons: [], guides: [], ranges: [], markers: [], chrome: SeriesChrome(), logScale: false, preset: preset, anchor: nil, histogramMode: .plain, threshold: nil, coloring: coloring, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: nil, onRangeSelect: onRangeSelect, onReset: nil, onVisibleStats: nil)
    }

    private func candleSeries(_ theme: ChartTheme) -> DrawnSeries {
        var item = drawnSeries(id: "candles", name: "Price", kind: .candle, rows: normalizeCandles(data), color: theme.palette.up, theme: theme, base: 0)
        item.up = theme.candlestickUp ?? theme.palette.up
        item.down = theme.candlestickDown ?? theme.palette.down
        return item
    }
}

public struct TimeSeriesChart: View {
    public var series: [TimeSeriesSpec]
    public var ribbons: [TimeSeriesRibbon]
    public var ranges: [TimeSeriesRange]
    public var guides: [TimeSeriesGuide]
    public var markers: [TimeSeriesMarker]
    public var profile: TimeSeriesProfile
    public var axis: TimeSeriesAxis
    public var categories: [String]
    public var height: CGFloat
    public var timeVisible: Bool
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var formatTime: ((Int) -> String)?
    public var formatValue: ((String, Double) -> String)?
    public var onPointClick: ((Int, [(String, Double)]) -> Void)?
    @Environment(\.chartTheme) private var environmentTheme

    public init(series: [TimeSeriesSpec], ribbons: [TimeSeriesRibbon] = [], ranges: [TimeSeriesRange] = [], guides: [TimeSeriesGuide] = [], markers: [TimeSeriesMarker] = [], profile: TimeSeriesProfile = .editorial, axis: TimeSeriesAxis = .time, categories: [String] = [], height: CGFloat = 340, timeVisible: Bool = false, ariaLabel: String = "Time series chart", theme: ChartTheme? = nil, formatTime: ((Int) -> String)? = nil, formatValue: ((String, Double) -> String)? = nil, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil) {
        self.series = series
        self.ribbons = ribbons
        self.ranges = ranges
        self.guides = guides
        self.markers = markers
        self.profile = profile
        self.axis = axis
        self.categories = categories
        self.height = height
        self.timeVisible = timeVisible
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.formatTime = formatTime
        self.formatValue = formatValue
        self.onPointClick = onPointClick
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let labels = axis == .ordinal ? categories : nil
        let drawn: [DrawnSeries] = series.enumerated().map { index, spec in
            let rows = seriesRows(spec.data, categories: labels).map { PlotRow(time: $0.time, open: $0.value, high: $0.value, low: $0.value, close: $0.value) }
            let kind: SeriesKind = spec.kind == .area ? .area : spec.kind == .histogram ? .histogram : .line
            let width = CGFloat(spec.lineWidth ?? (spec.kind == .line ? 2.0 : 1.0))
            return DrawnSeries(id: spec.id, name: spec.name, kind: kind, rows: rows, color: spec.color ?? categorical(theme, index), scale: spec.priceScale, lineWidth: width, dash: dashPattern(spec.lineStyle), tooltip: spec.includeInTooltip, base: 0, up: theme.palette.up, down: theme.palette.down, areaTop: theme.line.areaTop, areaBottom: theme.line.areaBottom)
        }
        let samples = ribbons.flatMap { ribbonSamples(upper: $0.upper, lower: $0.lower, categories: labels) }
        SeriesPlot(series: drawn, bands: [], bandStyles: [:], ribbons: samples, guides: guides, ranges: ranges, markers: markers, chrome: SeriesChrome(zoom: profile == .terminal, magnet: profile == .terminal, flash: false, followLive: false, rangeSelect: true, doubleTapReset: true, autoBucket: false, liveButton: false, profile: profile), logScale: false, preset: nil, anchor: nil, histogramMode: .plain, threshold: nil, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: labels, timeVisible: timeVisible, theme: theme, formatTime: formatTime, formatValue: formatValue, onPointClick: onPointClick, onRangeSelect: nil, onReset: nil, onVisibleStats: nil)
    }
}

func bucketedRows(_ rows: [PlotRow], kind: SeriesKind, size: Int) -> [PlotRow] {
    if kind == .candle {
        let candles = rows.map { OHLC(time: .unix($0.time), open: $0.open, high: $0.high, low: $0.low, close: $0.close, color: $0.color) }
        guard let aggregated = try? aggregateCandles(candles, bucketSize: size) else { return rows }
        return normalizeCandles(aggregated)
    }
    let points = rows.map { LinePoint(time: .unix($0.time), value: $0.close, color: $0.color) }
    guard let aggregated = try? aggregatePoints(points, bucketSize: size) else { return rows }
    return normalizePoints(aggregated)
}

func drawnSeries(id: String, name: String, kind: SeriesKind, rows: [PlotRow], color: String, theme: ChartTheme, base: Double) -> DrawnSeries {
    DrawnSeries(id: id, name: name, kind: kind, rows: rows, color: color, scale: .right, lineWidth: CGFloat(theme.line.width ?? 2.0), dash: [], tooltip: true, base: base, up: theme.palette.up, down: theme.palette.down, areaTop: theme.line.areaTop, areaBottom: theme.line.areaBottom)
}

public struct HistogramPane: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var meta: String?
    public var height: CGFloat
    public var data: [LinePoint]
    public var mode: HistogramMode
    public var threshold: Double?
    public init(id: String, title: String, meta: String? = nil, height: CGFloat = 52, data: [LinePoint], mode: HistogramMode = .plain, threshold: Double? = nil) {
        self.id = id
        self.title = title
        self.meta = meta
        self.height = height
        self.data = data
        self.mode = mode
        self.threshold = threshold
    }
}

public struct TimelineLane: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var meta: String?
    public var height: CGFloat
    public var items: [TimelineItem]
    public init(id: String, title: String, meta: String? = nil, height: CGFloat = 50, items: [TimelineItem]) {
        self.id = id
        self.title = title
        self.meta = meta
        self.height = height
        self.items = items
    }
}

public struct ChartPanes: View {
    public var panes: [HistogramPane]
    public var now: ChartTime?
    public var axisLabel: String?
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var onSelect: ((Int, [Double?]) -> Void)?
    @Environment(\.chartTheme) private var environmentTheme
    @State private var logical: LogicalRange?

    public init(panes: [HistogramPane], now: ChartTime? = nil, axisLabel: String? = nil, ariaLabel: String = "Chart panes", theme: ChartTheme? = nil, onSelect: ((Int, [Double?]) -> Void)? = nil) {
        self.panes = panes
        self.now = now
        self.axisLabel = axisLabel
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.onSelect = onSelect
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let times = Array(Set(panes.flatMap { normalizePoints($0.data).map(\.time) })).sorted()
        let range = logical ?? LogicalRange(from: -halfBar, to: Double(max(times.count - 1, 0)) + halfBar)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(panes) { pane in
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading) {
                        Text(pane.title).font(chartFont(theme.panesTitle, mono: false))
                        if let meta = pane.meta { Text(meta).font(chartFont(theme.panesMeta, mono: true)) }
                    }
                    .frame(width: 120, alignment: .leading)
                    HistogramChart(data: pane.data, mode: pane.mode, threshold: pane.threshold, height: pane.height, theme: theme)
                }
                .padding(.vertical, 4)
            }
            if let axisLabel { Text(axisLabel).font(chartFont(theme.axis, mono: true)).padding(.top, 4) }
        }
        .accessibilityLabel(ariaLabel)
        .onTapGesture { onSelect?(times.last ?? 0, panes.map { $0.data.last?.value }) }
        .background(chartColor(theme.palette.background))
        .overlay {
            if let now, let time = toUnixSeconds(now), let index = times.firstIndex(of: time) {
                GeometryReader { geo in
                    let x = CGFloat((Double(index) - range.from) / max(range.span, 1)) * geo.size.width
                    Rectangle().fill(chartColor(theme.panesNow ?? theme.palette.now)).frame(width: 1).position(x: x, y: geo.size.height / 2)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

public struct TimelineChart: View {
    public var lanes: [TimelineLane]
    public var step: Int
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    @Environment(\.chartTheme) private var environmentTheme

    public init(lanes: [TimelineLane], step: Int = 3600, ariaLabel: String = "Timeline", theme: ChartTheme? = nil) {
        self.lanes = lanes
        self.step = step
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let times = lanes.flatMap { $0.items.flatMap { [ $0.start, $0.end ] } }
        let grid = timeGrid(times, step: step)
        let first = grid.first ?? 0
        let last = grid.last ?? 1
        VStack(alignment: .leading, spacing: 8) {
            ForEach(lanes) { lane in
                VStack(alignment: .leading, spacing: 4) {
                    Text(lane.title).font(chartFont(theme.panesTitle, mono: false)).foregroundStyle(chartColor(theme.palette.text))
                    Canvas { context, size in
                        for item in timelineRanges(lane.items) {
                            guard let start = toUnixSeconds(item.from), let end = toUnixSeconds(item.to), last > first else { continue }
                            let x0 = CGFloat(start - first) / CGFloat(last - first) * size.width
                            let x1 = CGFloat(end - first) / CGFloat(last - first) * size.width
                            let height = theme.timelineBarHeight
                            let rect = CGRect(x: min(x0, x1), y: (size.height - height) / 2, width: max(2, abs(x1 - x0)), height: height)
                            let style = theme.timelineStyles[item.key]
                            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(chartColor(item.color ?? style?.fill, fallback: chartColor(categorical(theme, 0)).opacity(0.8))))
                            if item.key == "arrival" || item.key == "tentative" { strokeHatch(context, rect: rect, color: chartColor(style?.hatch ?? theme.palette.neutral)) }
                            if let label = item.label {
                                context.draw(Text(label).font(chartFont(theme.label, mono: true)).foregroundStyle(chartColor(theme.palette.background)), at: CGPoint(x: rect.minX + 8, y: rect.midY), anchor: .leading)
                            }
                        }
                    }
                    .frame(height: lane.height)
                }
            }
        }
        .accessibilityLabel(ariaLabel)
    }
}
