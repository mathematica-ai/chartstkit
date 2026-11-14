import Foundation

public struct LinePoint: Hashable, Sendable {
    public var time: ChartTime
    public var value: Double
    public var color: String?

    public init(time: ChartTime, value: Double, color: String? = nil) {
        self.time = time
        self.value = value
        self.color = color
    }
}

public struct OHLC: Hashable, Sendable {
    public var time: ChartTime
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var color: String?
    public var borderColor: String?
    public var wickColor: String?

    public init(
        time: ChartTime,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        color: String? = nil,
        borderColor: String? = nil,
        wickColor: String? = nil
    ) {
        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.color = color
        self.borderColor = borderColor
        self.wickColor = wickColor
    }
}

public struct PlotRow: Equatable, Sendable {
    public var time: Int
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var color: String?

    public init(time: Int, open: Double, high: Double, low: Double, close: Double, color: String? = nil) {
        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.color = color
    }
}

public struct VisibleStats: Equatable, Sendable {
    public var from: Int
    public var to: Int
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var change: Double?
    public var bars: Int
}

public struct LogicalRange: Equatable, Sendable {
    public var from: Double
    public var to: Double
    public init(from: Double, to: Double) {
        self.from = from
        self.to = to
    }
    public var span: Double { to - from }
}

public struct Bin: Equatable, Sendable {
    public var from: Double
    public var to: Double
    public var count: Int
    public var label: String
}

public struct BandItem: Hashable, Sendable {
    public var from: ChartTime
    public var to: ChartTime
    public var key: String
    public init(from: ChartTime, to: ChartTime, key: String) {
        self.from = from
        self.to = to
        self.key = key
    }
}

public struct BandStyle: Equatable, Sendable {
    public var fill: String?
    public var label: String?
    public var legendColor: String?
    public var hatch: String?
    public init(fill: String? = nil, label: String? = nil, legendColor: String? = nil, hatch: String? = nil) {
        self.fill = fill
        self.label = label
        self.legendColor = legendColor
        self.hatch = hatch
    }
}

public enum BandStyleInput: Sendable {
    case fill(String)
    case style(BandStyle)
}

public struct BandAtPoint: Equatable, Sendable {
    public var key: String
    public var label: String
    public var from: ChartTime
    public var to: ChartTime
    public var bars: Int
}

public enum HistogramMode: String, Sendable {
    case plain
    case threshold
    case diverging
}

public struct HistogramColors: Equatable, Sendable {
    public var bar: String?
    public var over: String?
    public var positive: String?
    public var negative: String?
    public init(bar: String? = nil, over: String? = nil, positive: String? = nil, negative: String? = nil) {
        self.bar = bar
        self.over = over
        self.positive = positive
        self.negative = negative
    }
}

public enum CandlestickColoring: String, Sendable {
    /// Filled bars. Up and down colours follow the close against the open.
    case direction
    /// Hollow when the bar is up, filled when it is down. Colour follows the close against the previous close.
    case trend
}

public func isUp(_ candle: OHLC) -> Bool { candle.close >= candle.open }

public func buckets<T>(_ items: [T], size: Int) throws -> [[T]] {
    if size <= 0 { throw ChartMathError.bucketSize }
    var result: [[T]] = []
    var index = 0
    while index < items.count {
        let end = min(index + size, items.count)
        result.append(Array(items[index..<end]))
        index = end
    }
    return result
}

public func nextBucketSize(current: Int, pxPerRawBar: Double, minBarWidth: Double, rawCount: Int) -> Int {
    if pxPerRawBar <= 0 || !pxPerRawBar.isFinite { return current }
    var next = current
    if next <= 0 { return current }
    while next < rawCount && pxPerRawBar * Double(next) < minBarWidth { next *= 2 }
    while next > 1 && pxPerRawBar * (Double(next) / 2) >= minBarWidth * 1.5 { next /= 2 }
    return next
}

public func aggregateCandles(_ candles: [OHLC], bucketSize: Int) throws -> [OHLC] {
    try buckets(candles, size: bucketSize).map { slice in
        let ends = highLow(slice.map { (high: $0.high, low: $0.low) })
        return OHLC(
            time: slice[0].time,
            open: slice[0].open,
            high: ends.high,
            low: ends.low,
            close: slice[slice.count - 1].close,
            color: slice[slice.count - 1].color
        )
    }
}

public func aggregatePoints(_ points: [LinePoint], bucketSize: Int) throws -> [LinePoint] {
    try buckets(points, size: bucketSize).map { slice in
        var last = slice[slice.count - 1]
        last.time = slice[0].time
        return last
    }
}

public func toLinePoints(_ candles: [OHLC]) -> [LinePoint] {
    candles.map { LinePoint(time: $0.time, value: $0.close, color: $0.color) }
}

public func normalizePoints(_ input: [LinePoint]) -> [PlotRow] {
    var byTime: [Int: LinePoint] = [:]
    for point in input {
        guard let time = toUnixSeconds(point.time), point.value.isFinite else { continue }
        byTime[time] = point
    }
    return byTime.keys.sorted().compactMap { time in
        guard let point = byTime[time] else { return nil }
        return PlotRow(time: time, open: point.value, high: point.value, low: point.value, close: point.value, color: point.color)
    }
}

public func normalizeCandles(_ input: [OHLC]) -> [PlotRow] {
    var byTime: [Int: OHLC] = [:]
    for candle in input {
        guard let time = toUnixSeconds(candle.time) else { continue }
        guard [candle.open, candle.high, candle.low, candle.close].allSatisfy(\.isFinite) else { continue }
        byTime[time] = candle
    }
    return byTime.keys.sorted().compactMap { time in
        guard let candle = byTime[time] else { return nil }
        return PlotRow(time: time, open: candle.open, high: candle.high, low: candle.low, close: candle.close, color: candle.color)
    }
}

public func indexAtOrBefore(_ times: [Int], time: Int) -> Int? {
    var low = 0
    var high = times.count - 1
    var found: Int? = nil
    while low <= high {
        let mid = (low + high) >> 1
        if times[mid] <= time {
            found = mid
            low = mid + 1
        } else {
            high = mid - 1
        }
    }
    return found
}

public func percent(from: Double, to: Double) -> Double? {
    from != 0 ? ((to - from) / from) * 100 : nil
}

public func highLow(_ rows: [(high: Double, low: Double)]) -> (high: Double, low: Double) {
    var high = rows[0].high
    var low = rows[0].low
    for row in rows {
        if row.high > high { high = row.high }
        if row.low < low { low = row.low }
    }
    return (high, low)
}

public func visibleStats(_ rows: [PlotRow], from: Double, to: Double) -> VisibleStats? {
    guard !rows.isEmpty else { return nil }
    let start = max(0, Int(ceil(from)))
    let end = min(rows.count - 1, Int(floor(to)))
    if start > end { return nil }
    let slice = Array(rows[start...end])
    let ends = highLow(slice.map { (high: $0.high, low: $0.low) })
    return VisibleStats(
        from: rows[start].time,
        to: rows[end].time,
        open: rows[start].open,
        high: ends.high,
        low: ends.low,
        close: rows[end].close,
        change: percent(from: rows[start].open, to: rows[end].close),
        bars: end - start + 1
    )
}

public let halfBar = 0.5
private let zoomSpeed = 0.002
private let minVisibleBars = 2.0

public func zoomRange(_ range: LogicalRange, anchor: Double, delta: Double) -> LogicalRange? {
    let factor = exp(delta * zoomSpeed)
    if !factor.isFinite { return nil }
    let next = LogicalRange(
        from: anchor - (anchor - range.from) * factor,
        to: anchor + (range.to - anchor) * factor
    )
    return next.span < minVisibleBars ? nil : next
}

public func isLive(_ range: LogicalRange?, lastIndex: Int) -> Bool {
    range == nil || lastIndex < 0 || (range!.to >= Double(lastIndex) - halfBar)
}

public enum TickDirection: String, Sendable { case up, down }

public func tickDirection(previous: [PlotRow], next: [PlotRow]) -> TickDirection? {
    guard let before = previous.last, let after = next.last else { return nil }
    let sameBar = next.count == previous.count && after.time == before.time
    let appended = next.count == previous.count + 1 && next.dropLast().last?.time == before.time
    if (!sameBar && !appended) || after.close == before.close { return nil }
    return after.close > before.close ? .up : .down
}

public func bin(
    _ samples: [Double],
    bins: Int? = nil,
    min minValue: Double? = nil,
    max maxValue: Double? = nil,
    edges explicit: [Double]? = nil
) -> [Bin] {
    let values = samples.filter(\.isFinite)
    guard !values.isEmpty, let edges = binEdges(values, bins: bins, min: minValue, max: maxValue, edges: explicit) else {
        return []
    }
    var result: [Bin] = []
    for index in 0..<(edges.count - 1) {
        result.append(Bin(from: edges[index], to: edges[index + 1], count: 0, label: binLabel(edges[index], edges[index + 1])))
    }
    let last = result.count - 1
    for value in values {
        guard let index = result.indices.first(where: { itemIndex in
            let item = result[itemIndex]
            return value >= item.from && (value < item.to || (itemIndex == last && value == item.to))
        }) else { continue }
        result[index].count += 1
    }
    return result
}

public func bandKeys(_ bands: [BandItem]) -> [String] {
    var seen = Set<String>()
    var keys: [String] = []
    for band in bands where seen.insert(band.key).inserted { keys.append(band.key) }
    return keys
}

public struct ResolvedBand: Equatable, Sendable {
    public var key: String
    public var start: Int
    public var end: Int
    public var from: ChartTime
    public var to: ChartTime
}

public func sortBands(_ bands: [BandItem]) -> [ResolvedBand] {
    bands.compactMap { band in
        guard let start = toUnixSeconds(band.from), let end = toUnixSeconds(band.to), end >= start else { return nil }
        return ResolvedBand(key: band.key, start: start, end: end, from: band.from, to: band.to)
    }.sorted { $0.start < $1.start }
}

public func resolveBandStyles(
    keys: [String],
    theme: ChartTheme?,
    bandStyles: [String: BandStyleInput] = [:]
) -> [String: BandStyle] {
    let categorical = theme?.palette.categorical ?? []
    var resolved: [String: BandStyle] = [:]
    for (index, key) in keys.enumerated() {
        let color = categorical.isEmpty ? nil : categorical[index % categorical.count]
        let themed = color.flatMap { withAlpha($0, theme?.bands.opacity ?? 0.15) } ?? color
        var style = BandStyle(fill: themed ?? "rgba(128, 128, 128, 0.15)", label: key)
        if let preset = theme?.bands.styles[key] { style = merging(style, preset) }
        if let own = bandStyles[key] {
            switch own {
            case let .fill(fill): style.fill = fill
            case let .style(extra): style = merging(style, extra)
            }
        }
        resolved[key] = style
    }
    return resolved
}

public func bandAt(_ bands: [BandItem], time: Int, times: [Int], styles: [String: BandStyle] = [:]) -> BandAtPoint? {
    guard let band = sortBands(bands).filter({ $0.start <= time && time < $0.end }).last else { return nil }
    let hovered = indexAtOrBefore(times, time: time)
    let before = indexAtOrBefore(times, time: band.start - 1)
    let bars = hovered == nil ? 0 : hovered! - (before ?? -1)
    return BandAtPoint(
        key: band.key,
        label: styles[band.key]?.label ?? band.key,
        from: band.from,
        to: band.to,
        bars: bars
    )
}

public func colorBars(_ rows: [PlotRow], mode: HistogramMode, threshold: Double?, colors: HistogramColors) -> [PlotRow] {
    rows.map { row in
        if row.color != nil { return row }
        var copy = row
        copy.color = histogramColor(row.close, mode: mode, threshold: threshold, colors: colors)
        return copy
    }
}

public func histogramColor(_ value: Double, mode: HistogramMode, threshold: Double?, colors: HistogramColors) -> String? {
    if mode == .diverging { return value < 0 ? colors.negative : colors.positive }
    if mode == .threshold, let threshold, value > threshold { return colors.over }
    return colors.bar
}

public func hideKeys(_ keys: [String], hidden: [String], key: String, only: Bool = false) -> [String] {
    guard keys.contains(key) else { return hidden }
    let next = only
        ? keys.filter { $0 != key }
        : hidden.contains(key) ? hidden.filter { $0 != key } : hidden + [key]
    if keys.contains(where: { !next.contains($0) }) {
        return keys.filter { next.contains($0) }
    }
    return hidden
}

func jsToPrecision(_ value: Double, precision: Int) -> String {
    if !value.isFinite { return String(value) }
    if value == 0 {
        return precision <= 1 ? "0" : "0." + String(repeating: "0", count: precision - 1)
    }
    let negative = value < 0
    var magnitude = abs(value)
    var exponent = Int(floor(log10(magnitude)))
    var scaled = (magnitude / pow(10, Double(exponent - precision + 1))).rounded()
    if scaled >= pow(10, Double(precision)) {
        scaled /= 10
        exponent += 1
    }
    var digits = String(Int(scaled))
    if digits.count < precision {
        digits = String(repeating: "0", count: precision - digits.count) + digits
    }
    let body: String
    if exponent < -6 || exponent >= precision {
        let head = digits.prefix(1)
        let tail = digits.dropFirst()
        let fraction = tail.isEmpty ? "" : ".\(tail)"
        body = "\(head)\(fraction)e\(exponent >= 0 ? "+" : "")\(exponent)"
    } else if exponent >= 0 {
        if exponent + 1 >= digits.count {
            body = digits + String(repeating: "0", count: exponent + 1 - digits.count)
        } else {
            let split = digits.index(digits.startIndex, offsetBy: exponent + 1)
            body = "\(digits[..<split]).\(digits[split...])"
        }
    } else {
        body = "0." + String(repeating: "0", count: -exponent - 1) + digits
    }
    return negative ? "-" + body : body
}

private func binEdges(_ samples: [Double], bins: Int?, min minValue: Double?, max maxValue: Double?, edges: [Double]?) -> [Double]? {
    if let edges, edges.count >= 2 { return edges.sorted() }
    let lo = minValue ?? samples.min() ?? .nan
    let hi = maxValue ?? samples.max() ?? .nan
    guard lo.isFinite, hi.isFinite else { return nil }
    let count = max(1, bins ?? sturges(samples.count))
    let span = hi - lo == 0 ? 1 : hi - lo
    let width = span / Double(count)
    return (0...count).map { lo + Double($0) * width }
}

private func sturges(_ count: Int) -> Int {
    max(1, Int(ceil(log2(Double(max(count, 1))) + 1)))
}

private func binLabel(_ from: Double, _ to: Double) -> String {
    "\(binText(from))–\(binText(to))"
}

private func binText(_ value: Double) -> String {
    value.isFinite && value.rounded() == value ? String(Int(value)) : jsToPrecision(value, precision: 4)
}

private func merging(_ base: BandStyle, _ extra: BandStyle) -> BandStyle {
    BandStyle(
        fill: extra.fill ?? base.fill,
        label: extra.label ?? base.label,
        legendColor: extra.legendColor ?? base.legendColor,
        hatch: extra.hatch ?? base.hatch
    )
}
