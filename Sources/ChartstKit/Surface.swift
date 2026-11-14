import Accessibility
import SwiftUI

public enum ScrubStyle: String, Equatable, Sendable {
    case none
    case rule
    case ruleAndDot
    case ruleDotAndTooltip
}

public struct SeriesID: Hashable, Sendable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue }

    public init(stringLiteral value: String) { self.rawValue = value }
}

public struct ChartSelection: Equatable, Sendable {
    public var time: Date
    public var values: [SeriesID: Double]
    public var index: Int

    public init(time: Date, values: [SeriesID: Double], index: Int) {
        self.time = time
        self.values = values
        self.index = index
    }
}

public enum ChartState: Equatable, Sendable {
    case ready
    case loading
    case empty(reason: String)
    case stale(asOf: Date)
    case closed(at: Date, nextOpen: Date?)
    case partial(through: Date)
    case failed(reason: String)
}

public enum ChartAccessibility: Equatable, Sendable {
    case automatic
    case summary(String)
    case hidden
}

private struct ChartAccessibilityKey: EnvironmentKey {
    static let defaultValue = ChartAccessibility.automatic
}

extension EnvironmentValues {
    public var chartAccessibility: ChartAccessibility {
        get { self[ChartAccessibilityKey.self] }
        set { self[ChartAccessibilityKey.self] = newValue }
    }
}

extension View {
    /// `.automatic` builds the summary. `.summary` replaces that sentence. `.hidden` is for a decorative chart.
    public func chartAccessibility(_ mode: ChartAccessibility) -> some View {
        environment(\.chartAccessibility, mode)
    }
}

public struct ResolvedAreaFill: Equatable, Sendable {
    public var top: RGBA
    public var bottom: RGBA

    public init(top: RGBA, bottom: RGBA) {
        self.top = top
        self.bottom = bottom
    }
}

/// An explicit `areaTop` or `areaBottom` is used as given. A missing top uses the line colour at `opacity`. A missing bottom fades to clear.
public func resolveAreaFill(areaTop: String?, areaBottom: String?, line: String, opacity: Double) -> ResolvedAreaFill {
    let lineColor = parseColor(line) ?? RGBA(r: 0, g: 0, b: 0, a: 1)
    let top: RGBA
    if let areaTop, let parsed = parseColor(areaTop) {
        top = parsed
    } else {
        top = RGBA(r: lineColor.r, g: lineColor.g, b: lineColor.b, a: opacity)
    }
    let bottom: RGBA
    if let areaBottom, let parsed = parseColor(areaBottom) {
        bottom = parsed
    } else {
        bottom = RGBA(r: top.r, g: top.g, b: top.b, a: 0)
    }
    return ResolvedAreaFill(top: top, bottom: bottom)
}

public struct AxisTick: Equatable, Sendable {
    public var value: Double
    public var label: String

    public init(value: Double, label: String) {
        self.value = value
        self.label = label
    }
}

func niceNumberStep(span: Double, count: Int) -> Double {
    guard span > 0, span.isFinite, count > 0 else { return 1 }
    let rough = span / Double(count)
    guard rough > 0, rough.isFinite else { return 1 }
    let power = pow(10, floor(log10(rough)))
    let error = rough / power
    let nice: Double
    if error <= 1 { nice = 1 }
    else if error <= 2 { nice = 2 }
    else if error <= 2.5 { nice = 2.5 }
    else if error <= 5 { nice = 5 }
    else { nice = 10 }
    return nice * power
}

public func niceAxisTicks(min minValue: Double, max maxValue: Double, count: Int = 4, locale: Locale = .current) -> [AxisTick] {
    guard minValue.isFinite, maxValue.isFinite else { return [] }
    guard maxValue > minValue, count >= 1 else {
        return labelledAxisTicks([minValue], locale: locale)
    }
    let step = niceNumberStep(span: maxValue - minValue, count: count)
    guard step > 0, step.isFinite else { return labelledAxisTicks([minValue, maxValue], locale: locale) }
    var value = ceil((minValue - step * 1e-8) / step) * step
    var numbers: [Double] = []
    var guardrail = 0
    while value <= maxValue + step * 1e-6, guardrail < 24 {
        let snapped = (value / step).rounded() * step
        numbers.append(snapped)
        value += step
        guardrail += 1
    }
    if numbers.isEmpty { numbers = [minValue, maxValue] }
    return labelledAxisTicks(numbers, locale: locale)
}

func labelledAxisTicks(_ values: [Double], locale: Locale) -> [AxisTick] {
    let finite = values.filter(\.isFinite)
    guard !finite.isEmpty else { return [] }
    for digits in 0...8 {
        let labels = finite.map { formatTick($0, fractionDigits: digits, locale: locale) }
        if Set(labels).count == labels.count {
            return zip(finite, labels).map { AxisTick(value: $0.0, label: $0.1) }
        }
    }
    var seen = Set<String>()
    var kept: [AxisTick] = []
    for value in finite {
        let label = formatTick(value, fractionDigits: 8, locale: locale)
        if seen.insert(label).inserted {
            kept.append(AxisTick(value: value, label: label))
        }
    }
    return kept
}

func formatTick(_ value: Double, fractionDigits: Int, locale: Locale) -> String {
    value.formatted(.number.precision(.fractionLength(0...fractionDigits)).locale(locale))
}

public struct TimeAxisLabel: Equatable, Sendable {
    public var index: Int
    public var unix: Int
    public var text: String

    public init(index: Int, unix: Int, text: String) {
        self.index = index
        self.unix = unix
        self.text = text
    }
}

enum AxisStep: Equatable { case hour, day, week, month, year }

func axisStep(span: Int) -> AxisStep {
    if span <= 36 * 3600 { return .hour }
    if span <= 21 * 86_400 { return .day }
    if span <= 120 * 86_400 { return .week }
    if span <= 800 * 86_400 { return .month }
    return .year
}

public func timeAxisLabels(times: [Int], visible: ClosedRange<Int>, calendar: Calendar, limit: Int = 4) -> [TimeAxisLabel] {
    guard !times.isEmpty, visible.lowerBound >= 0, visible.upperBound < times.count, visible.lowerBound <= visible.upperBound else { return [] }
    let start = times[visible.lowerBound]
    let end = times[visible.upperBound]
    let step = axisStep(span: max(0, end - start))
    if start == end {
        return [TimeAxisLabel(index: visible.lowerBound, unix: start, text: formatAxisDate(start, calendar: calendar, step: step))]
    }
    let boundaries = calendarBoundaries(from: start, to: end, step: step, calendar: calendar)
    var labels: [TimeAxisLabel] = []
    var used = Set<Int>()
    for boundary in boundaries {
        guard let index = nearestVisibleIndex(times: times, visible: visible, unix: boundary), used.insert(index).inserted else { continue }
        labels.append(TimeAxisLabel(index: index, unix: times[index], text: formatAxisDate(times[index], calendar: calendar, step: step)))
    }
    if labels.isEmpty {
        labels = [TimeAxisLabel(index: visible.lowerBound, unix: start, text: formatAxisDate(start, calendar: calendar, step: step))]
    }
    return thinLabels(labels, limit: max(1, limit))
}

func visibleCategoryLabels(visible: ClosedRange<Int>, limit: Int = 4) -> [Int] {
    guard visible.lowerBound <= visible.upperBound else { return [] }
    let count = visible.count
    let cap = max(1, limit)
    if count <= cap { return Array(visible) }
    return (0..<cap).map { step in
        let t = Double(step) / Double(cap - 1)
        return visible.lowerBound + Int((t * Double(count - 1)).rounded())
    }
}

private func nearestVisibleIndex(times: [Int], visible: ClosedRange<Int>, unix: Int) -> Int? {
    var best: Int?
    var distance = Int.max
    for index in visible {
        let gap = abs(times[index] - unix)
        if gap < distance {
            distance = gap
            best = index
        }
    }
    return best
}

private func calendarBoundaries(from start: Int, to end: Int, step: AxisStep, calendar: Calendar) -> [Int] {
    let startDate = Date(timeIntervalSince1970: TimeInterval(start))
    let component: Calendar.Component
    switch step {
    case .hour: component = .hour
    case .day: component = .day
    case .week: component = .weekOfYear
    case .month: component = .month
    case .year: component = .year
    }
    var cursor = calendar.dateInterval(of: component, for: startDate)?.start ?? startDate
    var marks: [Int] = []
    var guardrail = 0
    while guardrail < 400 {
        let unix = Int(cursor.timeIntervalSince1970)
        if unix > end { break }
        if unix >= start { marks.append(unix) }
        guard let next = calendar.date(byAdding: component, value: 1, to: cursor), next > cursor else { break }
        cursor = next
        guardrail += 1
    }
    return marks
}

func formatAxisDate(_ unix: Int, calendar: Calendar, step: AxisStep) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_GB")
    switch step {
    case .hour: formatter.dateFormat = "d MMM HH:mm"
    case .day, .week: formatter.dateFormat = "d MMM"
    case .month: formatter.dateFormat = "MMM yyyy"
    case .year: formatter.dateFormat = "yyyy"
    }
    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(unix)))
}

private func thinLabels(_ labels: [TimeAxisLabel], limit: Int) -> [TimeAxisLabel] {
    guard labels.count > limit, limit > 1 else { return labels }
    return (0..<limit).map { step in
        let index = Int((Double(step) / Double(limit - 1) * Double(labels.count - 1)).rounded())
        return labels[index]
    }
}

public func logicalIndex(atX x: Double, plotMinX: Double, plotWidth: Double, range: LogicalRange) -> Double {
    let span = range.span == 0 ? 1 : range.span
    let width = plotWidth == 0 ? 1 : plotWidth
    return range.from + ((x - plotMinX) / width) * span
}

public func presetLogicalRange(times: [Int], preset: RangePreset) -> LogicalRange? {
    guard let first = times.first, let last = times.last else { return nil }
    guard let window = presetRange(first: first, last: last, preset: preset) else { return nil }
    guard let start = times.firstIndex(where: { $0 >= window.from }),
          let end = times.lastIndex(where: { $0 <= window.to }),
          start <= end else { return nil }
    return LogicalRange(from: Double(start) - halfBar, to: Double(end) + halfBar)
}

/// A preset stays on its window while live data arrives. Follow-live slides that window. A user pan is left alone. Without a preset, follow-live fits every bar.
public func logicalRangeAfterUpdate(preset: RangePreset?, times: [Int], followLive: Bool, userAdjusted: Bool, current: LogicalRange?) -> LogicalRange? {
    if userAdjusted { return current }
    if let preset {
        guard followLive else { return current }
        return presetLogicalRange(times: times, preset: preset)
    }
    if followLive { return nil }
    return current
}

struct SelectionReport: Equatable {
    var time: Int
    var values: [String: Double]
}

func selectionReport(times: [Int], index: Int, values: [(String, Double)] = []) -> SelectionReport? {
    guard times.indices.contains(index) else { return nil }
    return SelectionReport(time: times[index], values: Dictionary(uniqueKeysWithValues: values))
}

func clampedTooltipOrigin(anchor: CGFloat, width: CGFloat, plotMin: CGFloat, plotMax: CGFloat) -> CGFloat {
    let gap: CGFloat = 8
    var origin = anchor + gap
    if origin + width > plotMax { origin = anchor - gap - width }
    let room = max(plotMin, plotMax - width)
    return min(max(origin, plotMin), room)
}

func chartMotion(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : .easeOut(duration: 0.25)
}

public enum ChartSummary {
    public static func make(
        open: Double,
        close: Double,
        high: Double,
        low: Double,
        highOn: Date,
        lowOn: Date,
        from: Date,
        to: Date,
        change: Double?,
        asOf: Date? = nil,
        formatValue: (Double) -> String,
        formatDate: (Date) -> String
    ) -> String {
        let direction: String
        if let change {
            if change > 0 { direction = "Up" }
            else if change < 0 { direction = "Down" }
            else { direction = "Unchanged" }
        } else {
            direction = "Unchanged"
        }
        let amount = formatValue(abs(close - open))
        let percentText: String
        if let change {
            percentText = String(format: "%.1f%%", change)
        } else {
            percentText = "0%"
        }
        var sentence = "\(direction) \(amount) (\(percentText)) over \(formatDate(from)) to \(formatDate(to)); high \(formatValue(high)) on \(formatDate(highOn)); low \(formatValue(low)) on \(formatDate(lowOn))."
        if let asOf {
            sentence += " As of \(formatDate(asOf))."
        }
        return sentence
    }
}

func resolveChartState(_ state: ChartState, hasRows: Bool) -> ChartState {
    if case .ready = state, !hasRows {
        return .empty(reason: "No data for this range yet.")
    }
    return state
}

func chartStateDrawsSeries(_ state: ChartState) -> Bool {
    switch state {
    case .loading, .empty, .failed: return false
    case .ready, .stale, .closed, .partial: return true
    }
}

struct ChartStatePresentation: Equatable {
    var message: String?
    var accessibility: String?
    var showsMessage: Bool
}

func chartStatePresentation(_ state: ChartState, formatTime: (Date) -> String) -> ChartStatePresentation {
    switch state {
    case .ready:
        return ChartStatePresentation(message: nil, accessibility: nil, showsMessage: false)
    case .loading:
        return ChartStatePresentation(message: nil, accessibility: "Loading chart", showsMessage: false)
    case .empty(let reason):
        let text = reason.isEmpty ? "No data for this range yet." : reason
        return ChartStatePresentation(message: text, accessibility: text, showsMessage: true)
    case .stale(let asOf):
        let text = "As of \(formatTime(asOf))"
        return ChartStatePresentation(message: text, accessibility: text, showsMessage: true)
    case .closed(let at, let next):
        let text = next.map { "At close \(formatTime(at)) · Opens \(formatTime($0))" } ?? "At close \(formatTime(at))"
        return ChartStatePresentation(message: text, accessibility: text, showsMessage: true)
    case .partial(let through):
        let text = "\(formatTime(through)) so far"
        return ChartStatePresentation(message: text, accessibility: text, showsMessage: true)
    case .failed(let reason):
        let text = reason.isEmpty ? "Couldn't load this chart." : reason
        return ChartStatePresentation(message: text, accessibility: text, showsMessage: true)
    }
}

func presetAnnouncement(_ preset: RangePreset, from: Date?, to: Date?, formatDate: (Date) -> String) -> String {
    let name: String
    switch preset {
    case .oneDay: name = "one day"
    case .oneWeek: name = "one week"
    case .oneMonth: name = "one month"
    case .threeMonths: name = "three months"
    case .yearToDate: name = "the year to date"
    case .oneYear: name = "one year"
    case .threeYears: name = "three years"
    case .fiveYears: name = "five years"
    case .all: name = "all"
    }
    if let from, let to {
        return "Showing \(name), \(formatDate(from)) to \(formatDate(to))"
    }
    return "Showing \(name)"
}

func scrubReadout(time: String, value: String, delta: Double?, formatDelta: (Double) -> String) -> String {
    guard let delta else { return "\(time), \(value)" }
    if delta > 0 { return "\(time), \(value), up \(formatDelta(abs(delta))) from the previous close" }
    if delta < 0 { return "\(time), \(value), down \(formatDelta(abs(delta))) from the previous close" }
    return "\(time), \(value), unchanged from the previous close"
}

struct ChartLandmark: Equatable, Identifiable {
    var id: String
    var index: Int
    var label: String
}

func seriesLandmarks(
    rows: [PlotRow],
    formatValue: (Double) -> String,
    formatTime: (Int) -> String,
    markers: [(index: Int, label: String)] = [],
    edges: [(index: Int, label: String)] = []
) -> [ChartLandmark] {
    guard let first = rows.first, let last = rows.last else { return [] }
    let high = rows.max { $0.high < $1.high } ?? first
    let low = rows.min { $0.low < $1.low } ?? first
    func index(of row: PlotRow) -> Int { rows.firstIndex(where: { $0.time == row.time }) ?? 0 }
    var marks = [
        ChartLandmark(id: "high", index: index(of: high), label: "High \(formatValue(high.high)) on \(formatTime(high.time))"),
        ChartLandmark(id: "low", index: index(of: low), label: "Low \(formatValue(low.low)) on \(formatTime(low.time))"),
        ChartLandmark(id: "first", index: 0, label: "First \(formatValue(first.close)) on \(formatTime(first.time))"),
        ChartLandmark(id: "last", index: rows.count - 1, label: "Last \(formatValue(last.close)) on \(formatTime(last.time))"),
    ]
    for (offset, marker) in markers.enumerated() {
        marks.append(ChartLandmark(id: "marker-\(offset)", index: marker.index, label: marker.label))
    }
    for (offset, edge) in edges.enumerated() {
        marks.append(ChartLandmark(id: "edge-\(offset)", index: edge.index, label: edge.label))
    }
    return marks
}

struct ChartPointSample: Equatable {
    var x: Double
    var y: Double?
    var category: String?
    var label: String
}

struct ChartSeriesSample: Equatable {
    var name: String
    var continuous: Bool
    var points: [ChartPointSample]
}

func seriesWindowSamples(
    series: [(id: String, name: String, continuous: Bool, candle: Bool, rows: [PlotRow])],
    times: [Int],
    visible: ClosedRange<Int>?,
    ribbons: [(name: String, upper: [PlotRow], lower: [PlotRow])] = [],
    formatValue: (String, Double) -> String,
    formatTime: (Int) -> String
) -> [ChartSeriesSample] {
    let span = visible ?? (times.isEmpty ? nil : 0...(times.count - 1))
    guard let span else { return [] }
    var samples: [ChartSeriesSample] = []
    for item in series {
        let byTime = Dictionary(uniqueKeysWithValues: item.rows.map { ($0.time, $0) })
        var points: [ChartPointSample] = []
        for index in span {
            let time = times[index]
            guard let row = byTime[time] else { continue }
            let label: String
            if item.candle {
                label = "\(formatTime(time)), open \(formatValue(item.id, row.open)), high \(formatValue(item.id, row.high)), low \(formatValue(item.id, row.low)), close \(formatValue(item.id, row.close))"
            } else {
                label = "\(formatTime(time)), \(formatValue(item.id, row.close))"
            }
            points.append(ChartPointSample(x: Double(time), y: row.close, label: label))
        }
        samples.append(ChartSeriesSample(name: item.name, continuous: item.continuous, points: points))
    }
    for ribbon in ribbons {
        let upper = Dictionary(uniqueKeysWithValues: ribbon.upper.map { ($0.time, $0.close) })
        let lower = Dictionary(uniqueKeysWithValues: ribbon.lower.map { ($0.time, $0.close) })
        var highPoints: [ChartPointSample] = []
        var lowPoints: [ChartPointSample] = []
        for index in span {
            let time = times[index]
            if let value = upper[time] {
                highPoints.append(ChartPointSample(x: Double(time), y: value, label: "\(formatTime(time)), \(formatValue(ribbon.name, value))"))
            }
            if let value = lower[time] {
                lowPoints.append(ChartPointSample(x: Double(time), y: value, label: "\(formatTime(time)), \(formatValue(ribbon.name, value))"))
            }
        }
        samples.append(ChartSeriesSample(name: "\(ribbon.name) upper", continuous: true, points: highPoints))
        samples.append(ChartSeriesSample(name: "\(ribbon.name) lower", continuous: true, points: lowPoints))
    }
    return samples
}

func heatmapSeriesSamples(rows: [String], columns: [String], values: [[Double?]], formatValue: (Double) -> String) -> [ChartSeriesSample] {
    rows.enumerated().map { row, name in
        let points = columns.enumerated().map { column, title -> ChartPointSample in
            let value = values.indices.contains(row) && values[row].indices.contains(column) ? values[row][column] : nil
            if let value {
                return ChartPointSample(x: Double(column), y: value, category: title, label: "\(title), \(formatValue(value))")
            }
            return ChartPointSample(x: Double(column), y: nil, category: title, label: "\(title), no data")
        }
        return ChartSeriesSample(name: name, continuous: false, points: points)
    }
}

func pieSeriesSamples(slices: [(label: String, share: Double)]) -> [ChartSeriesSample] {
    let points = slices.map { slice in
        ChartPointSample(x: 0, y: slice.share, category: slice.label, label: "\(slice.label), \(formatShare(slice.share))")
    }
    return [ChartSeriesSample(name: "Share", continuous: false, points: points)]
}

func categoricalSamples(series: [(name: String, values: [Double?])], categories: [String], formatValue: (Double) -> String) -> [ChartSeriesSample] {
    series.map { item in
        let points = categories.enumerated().map { index, category -> ChartPointSample in
            let value = item.values.indices.contains(index) ? item.values[index] : nil
            let label = value.map { "\(category), \(formatValue($0))" } ?? "\(category), no data"
            return ChartPointSample(x: Double(index), y: value, category: category, label: label)
        }
        return ChartSeriesSample(name: item.name, continuous: false, points: points)
    }
}

func sparklineSamples(_ values: [Double?]) -> [ChartSeriesSample] {
    let points = values.enumerated().compactMap { index, value -> ChartPointSample? in
        guard let value else { return nil }
        return ChartPointSample(x: Double(index), y: value, label: formatChartNumber(value))
    }
    return [ChartSeriesSample(name: "Series", continuous: true, points: points)]
}

func makeAccessibleChart(title: String, summary: String?, samples: [ChartSeriesSample], categorical: Bool) -> AXChartDescriptor {
    let ys = samples.flatMap { $0.points.compactMap(\.y) }.filter(\.isFinite)
    let yLower = ys.min() ?? 0
    let yUpper = max(ys.max() ?? 1, yLower + 1)
    let yAxis = AXNumericDataAxisDescriptor(title: "Value", range: yLower...yUpper, gridlinePositions: []) { value in
        nearestLabel(samples, axis: .y, value: value) ?? formatChartNumber(value)
    }
    let xAxis: any AXDataAxisDescriptor
    if categorical {
        var order: [String] = []
        for sample in samples {
            for point in sample.points {
                let name = point.category ?? point.label
                if !order.contains(name) { order.append(name) }
            }
        }
        xAxis = AXCategoricalDataAxisDescriptor(title: "Category", categoryOrder: order.isEmpty ? ["—"] : order)
    } else {
        let xs = samples.flatMap { $0.points.map(\.x) }
        let lower = xs.min() ?? 0
        let upper = max(xs.max() ?? 1, lower + 1)
        xAxis = AXNumericDataAxisDescriptor(title: "Time", range: lower...upper, gridlinePositions: []) { value in
            nearestLabel(samples, axis: .x, value: value) ?? formatChartNumber(value)
        }
    }
    let series = samples.map { sample in
        AXDataSeriesDescriptor(
            name: sample.name,
            isContinuous: sample.continuous,
            dataPoints: sample.points.map { point in
                if categorical, let category = point.category {
                    return AXDataPoint(x: category, y: point.y, label: point.label)
                }
                return AXDataPoint(x: point.x, y: point.y, label: point.label)
            }
        )
    }
    let described = series.isEmpty
        ? [AXDataSeriesDescriptor(name: title, isContinuous: false, dataPoints: [])]
        : series
    return AXChartDescriptor(title: title, summary: summary, xAxis: xAxis, yAxis: yAxis, series: described)
}

private enum SampleAxis { case x, y }

private func nearestLabel(_ samples: [ChartSeriesSample], axis: SampleAxis, value: Double) -> String? {
    let points = samples.flatMap(\.points)
    guard !points.isEmpty else { return nil }
    let nearest = points.min { lhs, rhs in
        let left = axis == .x ? lhs.x : (lhs.y ?? .greatestFiniteMagnitude)
        let right = axis == .x ? rhs.x : (rhs.y ?? .greatestFiniteMagnitude)
        return abs(left - value) < abs(right - value)
    }
    return nearest?.label
}

struct AccessibleChart: AXChartDescriptorRepresentable {
    var title: String
    var summary: String?
    var samples: [ChartSeriesSample]
    var categorical: Bool

    func makeChartDescriptor() -> AXChartDescriptor {
        makeAccessibleChart(title: title, summary: summary, samples: samples, categorical: categorical)
    }
}

extension View {
    @ViewBuilder
    func chartAccess(_ mode: ChartAccessibility, title: String, summary: String?, samples: [ChartSeriesSample], categorical: Bool) -> some View {
        switch mode {
        case .hidden:
            self.accessibilityHidden(true)
        case .summary(let text):
            self.accessibilityLabel(title)
                .accessibilityChartDescriptor(AccessibleChart(title: title, summary: text, samples: samples, categorical: categorical))
        case .automatic:
            self.accessibilityLabel(title)
                .accessibilityChartDescriptor(AccessibleChart(title: title, summary: summary, samples: samples, categorical: categorical))
        }
    }
}
