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

struct DrawnRibbon {
    var samples: [RibbonSample]
    var color: String?
    var opacity: Double
    var scale: PriceScale
}

/// What a host app leaves to the chart. `.terminal` is the trading surface.
/// `.embedded` draws the series and a scrub rule, so the host keeps its own axes and readout.
public struct ChartChrome: Equatable, Sendable {
    public var zoom: Bool
    public var pan: Bool
    public var magnet: Bool
    public var flash: Bool
    public var followLive: Bool
    public var rangeSelect: Bool
    public var doubleTapReset: Bool
    public var liveButton: Bool
    public var axes: Bool
    public var tooltip: Bool
    public var scrub: ScrubStyle
    public var sticky: Bool
    public var showExtremes: Bool

    public init(zoom: Bool = true, pan: Bool = true, magnet: Bool = true, flash: Bool = true, followLive: Bool = true, rangeSelect: Bool = true, doubleTapReset: Bool = true, liveButton: Bool = true, axes: Bool = true, tooltip: Bool = true, scrub: ScrubStyle = .ruleDotAndTooltip, sticky: Bool = false, showExtremes: Bool = false) {
        self.zoom = zoom
        self.pan = pan
        self.magnet = magnet
        self.flash = flash
        self.followLive = followLive
        self.rangeSelect = rangeSelect
        self.doubleTapReset = doubleTapReset
        self.liveButton = liveButton
        self.axes = axes
        self.tooltip = tooltip
        self.scrub = scrub
        self.sticky = sticky
        self.showExtremes = showExtremes
    }

    public static let terminal = ChartChrome()
    public static let embedded = ChartChrome(zoom: false, pan: false, magnet: false, flash: false, followLive: false, rangeSelect: false, doubleTapReset: false, liveButton: false, axes: false, tooltip: false, scrub: .ruleAndDot)
}

struct SeriesChrome {
    var zoom = true
    var pan = true
    var magnet = true
    var flash = true
    var followLive = true
    var rangeSelect = true
    var doubleTapReset = true
    var autoBucket = false
    var minBarWidth: Double = 6
    var liveButton = true
    var axes = true
    var tooltip = true
    var profile: TimeSeriesProfile = .terminal
    var scrub: ScrubStyle = .ruleDotAndTooltip
    var sticky = false
    var showExtremes = false

    init(zoom: Bool = true, pan: Bool = true, magnet: Bool = true, flash: Bool = true, followLive: Bool = true, rangeSelect: Bool = true, doubleTapReset: Bool = true, autoBucket: Bool = false, minBarWidth: Double = 6, liveButton: Bool = true, axes: Bool = true, tooltip: Bool = true, profile: TimeSeriesProfile = .terminal, scrub: ScrubStyle = .ruleDotAndTooltip, sticky: Bool = false, showExtremes: Bool = false) {
        self.zoom = zoom
        self.pan = pan
        self.magnet = magnet
        self.flash = flash
        self.followLive = followLive
        self.rangeSelect = rangeSelect
        self.doubleTapReset = doubleTapReset
        self.autoBucket = autoBucket
        self.minBarWidth = minBarWidth
        self.liveButton = liveButton
        self.axes = axes
        self.tooltip = tooltip
        self.profile = profile
        self.scrub = scrub
        self.sticky = sticky
        self.showExtremes = showExtremes
    }

    init(_ chrome: ChartChrome) {
        self.init(zoom: chrome.zoom, pan: chrome.pan, magnet: chrome.magnet, flash: chrome.flash, followLive: chrome.followLive, rangeSelect: chrome.rangeSelect, doubleTapReset: chrome.doubleTapReset, liveButton: chrome.liveButton, axes: chrome.axes, tooltip: chrome.tooltip, profile: chrome.magnet ? .terminal : .editorial, scrub: chrome.scrub, sticky: chrome.sticky, showExtremes: chrome.showExtremes)
    }
}

struct SeriesPlot: View {
    var series: [DrawnSeries]
    var bands: [BandItem]
    var bandStyles: [String: BandStyleInput]
    var ribbons: [DrawnRibbon]
    var guides: [TimeSeriesGuide]
    var ranges: [TimeSeriesRange]
    var markers: [TimeSeriesMarker]
    var chrome: SeriesChrome
    var logScale: Bool
    var preset: RangePreset?
    var anchor: ChartTime?
    var now: ChartTime? = nil
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
    var selection: Binding<ChartSelection?>? = nil
    var chartState: ChartState = .ready

    @State private var logical: LogicalRange?
    @State private var userAdjusted = false
    @State private var crosshair: Int?
    @State private var flash: TickDirection?
    @State private var previous: [PlotRow] = []
    @State private var selecting = false
    @State private var rangeSelection: (CGFloat, CGFloat)?
    @State private var panStart: LogicalRange?
    @State private var pinchStart: LogicalRange?
    @State private var plotWidth: CGFloat = 0
    @State private var tooltipWidth: CGFloat = 0
    @State private var accessSamples: [ChartSeriesSample] = []
    @State private var accessSummary: String = ""
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.chartAccessibility) private var chartAccessibility

    var body: some View {
        let prepared = prepare(plotWidth: plotWidth)
        let range = logical ?? fit(prepared.times.count)
        let resolved = resolveChartState(chartState, hasRows: !prepared.times.isEmpty)
        let presentation = chartStatePresentation(resolved) { date in
            formatAxisDate(Int(date.timeIntervalSince1970), calendar: .current, step: .hour)
        }
        VStack(spacing: 0) {
            GeometryReader { geo in
                let size = geo.size
                let pads = pads(for: prepared.series)
                let plot = CGRect(x: pads.left, y: pads.top, width: max(1, size.width - pads.left - pads.right), height: max(1, size.height - pads.top - pads.bottom))
                let canvas = Canvas { context, _ in
                    drawPlot(context, size: size, plot: plot, prepared: prepared, range: range, state: resolved)
                }
                .simultaneousGesture(zoomGesture(plot: plot, range: range))
                .simultaneousGesture(selectGesture(plot: plot, prepared: prepared))
                pointerLayer(canvas, plot: plot, prepared: prepared, range: range)
                .overlay(alignment: .topLeading) { tooltip(prepared, plot: plot, range: range) }
                .overlay(alignment: .bottomLeading) { stateLabel(presentation) }
                .overlay(alignment: .bottomTrailing) { liveButton(prepared) }
                .onAppear { plotWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, width in plotWidth = width }
            }
            .frame(height: height)
        }
        .background(chartColor(theme.palette.background))
        .chartAccess(chartAccessibility, title: ariaLabel, summary: accessSummary.isEmpty ? presentation.accessibility ?? ariaLabel : accessSummary, samples: accessSamples, categorical: categories != nil)
        .accessibilityValue(readout(prepared, range: range))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? 1 : -1
            guard let index = steppedIndex(delta, prepared) else { return }
            publishSelection(index, prepared: prepared, range: range)
        }
        .accessibilityRotor("Chart landmarks") {
            ForEach(landmarks(prepared, range: range)) { mark in
                AccessibilityRotorEntry(mark.label, id: mark.id) {
                    publishSelection(mark.index, prepared: prepared, range: range)
                }
            }
        }
        .modifier(SeriesZoomAccess(enabled: chrome.zoom) { action in
            let current = logical ?? fit(prepared.times.count)
            let anchor = (current.from + current.to) / 2
            let delta: Double = action.direction == .zoomIn ? -500 : 500
            if let next = zoomRange(current, anchor: anchor, delta: delta) {
                logical = next
                userAdjusted = true
            }
        })
        .focusable()
        .focused($focused)
        .onKeyPress(.leftArrow) { moveCrosshair(-1, prepared, range: range); return .handled }
        .onKeyPress(.rightArrow) { moveCrosshair(1, prepared, range: range); return .handled }
        .onKeyPress(.escape) { rangeSelection = nil; selecting = false; return .handled }
        .onAppear {
            applyPreset(prepared)
            let shown = logical ?? fit(prepared.times.count)
            report(prepared, range: shown)
            refreshAccess(prepared, range: shown, state: resolved)
        }
        .onChange(of: preset) { _, newValue in
            userAdjusted = false
            withAnimation(chartMotion(reduceMotion: reduceMotion)) { applyPreset(prepared) }
            let shown = logical ?? fit(prepared.times.count)
            report(prepared, range: shown)
            refreshAccess(prepared, range: shown, state: resolved)
            if let newValue {
                let window = stats(prepared, range: shown)
                let from = window.map { Date(timeIntervalSince1970: TimeInterval($0.from)) }
                let to = window.map { Date(timeIntervalSince1970: TimeInterval($0.to)) }
                AccessibilityNotification.Announcement(presetAnnouncement(newValue, from: from, to: to) { date in
                    formatAxisDate(Int(date.timeIntervalSince1970), calendar: .current, step: .day)
                }).post()
            }
        }
        .onChange(of: revision) { _, _ in
            let next = prepared.series.first?.rows ?? []
            if chrome.flash, let direction = tickDirection(previous: previous, next: next) { flash = direction }
            crosshair = nil
            if !chrome.sticky { selection?.wrappedValue = nil }
            logical = logicalRangeAfterUpdate(preset: preset, times: prepared.times, followLive: chrome.followLive, userAdjusted: userAdjusted, current: logical)
            previous = next
            let shown = logical ?? fit(prepared.times.count)
            report(prepared, range: shown)
            refreshAccess(prepared, range: shown, state: resolved)
        }
        .task(id: flash) {
            guard flash != nil else { return }
            if reduceMotion { flash = nil; return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            flash = nil
        }
    }

    @ViewBuilder private func pointerLayer<V: View>(_ view: V, plot: CGRect, prepared: Prepared, range: LogicalRange) -> some View {
        let panGesture = drag(plot: plot, prepared: prepared, range: range)
        let scrub = scrubGesture(plot: plot, prepared: prepared, range: range)
        let dragging = SeriesDrag(pan: chrome.pan, scrubs: chrome.scrub != .none && !chrome.pan, drag: panGesture, scrub: scrub)
        if chrome.doubleTapReset {
            view
                .onTapGesture(count: 2) {
                    withAnimation(chartMotion(reduceMotion: reduceMotion)) {
                        logical = nil
                        userAdjusted = false
                    }
                    clearSelection()
                    onReset?()
                }
                .onTapGesture { location in
                    publishSelection(indexAt(location.x, plot: plot, range: range, count: prepared.times.count), prepared: prepared, range: range)
                }
                .modifier(dragging)
        } else {
            view
                .gesture(SpatialTapGesture().onEnded { value in
                    publishSelection(indexAt(value.location.x, plot: plot, range: range, count: prepared.times.count), prepared: prepared, range: range)
                })
                .modifier(dragging)
        }
    }

    private var revision: String {
        series.map { "\($0.id):\($0.rows.count):\($0.rows.last?.close ?? 0)" }.joined(separator: "|")
    }

    private func prepare(plotWidth: CGFloat = 0) -> Prepared {
        var source = series
        if chrome.autoBucket, source.count == 1, var only = source.first, only.rows.count > 2 {
            let width = plotWidth > 1 ? Double(plotWidth) : 320
            let px = width / Double(only.rows.count)
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
        if !chrome.axes { return (6, 8, 6, 8) }
        let right: CGFloat = series.contains { $0.scale == .right } || series.isEmpty ? 48 : 12
        let left: CGFloat = series.contains { $0.scale == .left } ? 48 : 12
        return (12, right, 28, left)
    }

    private func drawPlot(_ context: GraphicsContext, size: CGSize, plot: CGRect, prepared: Prepared, range: LogicalRange, state: ChartState) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(chartColor(theme.palette.background)))
        let fadeLast: Bool
        if case .partial = state { fadeLast = true } else { fadeLast = false }
        context.drawLayer { layer in
            layer.clip(to: Path(plot))
            guard chartStateDrawsSeries(state) else {
                var baseline = Path()
                baseline.move(to: CGPoint(x: plot.minX, y: plot.midY))
                baseline.addLine(to: CGPoint(x: plot.maxX, y: plot.midY))
                layer.stroke(baseline, with: .color(chartColor(theme.palette.grid)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                return
            }
            drawClipped(layer, plot: plot, prepared: prepared, range: range, fadeLast: fadeLast)
        }
        guard chartStateDrawsSeries(state), chrome.axes else { return }
        let scales = axisScales(prepared)
        for scale in scales.labeled {
            let extent = domain(scale, prepared, range)
            let anchor: UnitPoint = scale == .left ? .trailing : .leading
            let x = scale == .left ? plot.minX - 6 : plot.maxX + 6
            for tick in priceTicks(extent) {
                let y = yPos(tick.value, domain: extent, plot: plot)
                context.draw(
                    Text(tick.label).font(chartFont(theme.axis, mono: true)).foregroundStyle(chartColor(theme.palette.text)),
                    at: CGPoint(x: x, y: y),
                    anchor: anchor
                )
            }
        }
        drawTimeLabels(context, prepared: prepared, plot: plot, range: range)
    }

    private func drawClipped(_ context: GraphicsContext, plot: CGRect, prepared: Prepared, range: LogicalRange, fadeLast: Bool) {
        if chrome.axes {
            let scales = axisScales(prepared)
            let gridDomain = domain(scales.grid, prepared, range)
            for tick in priceTicks(gridDomain) {
                let y = yPos(tick.value, domain: gridDomain, plot: plot)
                var path = Path()
                path.move(to: CGPoint(x: plot.minX, y: y))
                path.addLine(to: CGPoint(x: plot.maxX, y: y))
                context.stroke(path, with: .color(chartColor(theme.palette.grid)), lineWidth: 1)
            }
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
        for ribbon in ribbons {
            let extent = domain(ribbon.scale, prepared, range)
            var upper: [CGPoint] = []
            var lower: [CGPoint] = []
            for sample in ribbon.samples {
                guard let slot = prepared.times.firstIndex(of: sample.time) else { continue }
                let x = xPos(Double(slot), plot: plot, range: range)
                upper.append(CGPoint(x: x, y: yPos(sample.upper, domain: extent, plot: plot)))
                lower.append(CGPoint(x: x, y: yPos(sample.lower, domain: extent, plot: plot)))
            }
            guard let first = upper.first else { continue }
            var path = Path()
            path.move(to: first)
            for point in upper.dropFirst() { path.addLine(to: point) }
            for point in lower.reversed() { path.addLine(to: point) }
            path.closeSubpath()
            let fill = chartColor(ribbon.color ?? theme.palette.categorical.first, fallback: chartColor(theme.palette.neutral))
            context.fill(path, with: .color(fill.opacity(ribbon.opacity)))
        }
        for item in prepared.series {
            let values = aligned(item, times: prepared.times)
            let domain = domain(item.scale, prepared, range)
            switch item.kind {
            case .line, .area, .baseline:
                strokeLine(context, item: item, values: values, domain: domain, plot: plot, range: range, fadeLast: fadeLast)
            case .histogram, .bar:
                strokeColumns(context, item: item, values: values, domain: domain, plot: plot, range: range, fadeLast: fadeLast)
            case .candle:
                strokeCandles(context, item: item, values: values, domain: domain, plot: plot, range: range, fadeLast: fadeLast)
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
        if let anchor, let time = toUnixSeconds(anchor), let row = prepared.series.first?.rows.last(where: { $0.time <= time }) {
            let domain = domain(prepared.series.first?.scale ?? .right, prepared, range)
            let y = yPos(row.close, domain: domain, plot: plot)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: y))
            path.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.stroke(path, with: .color(chartColor(theme.anchorColor, fallback: chartColor(theme.palette.neutral))), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        }
        if showsRule, let crosshair, prepared.times.indices.contains(crosshair) {
            let x = xPos(Double(crosshair), plot: plot, range: range)
            var path = Path()
            path.move(to: CGPoint(x: x, y: plot.minY))
            path.addLine(to: CGPoint(x: x, y: plot.maxY))
            context.stroke(path, with: .color(chartColor(theme.palette.crosshair)), style: StrokeStyle(lineWidth: 1, dash: chrome.profile == .editorial ? [] : [3, 3]))
            if showsScrubDot {
                for item in prepared.series {
                    let values = aligned(item, times: prepared.times)
                    guard values.indices.contains(crosshair), let row = values[crosshair] else { continue }
                    let y = yPos(row.close, domain: domain(item.scale, prepared, range), plot: plot)
                    let dot = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: dot), with: .color(chartColor(item.color)))
                    context.stroke(Path(ellipseIn: dot), with: .color(chartColor(theme.palette.background)), lineWidth: 1.5)
                }
            }
            if chrome.magnet, let time = prepared.times[safe: crosshair],
               let item = prepared.series.first(where: { $0.rows.contains { $0.time == time } }),
               let row = item.rows.first(where: { $0.time == time }) {
                let y = yPos(row.close, domain: domain(item.scale, prepared, range), plot: plot)
                var horizontal = Path()
                horizontal.move(to: CGPoint(x: plot.minX, y: y))
                horizontal.addLine(to: CGPoint(x: plot.maxX, y: y))
                context.stroke(horizontal, with: .color(chartColor(item.color)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        if let now, let time = toUnixSeconds(now), let x = xForTime(time, times: prepared.times, plot: plot, range: range) {
            var path = Path()
            path.move(to: CGPoint(x: x, y: plot.minY))
            path.addLine(to: CGPoint(x: x, y: plot.maxY))
            context.stroke(path, with: .color(chartColor(theme.panesNow ?? theme.palette.now)), lineWidth: 1)
        }
        if let rangeSelection {
            let rect = CGRect(x: min(rangeSelection.0, rangeSelection.1), y: plot.minY, width: abs(rangeSelection.1 - rangeSelection.0), height: plot.height)
            context.fill(Path(rect), with: .color(chartColor(theme.palette.crosshair).opacity(0.15)))
        }
        if chrome.showExtremes { drawExtremes(context, prepared: prepared, plot: plot, range: range) }
    }

    private var showsRule: Bool {
        chrome.scrub != .none || chrome.magnet || chrome.tooltip
    }

    private var showsScrubDot: Bool {
        chrome.scrub == .ruleAndDot || chrome.scrub == .ruleDotAndTooltip
    }

    private var showsTooltip: Bool {
        chrome.tooltip || chrome.scrub == .ruleDotAndTooltip
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

    private func strokeLine(_ context: GraphicsContext, item: DrawnSeries, values: [PlotRow?], domain: (Double, Double), plot: CGRect, range: LogicalRange, fadeLast: Bool) {
        var line = Path()
        var tail = Path()
        var area = Path()
        var started = false
        var previousPoint: CGPoint?
        var firstX: CGFloat = 0
        var lastX: CGFloat = 0
        var topY = plot.maxY
        let lastDrawn = fadeLast ? values.lastIndex(where: { $0 != nil }) : nil
        for (index, row) in values.enumerated() {
            guard let row else { continue }
            let point = CGPoint(x: xPos(Double(index), plot: plot, range: range), y: yPos(row.close, domain: domain, plot: plot))
            if !started {
                line.move(to: point)
                area.move(to: point)
                firstX = point.x
                started = true
            } else if index == lastDrawn, let previousPoint {
                tail.move(to: previousPoint)
                tail.addLine(to: point)
            } else {
                line.addLine(to: point)
            }
            area.addLine(to: point)
            lastX = point.x
            topY = min(topY, point.y)
            previousPoint = point
        }
        if started, item.kind == .area || item.kind == .baseline {
            if item.kind == .baseline {
                let baseY = yPos(item.base, domain: domain, plot: plot)
                area.addLine(to: CGPoint(x: lastX, y: baseY))
                area.addLine(to: CGPoint(x: firstX, y: baseY))
                area.closeSubpath()
                fillBaseline(context, area: area, item: item, baseY: baseY, plot: plot)
            } else {
                let baseY = chrome.axes ? yPos(domain.0, domain: domain, plot: plot) : plot.maxY
                area.addLine(to: CGPoint(x: lastX, y: baseY))
                area.addLine(to: CGPoint(x: firstX, y: baseY))
                area.closeSubpath()
                let fill = resolveAreaFill(areaTop: item.areaTop, areaBottom: item.areaBottom, line: item.color, opacity: theme.line.areaOpacity)
                fillGradient(context, path: area, top: fill.top, bottom: fill.bottom, from: CGPoint(x: plot.midX, y: topY), to: CGPoint(x: plot.midX, y: baseY))
            }
        }
        let stroke = StrokeStyle(lineWidth: item.lineWidth, lineCap: .round, lineJoin: .round, dash: item.dash)
        context.stroke(line, with: .color(chartColor(item.color)), style: stroke)
        if !tail.isEmpty {
            context.stroke(tail, with: .color(chartColor(item.color).opacity(0.45)), style: stroke)
        }
        if let flash, let last = values.lastIndex(where: { $0 != nil }), let row = values[last] {
            let point = CGPoint(x: xPos(Double(last), plot: plot, range: range), y: yPos(row.close, domain: domain, plot: plot))
            let color = flash == .up ? chartColor(item.up) : chartColor(item.down)
            context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(color))
        }
    }

    private func strokeColumns(_ context: GraphicsContext, item: DrawnSeries, values: [PlotRow?], domain: (Double, Double), plot: CGRect, range: LogicalRange, fadeLast: Bool) {
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
            let faded = fadeLast && index == values.lastIndex(where: { $0 != nil })
            context.fill(Path(rect), with: .color(chartColor(color).opacity(faded ? 0.45 : 1)))
            if flash != nil, index == values.lastIndex(where: { $0 != nil }) {
                context.stroke(Path(rect), with: .color(flash == .up ? chartColor(item.up) : chartColor(item.down)), lineWidth: 2)
            }
        }
    }

    private func strokeCandles(_ context: GraphicsContext, item: DrawnSeries, values: [PlotRow?], domain: (Double, Double), plot: CGRect, range: LogicalRange, fadeLast: Bool) {
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
            let faded = fadeLast && index == values.lastIndex(where: { $0 != nil })
            let ink = faded ? bodyColor.opacity(0.45) : bodyColor
            context.stroke(wick, with: .color(chartColor(theme.candlestickWick, fallback: ink).opacity(faded ? 0.45 : 1)), lineWidth: 1)
            let rect = CGRect(x: x - width / 2, y: min(yPos(row.open, domain: domain, plot: plot), yPos(row.close, domain: domain, plot: plot)), width: width, height: max(1, abs(yPos(row.close, domain: domain, plot: plot) - yPos(row.open, domain: domain, plot: plot))))
            if hollow { context.stroke(Path(rect), with: .color(ink), lineWidth: 1.5) }
            else { context.fill(Path(rect), with: .color(ink)) }
            previous = row
        }
    }

    private func domain(_ scale: PriceScale, _ prepared: Prepared, _ range: LogicalRange) -> (Double, Double) {
        let window = visibleBarSpan(count: prepared.times.count, range: range)
        let loTime = window.map { prepared.times[$0.lowerBound] }
        let hiTime = window.map { prepared.times[$0.upperBound] }
        func include(_ time: Int) -> Bool {
            guard let loTime, let hiTime else { return true }
            return time >= loTime && time <= hiTime
        }
        func collect(visibleOnly: Bool) -> [Double] {
            var values: [Double] = []
            for item in prepared.series where item.scale == scale {
                for row in item.rows where !visibleOnly || include(row.time) {
                    values.append(contentsOf: [row.low, row.high])
                    if item.kind == .bar || item.kind == .histogram || item.kind == .baseline { values.append(item.base) }
                }
            }
            for ribbon in ribbons where ribbon.scale == scale {
                for sample in ribbon.samples where !visibleOnly || include(sample.time) {
                    values.append(sample.upper)
                    values.append(sample.lower)
                }
            }
            return values
        }
        var values = collect(visibleOnly: true)
        if values.isEmpty { values = collect(visibleOnly: false) }
        for guide in guides where guide.scale == scale { values.append(guide.value) }
        if histogramMode == .diverging {
            let pair = symmetricExtent(values)
            return (pair.min, pair.max == pair.min ? pair.max + 1 : pair.max)
        }
        let lo = values.min() ?? 0
        let hi = values.max() ?? 1
        return (lo, hi == lo ? hi + 1 : hi)
    }

    private func yPos(_ value: Double, domain: (Double, Double), plot: CGRect) -> CGFloat {
        plot.minY + CGFloat(pricePlotFraction(value: value, lower: domain.0, upper: domain.1, logScale: logScale)) * plot.height
    }

    private func priceTicks(_ extent: (Double, Double)) -> [AxisTick] {
        if logScale, extent.0 > 0, extent.1 > extent.0 {
            let powers = niceAxisTicks(min: log10(extent.0), max: log10(extent.1)).map { pow(10, $0.value) }
            return labelledAxisTicks(powers, locale: .current)
        }
        return niceAxisTicks(min: extent.0, max: extent.1)
    }

    private func axisScales(_ prepared: Prepared) -> (grid: PriceScale, labeled: [PriceScale]) {
        let hasLeft = prepared.series.contains { $0.scale == .left } || guides.contains { $0.scale == .left }
        let hasRight = prepared.series.isEmpty
            || prepared.series.contains { $0.scale == .right }
            || guides.contains { $0.scale == .right }
            || ribbons.contains { $0.scale == .right }
        let grid: PriceScale = hasRight || !hasLeft ? .right : .left
        var labeled: [PriceScale] = []
        if hasLeft { labeled.append(.left) }
        if hasRight { labeled.append(.right) }
        return (grid, labeled)
    }

    private func fillBaseline(_ context: GraphicsContext, area: Path, item: DrawnSeries, baseY: CGFloat, plot: CGRect) {
        let above = CGRect(x: plot.minX, y: plot.minY, width: plot.width, height: max(0, baseY - plot.minY))
        let below = CGRect(x: plot.minX, y: baseY, width: plot.width, height: max(0, plot.maxY - baseY))
        let top = resolveAreaFill(areaTop: item.areaTop, areaBottom: nil, line: item.color, opacity: theme.line.areaOpacity).top
        let bottom: RGBA
        if let areaBottom = item.areaBottom, let parsed = parseColor(areaBottom) {
            bottom = parsed
        } else {
            bottom = resolveAreaFill(areaTop: nil, areaBottom: nil, line: item.color, opacity: theme.line.areaOpacity).top
        }
        let clearTop = RGBA(r: top.r, g: top.g, b: top.b, a: 0)
        let clearBottom = RGBA(r: bottom.r, g: bottom.g, b: bottom.b, a: 0)
        context.drawLayer { layer in
            layer.clip(to: Path(above))
            fillGradient(layer, path: area, top: top, bottom: clearTop, from: CGPoint(x: plot.midX, y: above.minY), to: CGPoint(x: plot.midX, y: baseY))
        }
        context.drawLayer { layer in
            layer.clip(to: Path(below))
            fillGradient(layer, path: area, top: clearBottom, bottom: bottom, from: CGPoint(x: plot.midX, y: baseY), to: CGPoint(x: plot.midX, y: below.maxY))
        }
    }

    private func fillGradient(_ context: GraphicsContext, path: Path, top: RGBA, bottom: RGBA, from: CGPoint, to: CGPoint) {
        if hypot(from.x - to.x, from.y - to.y) < 0.5 {
            context.fill(path, with: .color(chartColor(top)))
            return
        }
        context.fill(path, with: .linearGradient(Gradient(colors: [chartColor(top), chartColor(bottom)]), startPoint: from, endPoint: to))
    }

    private func xForTime(_ time: Int, times: [Int], plot: CGRect, range: LogicalRange) -> CGFloat? {
        if let index = times.firstIndex(of: time) { return xPos(Double(index), plot: plot, range: range) }
        guard let after = times.firstIndex(where: { $0 > time }), after > 0 else { return nil }
        let before = after - 1
        let span = Double(times[after] - times[before])
        let fraction = span > 0 ? Double(time - times[before]) / span : 0
        return xPos(Double(before) + fraction, plot: plot, range: range)
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
            publishSelection(indexAt(value.location.x, plot: plot, range: logical ?? range, count: prepared.times.count), prepared: prepared, range: logical ?? range)
        }.onEnded { _ in panStart = nil }
    }

    private func scrubGesture(plot: CGRect, prepared: Prepared, range: LogicalRange) -> some Gesture {
        let press = LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case let .second(true, drag?) = value else { return }
                publishSelection(indexAt(drag.location.x, plot: plot, range: logical ?? range, count: prepared.times.count), prepared: prepared, range: logical ?? range)
            }
            .onEnded { _ in
                if !chrome.sticky { clearSelection() }
            }
        let horizontal = DragGesture(minimumDistance: 12).onChanged { value in
            guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
            publishSelection(indexAt(value.location.x, plot: plot, range: logical ?? range, count: prepared.times.count), prepared: prepared, range: logical ?? range)
        }.onEnded { _ in
            if !chrome.sticky { clearSelection() }
        }
        return press.simultaneously(with: horizontal)
    }

    private func zoomGesture(plot: CGRect, range: LogicalRange) -> some Gesture {
        MagnifyGesture().onChanged { value in
            guard chrome.zoom else { return }
            let base = pinchStart ?? range
            if pinchStart == nil { pinchStart = base }
            guard let delta = pinchZoomDelta(magnification: Double(value.magnification)) else { return }
            let anchor = logicalIndex(atX: Double(value.startLocation.x), plotMinX: Double(plot.minX), plotWidth: Double(plot.width), range: base)
            logical = zoomRange(base, anchor: anchor, delta: delta) ?? base
            userAdjusted = true
        }.onEnded { _ in pinchStart = nil }
    }

    private func selectGesture(plot: CGRect, prepared: Prepared) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3).sequenced(before: DragGesture(minimumDistance: 0)).onChanged { value in
            guard chrome.rangeSelect else { return }
            switch value {
            case .first(true):
                selecting = true
                if let base = panStart {
                    logical = base
                    panStart = nil
                }
            case let .second(true, drag?):
                selecting = true
                if let base = panStart {
                    logical = base
                    panStart = nil
                }
                rangeSelection = (drag.startLocation.x, drag.location.x)
            default:
                break
            }
        }.onEnded { value in
            guard chrome.rangeSelect else { return }
            selecting = false
            if case let .second(true, drag?) = value {
                if let base = panStart {
                    logical = base
                    panStart = nil
                }
                let current = logical ?? fit(prepared.times.count)
                let a = indexAt(drag.startLocation.x, plot: plot, range: current, count: prepared.times.count)
                let b = indexAt(drag.location.x, plot: plot, range: current, count: prepared.times.count)
                guard prepared.times.indices.contains(a), prepared.times.indices.contains(b) else { rangeSelection = nil; return }
                let chosen = LogicalRange(from: Double(min(a, b)) - halfBar, to: Double(max(a, b)) + halfBar)
                logical = chosen
                userAdjusted = true
                if let stats = stats(prepared, range: chosen) { onRangeSelect?(stats) }
            }
            rangeSelection = nil
        }
    }

    private func stats(_ prepared: Prepared, range: LogicalRange) -> VisibleStats? {
        guard let rows = prepared.series.first?.rows, !prepared.times.isEmpty else { return nil }
        let start = min(max(Int(ceil(range.from)), 0), prepared.times.count - 1)
        let end = min(max(Int(floor(range.to)), 0), prepared.times.count - 1)
        let from = prepared.times[min(start, end)]
        let to = prepared.times[max(start, end)]
        let window = rows.filter { $0.time >= from && $0.time <= to }
        guard !window.isEmpty else { return nil }
        return visibleStats(window, from: 0, to: Double(window.count - 1))
    }

    private func report(_ prepared: Prepared, range: LogicalRange) {
        onVisibleStats?(stats(prepared, range: range))
    }

    private func applyPreset(_ prepared: Prepared) {
        guard !userAdjusted, let preset else { return }
        logical = presetLogicalRange(times: prepared.times, preset: preset)
        crosshair = nil
        if !chrome.sticky { selection?.wrappedValue = nil }
    }

    private func publishSelection(_ index: Int, prepared: Prepared, range: LogicalRange) {
        guard let report = selectionReport(times: prepared.times, index: index, values: hits(prepared, index: index)) else { return }
        crosshair = index
        onPointClick?(report.time, hits(prepared, index: index))
        var values: [SeriesID: Double] = [:]
        for pair in hits(prepared, index: index) { values[SeriesID(pair.0)] = pair.1 }
        selection?.wrappedValue = ChartSelection(time: Date(timeIntervalSince1970: TimeInterval(report.time)), values: values, index: index)
        _ = range
    }

    private func clearSelection() {
        crosshair = nil
        if !chrome.sticky { selection?.wrappedValue = nil }
    }

    private func steppedIndex(_ delta: Int, _ prepared: Prepared) -> Int? {
        let count = prepared.times.count
        guard count > 0 else { return nil }
        return min(max((crosshair ?? count - 1) + delta, 0), count - 1)
    }

    private func moveCrosshair(_ delta: Int, _ prepared: Prepared, range: LogicalRange) {
        guard let index = steppedIndex(delta, prepared) else { return }
        publishSelection(index, prepared: prepared, range: range)
    }

    private func timeText(_ time: Int) -> String {
        if let categories, let label = ordinalLabel(time, categories: categories).nilIfEmpty { return label }
        return formatTime?(time) ?? defaultTimeLabel(unix: time, timeVisible: timeVisible)
    }

    private func valueText(_ id: String, _ value: Double) -> String {
        formatValue?(id, value) ?? formatChartNumber(value)
    }

    @ViewBuilder private func tooltip(_ prepared: Prepared, plot: CGRect, range: LogicalRange) -> some View {
        if showsTooltip, let crosshair, prepared.times.indices.contains(crosshair) {
            let time = prepared.times[crosshair]
            let anchor = xPos(Double(crosshair), plot: plot, range: range)
            TooltipBox(title: timeText(time), rows: prepared.series.compactMap { item in
                guard item.tooltip, let row = item.rows.first(where: { $0.time == time }) else { return nil }
                return (item.name, valueText(item.id, row.close), chartColor(item.color))
            }, theme: theme)
            .fixedSize()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: TooltipWidthKey.self, value: proxy.size.width)
            })
            .offset(x: clampedTooltipOrigin(anchor: anchor, width: tooltipWidth, plotMin: plot.minX, plotMax: plot.maxX), y: 8)
            .onPreferenceChange(TooltipWidthKey.self) { tooltipWidth = $0 }
        }
    }

    private func drawTimeLabels(_ context: GraphicsContext, prepared: Prepared, plot: CGRect, range: LogicalRange) {
        guard let span = visibleBarSpan(count: prepared.times.count, range: range) else { return }
        let font = chartFont(theme.axis, mono: true)
        let ink = chartColor(theme.palette.text)
        if let categories {
            for index in visibleCategoryLabels(visible: span) {
                let time = prepared.times[index]
                let text = ordinalLabel(time, categories: categories).nilIfEmpty ?? timeText(time)
                context.draw(Text(text).font(font).foregroundStyle(ink), at: CGPoint(x: xPos(Double(index), plot: plot, range: range), y: plot.maxY + 14))
            }
            return
        }
        for label in timeAxisLabels(times: prepared.times, visible: span, calendar: .current) {
            let text = formatTime?(label.unix) ?? label.text
            context.draw(Text(text).font(font).foregroundStyle(ink), at: CGPoint(x: xPos(Double(label.index), plot: plot, range: range), y: plot.maxY + 14))
        }
    }

    private func drawExtremes(_ context: GraphicsContext, prepared: Prepared, plot: CGRect, range: LogicalRange) {
        guard let span = visibleBarSpan(count: prepared.times.count, range: range), let item = prepared.series.first else { return }
        let rows = item.rows.filter { row in
            guard let index = prepared.times.firstIndex(of: row.time) else { return false }
            return span.contains(index)
        }
        guard let high = rows.max(by: { $0.high < $1.high }), let low = rows.min(by: { $0.low < $1.low }),
              let highIndex = prepared.times.firstIndex(of: high.time),
              let lowIndex = prepared.times.firstIndex(of: low.time) else { return }
        let domain = domain(item.scale, prepared, range)
        let ink = chartColor(theme.palette.text)
        let font = chartFont(theme.axis, mono: true)
        let highPoint = CGPoint(x: xPos(Double(highIndex), plot: plot, range: range), y: yPos(high.high, domain: domain, plot: plot))
        let lowPoint = CGPoint(x: xPos(Double(lowIndex), plot: plot, range: range), y: yPos(low.low, domain: domain, plot: plot))
        context.draw(Text("\(valueText(item.id, high.high)) \(timeText(high.time))").font(font).foregroundStyle(ink), at: CGPoint(x: min(max(highPoint.x, plot.minX + 36), plot.maxX - 36), y: max(plot.minY + 10, highPoint.y - 12)))
        context.draw(Text("\(valueText(item.id, low.low)) \(timeText(low.time))").font(font).foregroundStyle(ink), at: CGPoint(x: min(max(lowPoint.x, plot.minX + 36), plot.maxX - 36), y: min(plot.maxY - 10, lowPoint.y + 12)))
    }

    @ViewBuilder private func stateLabel(_ presentation: ChartStatePresentation) -> some View {
        if presentation.showsMessage, let message = presentation.message {
            Text(message)
                .font(chartFont(theme.axis, mono: true))
                .foregroundStyle(chartColor(theme.palette.text))
                .padding(8)
                .accessibilityLabel(presentation.accessibility ?? message)
        } else if let accessibility = presentation.accessibility {
            Color.clear.frame(width: 0, height: 0).accessibilityLabel(accessibility)
        }
    }

    private func readout(_ prepared: Prepared, range: LogicalRange) -> String {
        guard let crosshair, prepared.times.indices.contains(crosshair) else { return accessSummary }
        let time = prepared.times[crosshair]
        guard let item = prepared.series.first, let row = item.rows.first(where: { $0.time == time }) else { return timeText(time) }
        let previous = item.rows.last(where: { $0.time < time })?.close
        let delta = previous.map { row.close - $0 }
        return scrubReadout(time: timeText(time), value: valueText(item.id, row.close), delta: delta) { valueText(item.id, $0) }
    }

    private func landmarks(_ prepared: Prepared, range: LogicalRange) -> [ChartLandmark] {
        guard let span = visibleBarSpan(count: prepared.times.count, range: range), let rows = prepared.series.first?.rows else { return [] }
        let window = rows.filter { row in
            guard let index = prepared.times.firstIndex(of: row.time) else { return false }
            return span.contains(index)
        }
        let markerMarks: [(index: Int, label: String)] = markers.compactMap { marker in
            guard let time = seriesTime(marker.time, categories: categories), let index = prepared.times.firstIndex(of: time), span.contains(index) else { return nil }
            return (index, marker.text ?? "Marker \(timeText(time))")
        }
        return seriesLandmarks(rows: window, formatValue: { valueText(prepared.series.first?.id ?? "", $0) }, formatTime: timeText, markers: markerMarks)
    }

    private func refreshAccess(_ prepared: Prepared, range: LogicalRange, state: ChartState) {
        let resolved = resolveChartState(state, hasRows: !prepared.times.isEmpty)
        let presentation = chartStatePresentation(resolved) { date in
            formatAxisDate(Int(date.timeIntervalSince1970), calendar: .current, step: .hour)
        }
        if let summary = summarySentence(prepared, range: range, state: resolved) {
            accessSummary = summary
        } else {
            accessSummary = presentation.accessibility ?? ariaLabel
        }
        let span = visibleBarSpan(count: prepared.times.count, range: range)
        accessSamples = seriesWindowSamples(
            series: prepared.series.map { (id: $0.id, name: $0.name, continuous: $0.kind == .line || $0.kind == .area || $0.kind == .baseline, candle: $0.kind == .candle, rows: $0.rows) },
            times: prepared.times,
            visible: span,
            ribbons: ribbons.map { (name: $0.color ?? "Band", upper: ribbonRows($0, upper: true), lower: ribbonRows($0, upper: false)) },
            formatValue: valueText,
            formatTime: timeText
        )
    }

    private func ribbonRows(_ ribbon: DrawnRibbon, upper: Bool) -> [PlotRow] {
        ribbon.samples.map { sample in
            let value = upper ? sample.upper : sample.lower
            return PlotRow(time: sample.time, open: value, high: value, low: value, close: value)
        }
    }

    private func summarySentence(_ prepared: Prepared, range: LogicalRange, state: ChartState) -> String? {
        if case .summary(let text) = chartAccessibility { return text }
        guard let rows = prepared.series.first?.rows, let span = visibleBarSpan(count: prepared.times.count, range: range) else { return nil }
        let window = rows.filter { row in
            guard let index = prepared.times.firstIndex(of: row.time) else { return false }
            return span.contains(index)
        }
        guard let first = window.first, let last = window.last else { return nil }
        let high = window.max { $0.high < $1.high } ?? first
        let low = window.min { $0.low < $1.low } ?? first
        let asOf: Date?
        if case .stale(let date) = state { asOf = date } else { asOf = nil }
        return ChartSummary.make(
            open: first.open, close: last.close, high: high.high, low: low.low,
            highOn: Date(timeIntervalSince1970: TimeInterval(high.time)),
            lowOn: Date(timeIntervalSince1970: TimeInterval(low.time)),
            from: Date(timeIntervalSince1970: TimeInterval(first.time)),
            to: Date(timeIntervalSince1970: TimeInterval(last.time)),
            change: percent(from: first.open, to: last.close),
            asOf: asOf,
            formatValue: { valueText(prepared.series.first?.id ?? "", $0) },
            formatDate: { formatAxisDate(Int($0.timeIntervalSince1970), calendar: .current, step: .day) }
        )
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

private struct TooltipWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct SeriesDrag<Pan: Gesture, Scrub: Gesture>: ViewModifier {
    var pan: Bool
    var scrubs: Bool
    var drag: Pan
    var scrub: Scrub

    @ViewBuilder func body(content: Content) -> some View {
        if pan {
            content.gesture(drag)
        } else if scrubs {
            content.simultaneousGesture(scrub)
        } else {
            content
        }
    }
}

private struct SeriesZoomAccess: ViewModifier {
    var enabled: Bool
    var action: (AccessibilityZoomGestureAction) -> Void

    @ViewBuilder func body(content: Content) -> some View {
        if enabled {
            content.accessibilityZoomAction(action)
        } else {
            content
        }
    }
}

struct Prepared {
    var series: [DrawnSeries]
    var times: [Int]
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
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
    public var markers: [TimeSeriesMarker]
    public var chrome: ChartChrome
    public var onPointClick: ((Int, [(String, Double)]) -> Void)?
    public var onRangeSelect: ((VisibleStats) -> Void)?
    public var onReset: (() -> Void)?
    public var onVisibleStats: ((VisibleStats?) -> Void)?
    public var selection: Binding<ChartSelection?>?
    public var state: ChartState

    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [LinePoint], variant: LineVariant = .line, bands: [BandItem] = [], bandStyles: [String: BandStyleInput] = [:], overlays: [[LinePoint]] = [], range: RangePreset? = nil, anchor: ChartTime? = nil, logScale: Bool = false, height: CGFloat = 340, ariaLabel: String = "Line chart", theme: ChartTheme? = nil, baseValue: Double = 0, markers: [TimeSeriesMarker] = [], chrome: ChartChrome = .terminal, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil, onReset: (() -> Void)? = nil, onVisibleStats: ((VisibleStats?) -> Void)? = nil, selection: Binding<ChartSelection?>? = nil, state: ChartState = .ready) {
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
        self.markers = markers
        self.chrome = chrome
        self.onPointClick = onPointClick
        self.onRangeSelect = onRangeSelect
        self.onReset = onReset
        self.onVisibleStats = onVisibleStats
        self.selection = selection
        self.state = state
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        SeriesPlot(series: lineSeries(theme), bands: bands, bandStyles: bandStyles, ribbons: [], guides: [], ranges: [], markers: markers, chrome: SeriesChrome(chrome), logScale: logScale, preset: preset, anchor: anchor, histogramMode: .plain, threshold: nil, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: onPointClick, onRangeSelect: onRangeSelect, onReset: onReset, onVisibleStats: onVisibleStats, selection: selection, chartState: state)
    }

    private func lineSeries(_ theme: ChartTheme) -> [DrawnSeries] {
        let kind: SeriesKind = variant == .area ? .area : variant == .baseline ? .baseline : .line
        var drawn = [drawnSeries(id: "series", name: "Series", kind: kind, rows: normalizePoints(data), color: theme.line.color ?? theme.palette.down, theme: theme, base: baseValue)]
        if variant == .baseline {
            drawn[0].areaTop = theme.line.baselineTopFill ?? drawn[0].areaTop
            drawn[0].areaBottom = theme.line.baselineBottomFill ?? drawn[0].areaBottom
        }
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
    public var chrome: ChartChrome
    public var onPointClick: ((Int, [(String, Double)]) -> Void)?
    public var onRangeSelect: ((VisibleStats) -> Void)?
    public var onReset: (() -> Void)?
    public var onVisibleStats: ((VisibleStats?) -> Void)?
    public var selection: Binding<ChartSelection?>?
    public var state: ChartState
    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [LinePoint], base: Double = 0, upColor: String = "#26a69a", downColor: String = "#ef5350", bands: [BandItem] = [], range: RangePreset? = nil, height: CGFloat = 340, ariaLabel: String = "Bar chart", theme: ChartTheme? = nil, chrome: ChartChrome = .terminal, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil, onReset: (() -> Void)? = nil, onVisibleStats: ((VisibleStats?) -> Void)? = nil, selection: Binding<ChartSelection?>? = nil, state: ChartState = .ready) {
        self.data = data
        self.base = base
        self.upColor = upColor
        self.downColor = downColor
        self.bands = bands
        self.preset = range
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.chrome = chrome
        self.onPointClick = onPointClick
        self.onRangeSelect = onRangeSelect
        self.onReset = onReset
        self.onVisibleStats = onVisibleStats
        self.selection = selection
        self.state = state
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        SeriesPlot(series: [barSeries(theme)], bands: bands, bandStyles: [:], ribbons: [], guides: [], ranges: [], markers: [], chrome: SeriesChrome(chrome), logScale: false, preset: preset, anchor: nil, histogramMode: .plain, threshold: nil, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: onPointClick, onRangeSelect: onRangeSelect, onReset: onReset, onVisibleStats: onVisibleStats, selection: selection, chartState: state)
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
    public var now: ChartTime?
    public var height: CGFloat
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var chrome: ChartChrome
    public var onPointClick: ((Int, [(String, Double)]) -> Void)?
    public var onRangeSelect: ((VisibleStats) -> Void)?
    public var onReset: (() -> Void)?
    public var onVisibleStats: ((VisibleStats?) -> Void)?
    public var selection: Binding<ChartSelection?>?
    public var state: ChartState
    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [LinePoint], mode: HistogramMode = .plain, threshold: Double? = nil, now: ChartTime? = nil, height: CGFloat = 340, ariaLabel: String = "Histogram", theme: ChartTheme? = nil, chrome: ChartChrome = .terminal, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil, onReset: (() -> Void)? = nil, onVisibleStats: ((VisibleStats?) -> Void)? = nil, selection: Binding<ChartSelection?>? = nil, state: ChartState = .ready) {
        self.data = data
        self.mode = mode
        self.threshold = threshold
        self.now = now
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.chrome = chrome
        self.onPointClick = onPointClick
        self.onRangeSelect = onRangeSelect
        self.onReset = onReset
        self.onVisibleStats = onVisibleStats
        self.selection = selection
        self.state = state
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let color = theme.histogram.bar ?? theme.palette.neutral
        let item = drawnSeries(id: "histogram", name: "Histogram", kind: .histogram, rows: normalizePoints(data), color: color, theme: theme, base: 0)
        SeriesPlot(series: [item], bands: [], bandStyles: [:], ribbons: [], guides: threshold.map { [TimeSeriesGuide(id: "threshold", value: $0, scale: .right)] } ?? [], ranges: [], markers: [], chrome: SeriesChrome(chrome), logScale: false, preset: nil, anchor: nil, now: now, histogramMode: mode, threshold: threshold, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: onPointClick, onRangeSelect: onRangeSelect, onReset: onReset, onVisibleStats: onVisibleStats, selection: selection, chartState: state)
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
    public var chrome: ChartChrome
    public var onPointClick: ((Int, [(String, Double)]) -> Void)?
    public var onRangeSelect: ((VisibleStats) -> Void)?
    public var onReset: (() -> Void)?
    public var onVisibleStats: ((VisibleStats?) -> Void)?
    public var selection: Binding<ChartSelection?>?
    public var state: ChartState
    @Environment(\.chartTheme) private var environmentTheme

    public init(data: [OHLC], coloring: CandlestickColoring = .direction, bands: [BandItem] = [], range: RangePreset? = nil, height: CGFloat = 340, ariaLabel: String = "Candlestick chart", theme: ChartTheme? = nil, chrome: ChartChrome = .terminal, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil, onReset: (() -> Void)? = nil, onVisibleStats: ((VisibleStats?) -> Void)? = nil, selection: Binding<ChartSelection?>? = nil, state: ChartState = .ready) {
        self.data = data
        self.coloring = coloring
        self.bands = bands
        self.preset = range
        self.height = height
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.chrome = chrome
        self.onPointClick = onPointClick
        self.onRangeSelect = onRangeSelect
        self.onReset = onReset
        self.onVisibleStats = onVisibleStats
        self.selection = selection
        self.state = state
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        SeriesPlot(series: [candleSeries(theme)], bands: bands, bandStyles: [:], ribbons: [], guides: [], ranges: [], markers: [], chrome: SeriesChrome(chrome), logScale: false, preset: preset, anchor: nil, histogramMode: .plain, threshold: nil, coloring: coloring, height: height, ariaLabel: ariaLabel, categories: nil, timeVisible: false, theme: theme, formatTime: nil, formatValue: nil, onPointClick: onPointClick, onRangeSelect: onRangeSelect, onReset: onReset, onVisibleStats: onVisibleStats, selection: selection, chartState: state)
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
    public var onRangeSelect: ((VisibleStats) -> Void)?
    public var onReset: (() -> Void)?
    public var onVisibleStats: ((VisibleStats?) -> Void)?
    public var selection: Binding<ChartSelection?>?
    public var state: ChartState
    @Environment(\.chartTheme) private var environmentTheme

    public init(series: [TimeSeriesSpec], ribbons: [TimeSeriesRibbon] = [], ranges: [TimeSeriesRange] = [], guides: [TimeSeriesGuide] = [], markers: [TimeSeriesMarker] = [], profile: TimeSeriesProfile = .editorial, axis: TimeSeriesAxis = .time, categories: [String] = [], height: CGFloat = 340, timeVisible: Bool = false, ariaLabel: String = "Time series chart", theme: ChartTheme? = nil, formatTime: ((Int) -> String)? = nil, formatValue: ((String, Double) -> String)? = nil, onPointClick: ((Int, [(String, Double)]) -> Void)? = nil, onRangeSelect: ((VisibleStats) -> Void)? = nil, onReset: (() -> Void)? = nil, onVisibleStats: ((VisibleStats?) -> Void)? = nil, selection: Binding<ChartSelection?>? = nil, state: ChartState = .ready) {
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
        self.onRangeSelect = onRangeSelect
        self.onReset = onReset
        self.onVisibleStats = onVisibleStats
        self.selection = selection
        self.state = state
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
        let drawnRibbons = ribbons.map { ribbon in
            DrawnRibbon(samples: ribbonSamples(upper: ribbon.upper, lower: ribbon.lower, categories: labels), color: ribbon.color, opacity: ribbon.opacity, scale: ribbon.priceScale)
        }
        let scrub: ScrubStyle = profile == .terminal ? .ruleDotAndTooltip : .ruleAndDot
        SeriesPlot(series: drawn, bands: [], bandStyles: [:], ribbons: drawnRibbons, guides: guides, ranges: ranges, markers: markers, chrome: SeriesChrome(zoom: profile == .terminal, pan: profile == .terminal, magnet: profile == .terminal, flash: false, followLive: false, rangeSelect: profile == .terminal, doubleTapReset: profile == .terminal, autoBucket: false, liveButton: false, profile: profile, scrub: scrub), logScale: false, preset: nil, anchor: nil, histogramMode: .plain, threshold: nil, coloring: .direction, height: height, ariaLabel: ariaLabel, categories: labels, timeVisible: timeVisible, theme: theme, formatTime: formatTime, formatValue: formatValue, onPointClick: onPointClick, onRangeSelect: onRangeSelect, onReset: onReset, onVisibleStats: onVisibleStats, selection: selection, chartState: state)
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
        let still = ChartChrome(zoom: false, pan: false, magnet: false, flash: false, followLive: false, rangeSelect: false, doubleTapReset: false, liveButton: false, axes: true, tooltip: false, scrub: .none)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(panes) { pane in
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading) {
                        Text(pane.title).font(chartFont(theme.panesTitle, mono: false))
                        if let meta = pane.meta { Text(meta).font(chartFont(theme.panesMeta, mono: true)) }
                    }
                    .frame(width: 120, alignment: .leading)
                    HistogramChart(data: pane.data, mode: pane.mode, threshold: pane.threshold, now: now, height: pane.height, theme: theme, chrome: still)
                }
                .padding(.vertical, 4)
            }
            if let axisLabel { Text(axisLabel).font(chartFont(theme.axis, mono: true)).padding(.top, 4) }
        }
        .accessibilityLabel(ariaLabel)
        .onTapGesture { onSelect?(times.last ?? 0, panes.map { $0.data.last?.value }) }
        .background(chartColor(theme.palette.background))
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
