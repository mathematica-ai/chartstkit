import Foundation

public enum CategoryBarMode: String, Sendable { case group, stack, overlay }
public enum CategoryOrientation: String, Sendable { case vertical, horizontal }
public enum CategoryScale: String, Sendable { case left, right }

public enum CategoryBarDatum: Hashable, Sendable {
    case value(Double)
    case styled(Double, color: String?, label: String?)

    public var number: Double? {
        switch self {
        case let .value(value): return value.isFinite ? value : nil
        case let .styled(value, _, _): return value.isFinite ? value : nil
        }
    }

    public var color: String? {
        if case let .styled(_, color, _) = self { return color }
        return nil
    }

    public var label: String? {
        if case let .styled(_, _, label) = self { return label }
        return nil
    }
}

extension CategoryBarDatum: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) { self = .value(Double(value)) }
    public init(floatLiteral value: Double) { self = .value(value) }
}

public struct CategorySeriesInput: Sendable {
    public var id: String
    public var data: [Double]
    public var scale: CategoryScale
    public init(id: String, data: [Double], scale: CategoryScale = .left) {
        self.id = id
        self.data = data
        self.scale = scale
    }
}

public struct CategoryRect: Equatable, Sendable {
    public var series: String
    public var category: Int
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var value: Double
}

public struct CategoryPad: Equatable, Sendable {
    public var top, right, bottom, left: Double
    public init(top: Double, right: Double, bottom: Double, left: Double) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
}

public struct CategoryExtent: Equatable, Sendable {
    public var min: Double
    public var max: Double
}

public struct CategoryDomain: Equatable, Sendable {
    public var min: Double?
    public var max: Double?
    public init(min: Double? = nil, max: Double? = nil) {
        self.min = min
        self.max = max
    }
}

public struct CategoryLine: Equatable, Sendable {
    public var x1, y1, x2, y2: Double
}

public struct CategoryFrame: Sendable {
    public var rects: [CategoryRect]
    public var orientation: CategoryOrientation
    public var pad: CategoryPad
    public var left: CategoryExtent
    public var right: CategoryExtent?
    public var across: (Double, CategoryScale) -> CategoryLine
}

public struct CategoryLayoutOptions {
    public var mode: CategoryBarMode
    public var series: [CategorySeriesInput]
    public var categories: Int
    public var width: Double
    public var height: Double
    public var pad: CategoryPad?
    public var orientation: CategoryOrientation
    public var domain: CategoryDomain?
    public var rightDomain: CategoryDomain?
    public var pins: [(value: Double, scale: CategoryScale)]
    public init(
        mode: CategoryBarMode, series: [CategorySeriesInput], categories: Int, width: Double, height: Double,
        pad: CategoryPad? = nil, orientation: CategoryOrientation = .vertical, domain: CategoryDomain? = nil,
        rightDomain: CategoryDomain? = nil, pins: [(value: Double, scale: CategoryScale)] = []
    ) {
        self.mode = mode
        self.series = series
        self.categories = categories
        self.width = width
        self.height = height
        self.pad = pad
        self.orientation = orientation
        self.domain = domain
        self.rightDomain = rightDomain
        self.pins = pins
    }
}

private let verticalPad = CategoryPad(top: 16, right: 12, bottom: 28, left: 36)
private let horizontalPad = CategoryPad(top: 12, right: 56, bottom: 28, left: 96)

public func categoryFrame(_ options: CategoryLayoutOptions) -> CategoryFrame {
    let orientation = options.orientation
    let pad = options.pad ?? (orientation == .horizontal ? horizontalPad : verticalPad)
    func pins(for scale: CategoryScale) -> [Double] {
        options.pins.compactMap { $0.scale == scale && $0.value.isFinite ? $0.value : nil }
    }
    let left = extentOf(options.mode, options.series, options.categories, .left, options.domain, pins(for: .left))
        ?? CategoryExtent(min: 0, max: 1)
    let right = extentOf(options.mode, options.series, options.categories, .right, options.rightDomain, pins(for: .right))
    let rects: [CategoryRect]
    if options.categories <= 0 || options.series.isEmpty {
        rects = []
    } else if orientation == .horizontal {
        rects = placeHorizontal(options, pad, left, right)
    } else {
        rects = placeVertical(options, pad, left, right)
    }
    return CategoryFrame(rects: rects, orientation: orientation, pad: pad, left: left, right: right) { value, scale in
        acrossLine(orientation, pad, options.width, options.height, left, right, value, scale)
    }
}

public func categoryLayout(_ options: CategoryLayoutOptions) -> [CategoryRect] {
    categoryFrame(options).rects
}

public func axisTicks(min minValue: Double, max maxValue: Double, count: Int = 4) -> [Double] {
    if !(maxValue > minValue) || count < 1 { return [minValue] }
    let step = (maxValue - minValue) / Double(count)
    return (0...count).map { jsToPrecision(minValue + step * Double($0), precision: 6).asDouble }
}

public struct ScatterDatum: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct PlacedScatterPoint: Equatable, Sendable {
    public var series: String
    public var index: Int
    public var x: Double
    public var y: Double
    public var px: Double
    public var py: Double
}

public struct ScatterFrame {
    public var points: [PlacedScatterPoint]
    public var xTicks: [Double]
    public var yTicks: [Double]
    public var xOf: (Double) -> Double
    public var yOf: (Double) -> Double
}

public func scatterLayout(series: [(id: String, data: [ScatterDatum])], width: Double, height: Double) -> ScatterFrame {
    let finite = series.flatMap { $0.data.filter { $0.x.isFinite && $0.y.isFinite } }
    let xMin = finite.map(\.x).min() ?? 0
    let xMax = finite.map(\.x).max() ?? 1
    let yMin = finite.map(\.y).min() ?? 0
    let yMax = finite.map(\.y).max() ?? 1
    let xSpan = xMax - xMin == 0 ? 1 : xMax - xMin
    let ySpan = yMax - yMin == 0 ? 1 : yMax - yMin
    let pad = (top: 16.0, right: 16.0, bottom: 32.0, left: 40.0)
    let plotW = max(0, width - pad.left - pad.right)
    let plotH = max(0, height - pad.top - pad.bottom)
    let xOf = { (value: Double) in pad.left + ((value - xMin) / xSpan) * plotW }
    let yOf = { (value: Double) in pad.top + ((yMax - value) / ySpan) * plotH }
    let points = series.flatMap { item in
        item.data.enumerated().compactMap { index, point -> PlacedScatterPoint? in
            guard point.x.isFinite, point.y.isFinite else { return nil }
            return PlacedScatterPoint(series: item.id, index: index, x: point.x, y: point.y, px: xOf(point.x), py: yOf(point.y))
        }
    }
    return ScatterFrame(points: points, xTicks: niceTicks(xMin, xMax, 4), yTicks: niceTicks(yMin, yMax, 4), xOf: xOf, yOf: yOf)
}

public enum PolarDirection: String, Sendable { case clockwise, counterclockwise }

public func polarPoint(cx: Double, cy: Double, radius: Double, angle: Double) -> (Double, Double) {
    (round2(cx + radius * sin(angle)), round2(cy - radius * cos(angle)))
}

public func wedgeAngles(index: Int, count: Int, direction: PolarDirection) -> (Double, Double) {
    let span = (2 * .pi) / Double(max(1, count))
    let sign: Double = direction == .counterclockwise ? -1 : 1
    let start = sign * Double(index) * span
    return (start, start + sign * span)
}

public func barRadius(value: Double, max maxValue: Double, radius: Double) -> Double {
    if !(maxValue > 0) || !value.isFinite || value <= 0 { return 0 }
    return (value / maxValue) * radius
}

public enum SparklineDatum: Hashable, Sendable {
    case number(Double?)
    case point(Double?)
    public var value: Double? {
        let raw: Double?
        switch self {
        case let .number(value), let .point(value): raw = value
        }
        guard let raw, raw.isFinite else { return nil }
        return raw
    }
}

public func sparklineValue(_ datum: SparklineDatum) -> Double? { datum.value }

public struct SparklinePoint: Equatable, Sendable { public var x: Double; public var y: Double }

public func sparklineRuns(_ data: [SparklineDatum], width: Double, height: Double, pad: Double = 1) -> [[SparklinePoint]] {
    let values = data.map(sparklineValue)
    let place = sparklinePlace(values, width, height, pad)
    var runs: [[SparklinePoint]] = []
    var run: [SparklinePoint] = []
    for (index, value) in values.enumerated() {
        guard let value else {
            if !run.isEmpty { runs.append(run) }
            run = []
            continue
        }
        run.append(SparklinePoint(x: place.x(index), y: place.y(value)))
    }
    if !run.isEmpty { runs.append(run) }
    return runs
}

public func sparklinePaths(_ data: [SparklineDatum], width: Double, height: Double, pad: Double = 1) -> [String] {
    let values = data.map(sparklineValue)
    let place = sparklinePlace(values, width, height, pad)
    var paths: [String] = []
    var command: [String] = []
    for (index, value) in values.enumerated() {
        guard let value else {
            if !command.isEmpty { paths.append(command.joined(separator: " ")) }
            command = []
            continue
        }
        let point = "\(format2(place.x(index))) \(format2(place.y(value)))"
        command.append(command.isEmpty ? "M \(point)" : "L \(point)")
    }
    if !command.isEmpty { paths.append(command.joined(separator: " ")) }
    return paths
}

public func sparklineArea(_ data: [SparklineDatum], width: Double, height: Double, pad: Double = 1) -> String? {
    guard let line = sparklinePaths(data, width: width, height: height, pad: pad).first else { return nil }
    let values = data.map(sparklineValue)
    guard let first = values.firstIndex(where: { $0 != nil }) else { return nil }
    guard let last = values.lastIndex(where: { $0 != nil }) else { return nil }
    let finite = values.compactMap { $0 }
    let place = sparklinePlace(values, width, height, pad)
    let baseline = place.y(finite.min() ?? 0)
    return "\(line) L \(format2(place.x(last))) \(format2(baseline)) L \(format2(place.x(first))) \(format2(baseline)) Z"
}

public struct HeatmapPosition: Equatable, Hashable, Sendable {
    public var r: Int
    public var c: Int
    public init(r: Int, c: Int) { self.r = r; self.c = c }
}

public struct HeatmapRange: Equatable, Sendable {
    public var r0, r1, c0, c1: Int
    public init(r0: Int, r1: Int, c0: Int, c1: Int) {
        self.r0 = r0
        self.r1 = r1
        self.c0 = c0
        self.c1 = c1
    }
}

public struct HeatmapCell<Row, Column>: Sendable {
    public var row: Row
    public var column: Column
    public var r: Int
    public var c: Int
    public var value: Double?
    public var step: Int
}

public struct HeatmapStats<Row, Column>: Sendable {
    public var count: Int
    public var missing: Int
    public var mean: Double?
    public var min: HeatmapCell<Row, Column>?
    public var max: HeatmapCell<Row, Column>?
}

public struct HeatmapLayout: Equatable, Sendable {
    public var rows: Int
    public var cols: Int
    public var top: Double
    public var width: Double
    public var height: Double
    public var cellSize: Double
    public var labelWidth: Double
    public var axisY: Double
    public func cell(_ r: Int, _ c: Int, gap: Double = 0) -> (x: Double, y: Double, size: Double) {
        (labelWidth + Double(c) * cellSize + gap / 2, top + Double(r) * cellSize + gap / 2, max(cellSize - gap, 0))
    }
}

public func heatmapGrid<Row, Column>(
    rows: [Row], columns: [Column],
    value: (Row, Column, Int, Int) -> Double?,
    count: Int = 5, thresholds: [Double]? = nil, scale: QuantizeScale = .equal
) throws -> (grid: [[HeatmapCell<Row, Column>]], thresholds: [Double]) {
    let raw: [[Double?]] = rows.enumerated().map { r, row in
        columns.enumerated().map { c, column in
            let number = value(row, column, r, c)
            return (number?.isFinite == true) ? number : nil
        }
    }
    let finite = raw.flatMap { $0 }.compactMap { $0 }
    let quantizer = try quantize(finite, count: count, thresholds: thresholds, scale: scale)
    let grid: [[HeatmapCell<Row, Column>]] = rows.enumerated().map { r, row in
        columns.enumerated().map { c, column in
            let number = raw[r][c]
            return HeatmapCell(row: row, column: column, r: r, c: c, value: number, step: number == nil ? 0 : quantizer.step(number!) + 1)
        }
    }
    return (grid, quantizer.thresholds)
}

public func stepColor(step: Int, count: Int, palette: [String]) -> String? {
    if step < 1 || palette.isEmpty { return nil }
    if count <= 1 { return palette[palette.count - 1] }
    let at = Int((((Double(step - 1) * Double(palette.count - 1)) / Double(count - 1))).rounded())
    return palette[min(at, palette.count - 1)]
}

public func normaliseRange(_ a: HeatmapPosition, _ b: HeatmapPosition) -> HeatmapRange {
    HeatmapRange(r0: min(a.r, b.r), r1: max(a.r, b.r), c0: min(a.c, b.c), c1: max(a.c, b.c))
}

public func inRange(_ range: HeatmapRange?, _ r: Int, _ c: Int) -> Bool {
    guard let range else { return false }
    return r >= range.r0 && r <= range.r1 && c >= range.c0 && c <= range.c1
}

public func rangeStats<Row, Column>(_ grid: [[HeatmapCell<Row, Column>]], range: HeatmapRange, hiddenSteps: [Int] = []) -> HeatmapStats<Row, Column> {
    var count = 0
    var missing = 0
    var total = 0.0
    var minCell: HeatmapCell<Row, Column>?
    var maxCell: HeatmapCell<Row, Column>?
    for cells in grid {
        for cell in cells {
            guard inRange(range, cell.r, cell.c) else { continue }
            guard let value = cell.value else { missing += 1; continue }
            if hiddenSteps.contains(cell.step) { continue }
            count += 1
            total += value
            if minCell == nil || value < minCell!.value! { minCell = cell }
            if maxCell == nil || value > maxCell!.value! { maxCell = cell }
        }
    }
    return HeatmapStats(count: count, missing: missing, mean: count > 0 ? total / Double(count) : nil, min: minCell, max: maxCell)
}

public func extremes<Row, Column>(_ grid: [[HeatmapCell<Row, Column>]]) -> (min: HeatmapCell<Row, Column>?, max: HeatmapCell<Row, Column>?) {
    let stats = rangeStats(grid, range: HeatmapRange(r0: 0, r1: max(0, grid.count - 1), c0: 0, c1: Int.max))
    return (stats.min, stats.max)
}

public func heatmapLayout(rows: Int, cols: Int, cellSize: Double = 30, labelWidth: Double = 46, gap: Double = 0) -> HeatmapLayout {
    let top = 6.0
    return HeatmapLayout(
        rows: rows, cols: cols, top: top,
        width: labelWidth + Double(cols) * cellSize + 4,
        height: top + Double(rows) * cellSize + 26,
        cellSize: cellSize, labelWidth: labelWidth, axisY: top + Double(rows) * cellSize
    )
}

public func cellAt(_ layout: HeatmapLayout, x: Double, y: Double, clamp: Bool = false) -> HeatmapPosition? {
    let c = Int(floor((x - layout.labelWidth) / layout.cellSize))
    let r = Int(floor((y - layout.top) / layout.cellSize))
    func fit(_ at: Int, _ size: Int) -> Int { min(max(at, 0), size - 1) }
    if clamp, layout.rows > 0, layout.cols > 0 { return HeatmapPosition(r: fit(r, layout.rows), c: fit(c, layout.cols)) }
    if r >= 0, r < layout.rows, c >= 0, c < layout.cols { return HeatmapPosition(r: r, c: c) }
    return nil
}

public enum HeatmapEmphasis: String, Sendable { case crosshair, cell, none }

public func isDimmed(emphasis: HeatmapEmphasis, active: HeatmapPosition?, range: HeatmapRange?, r: Int, c: Int) -> Bool {
    guard let active else { return range != nil && !inRange(range, r, c) }
    if emphasis == .none { return false }
    if emphasis == .cell { return active.r != r || active.c != c }
    return active.r != r && active.c != c
}

public struct PieDatum: Hashable, Sendable {
    public var label: String
    public var value: Double
    public var color: String?
    public init(label: String, value: Double, color: String? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }
}

public struct PieSlice: Equatable, Sendable {
    public var index: Int
    public var value: Double
    public var share: Double
    public var startAngle: Double
    public var endAngle: Double
    public var midAngle: Double
    public var key: String
    public var label: String
    public var color: String?
    public var members: [PieDatum]
    public var other: Bool
    public var shareOfAll: Double
    public var hidden: Bool
    public var selected: Bool
}

public struct PieLabelLayout: Equatable, Sendable {
    public var key: String
    public var side: Int
    public var x: Double
    public var y: Double
    public var points: [SparklinePoint]
}

public func pieSlices(_ data: [PieDatum], maxSlices: Int = .max, otherLabel: String = "Other") -> [PieSlice] {
    let valid = data.filter { $0.value.isFinite && $0.value > 0 }.sorted { $0.value > $1.value }
    let folds = valid.count > maxSlices
    let keep = folds ? max(0, maxSlices - 1) : valid.count
    struct Group {
        var label: String
        var color: String?
        var members: [PieDatum]
        var other: Bool
    }
    var groups = valid.prefix(keep).map { Group(label: $0.label, color: $0.color, members: [$0], other: false) }
    let rest = Array(valid.dropFirst(keep))
    if !rest.isEmpty {
        groups.append(Group(label: otherLabel, color: nil, members: rest, other: true))
    }
    let arcs = (try? pieArcs(groups.map { $0.members.reduce(0) { $0 + $1.value } })) ?? []
    var used = Set<String>()
    func unique(_ base: String) -> String {
        var key = base
        var n = 2
        while used.contains(key) { key = "\(base)#\(n)"; n += 1 }
        used.insert(key)
        return key
    }
    return groups.enumerated().map { index, group in
        let arc = arcs[index]
        return PieSlice(
            index: arc.index, value: arc.value, share: arc.share, startAngle: arc.startAngle,
            endAngle: arc.endAngle, midAngle: arc.midAngle, key: unique(group.other ? "other" : group.label),
            label: group.label, color: group.color, members: group.members, other: group.other,
            shareOfAll: arc.share, hidden: false, selected: false
        )
    }
}

public func hideSlices(_ slices: [PieSlice], hidden: [String]) -> [PieSlice] {
    let arcs = (try? pieArcs(slices.map { hidden.contains($0.key) ? 0 : $0.value })) ?? []
    return slices.enumerated().map { index, slice in
        var copy = slice
        let arc = arcs[index]
        copy.share = arc.share
        copy.startAngle = arc.startAngle
        copy.endAngle = arc.endAngle
        copy.midAngle = arc.midAngle
        copy.hidden = hidden.contains(slice.key)
        return copy
    }
}

public func polar(angle: Double, radius: Double) -> (Double, Double) {
    (round2(sin(angle) * radius), round2(-cos(angle) * radius))
}

public func placeLabels(_ slices: [PieSlice], radius: Double = 100, offset: Double = 16, spacing: Double = 32, limit: Double? = nil) -> [PieLabelLayout] {
    let bound = limit ?? radius + offset
    return [1, -1].flatMap { side -> [PieLabelLayout] in
        let own = slices.filter { (sin($0.midAngle) >= 0 ? 1 : -1) == side }
            .map { (slice: $0, elbow: polar(angle: $0.midAngle, radius: radius + offset / 2)) }
            .sorted { $0.elbow.1 < $1.elbow.1 }
        let ys = spread(own.map(\.elbow.1), spacing: spacing, limit: bound)
        return own.enumerated().map { index, item in
            let x = Double(side) * (radius + offset)
            let y = round2(ys[index])
            let start = polar(angle: item.slice.midAngle, radius: radius)
            return PieLabelLayout(
                key: item.slice.key, side: side, x: x, y: y,
                points: [
                    SparklinePoint(x: start.0, y: start.1),
                    SparklinePoint(x: item.elbow.0, y: item.elbow.1),
                    SparklinePoint(x: x, y: y),
                ]
            )
        }
    }.sorted { lhs, rhs in
        let li = slices.firstIndex { $0.key == lhs.key } ?? 0
        let ri = slices.firstIndex { $0.key == rhs.key } ?? 0
        return li < ri
    }
}

public struct TimeSeriesPoint: Hashable, Sendable {
    public var time: ChartTime
    public var value: Double
    public init(time: ChartTime, value: Double) { self.time = time; self.value = value }
}

public struct RibbonSample: Equatable, Sendable {
    public var time: Int
    public var upper: Double
    public var lower: Double
}

public func seriesRows(_ data: [TimeSeriesPoint], categories: [String]?) -> [(time: Int, value: Double)] {
    var rows: [(time: Int, value: Double)] = []
    for point in data {
        guard let time = seriesTime(point.time, categories: categories), point.value.isFinite else { continue }
        if let last = rows.last, last.time == time { rows[rows.count - 1] = (time, point.value) }
        else { rows.append((time, point.value)) }
    }
    rows.sort { $0.time < $1.time }
    var unique: [(time: Int, value: Double)] = []
    for row in rows {
        if let last = unique.last, last.time == row.time { unique[unique.count - 1] = row }
        else { unique.append(row) }
    }
    return unique
}

public func ribbonSamples(upper: [TimeSeriesPoint], lower: [TimeSeriesPoint], categories: [String]?) -> [RibbonSample] {
    var below: [Int: Double] = [:]
    for point in lower {
        guard let time = seriesTime(point.time, categories: categories), point.value.isFinite else { continue }
        below[time] = point.value
    }
    var samples: [RibbonSample] = []
    for point in upper {
        guard let time = seriesTime(point.time, categories: categories), let low = below[time], point.value.isFinite else { continue }
        samples.append(RibbonSample(time: time, upper: point.value, lower: low))
    }
    return samples.sorted { $0.time < $1.time }
}

public struct TimelineItem: Hashable, Sendable {
    public var start: ChartTime
    public var end: ChartTime
    public var eta: ChartTime?
    public var state: String
    public var label: String?
    public var color: String?
    public init(start: ChartTime, end: ChartTime, eta: ChartTime? = nil, state: String, label: String? = nil, color: String? = nil) {
        self.start = start
        self.end = end
        self.eta = eta
        self.state = state
        self.label = label
        self.color = color
    }
}

public struct TimeRangeItem: Equatable, Sendable {
    public var from: ChartTime
    public var to: ChartTime
    public var key: String
    public var label: String?
    public var color: String?
}

public func timelineRanges(_ items: [TimelineItem]) -> [TimeRangeItem] {
    items.flatMap { item -> [TimeRangeItem] in
        let bar = TimeRangeItem(from: item.start, to: item.end, key: item.state, label: item.label, color: item.color)
        guard let eta = item.eta, let etaTime = toUnixSeconds(eta), let startTime = toUnixSeconds(item.start), etaTime < startTime else {
            return [bar]
        }
        return [TimeRangeItem(from: eta, to: item.start, key: "arrival", label: nil, color: nil), bar]
    }
}

public func unixTimes(_ times: [ChartTime]) -> [Int] {
    Array(Set(times.compactMap(toUnixSeconds))).sorted()
}

public func timeGrid(_ times: [ChartTime], step: Int = 3600) -> [Int] {
    let known = unixTimes(times)
    guard let first = known.first, let last = known.last, step > 0 else { return [] }
    let size = max(step, Int(ceil(Double(last - first) / 5000)))
    let from = (first / size) * size
    let to = Int(ceil(Double(last) / Double(size))) * size
    let count = max(1, (to - from) / size + 1)
    return (0..<count).map { from + $0 * size }
}

public enum PieSelectionMode: String, Sendable { case none, single, multiple }
public enum PieEmphasis: String, Sendable { case dim, none }
public enum HeatmapSelectionMode: String, Sendable { case none, single, range }

public struct PieChartState: Equatable, Sendable {
    public var selectionMode: PieSelectionMode
    public var drillOther: Bool
    public private(set) var selectedKeys: [String]
    public private(set) var hiddenKeys: [String]
    public private(set) var drilled: Bool
    public private(set) var activeKey: String?
    private var root: [PieSlice]
    private var drilledSlices: [PieSlice]

    public init(data: [PieDatum], maxSlices: Int = .max, otherLabel: String = "Other", selectionMode: PieSelectionMode = .none, drillOther: Bool = false) {
        self.selectionMode = selectionMode
        self.drillOther = drillOther
        self.selectedKeys = []
        self.hiddenKeys = []
        self.drilled = false
        self.activeKey = nil
        self.root = pieSlices(data, maxSlices: maxSlices, otherLabel: otherLabel)
        self.drilledSlices = []
    }

    public var slices: [PieSlice] {
        let laid = drilled ? drilledSlices : root
        let chosen = shownKeys(selectionMode, selectedKeys)
        return hideSlices(laid, hidden: hiddenKeys).map { slice in
            var copy = slice
            copy.selected = !slice.hidden && chosen.contains(slice.key)
            return copy
        }
    }

    public var visible: [PieSlice] { slices.filter { !$0.hidden } }
    public var active: PieSlice? { visible.first { $0.key == activeKey } }

    public mutating func activate(_ key: String?) { activeKey = key }

    public mutating func click(_ key: String) {
        guard let slice = slices.first(where: { $0.key == key }) else { return }
        if drillOther, slice.other, !drilled {
            drilledSlices = pieSlices(slice.members)
            drilled = true
            selectedKeys = []
            hiddenKeys = []
            activeKey = nil
            return
        }
        guard selectionMode != .none else { return }
        let chosen = shownKeys(selectionMode, selectedKeys)
        if slice.selected {
            selectedKeys = chosen.filter { $0 != key }
        } else if selectionMode == .single {
            selectedKeys = [key]
        } else {
            selectedKeys = chosen + [key]
        }
    }

    public mutating func hide(_ key: String, only: Bool = false) {
        let keys = slices.map(\.key)
        let next = hideKeys(keys, hidden: hiddenKeys, key: key, only: only)
        if next == hiddenKeys { return }
        hiddenKeys = next
        selectedKeys = selectedKeys.filter { !next.contains($0) }
        if let activeKey, next.contains(activeKey) { self.activeKey = nil }
    }

    public mutating func clearSelection() { selectedKeys = [] }

    public mutating func back() {
        guard drilled else { return }
        drilled = false
        drilledSlices = []
        selectedKeys = []
        hiddenKeys = []
        activeKey = nil
    }

    public mutating func move(by delta: Int) {
        let items = visible
        guard !items.isEmpty else { return }
        let current = items.firstIndex { $0.key == activeKey } ?? 0
        let next = (current + delta + items.count) % items.count
        activeKey = items[next].key
    }
}

private func shownKeys(_ mode: PieSelectionMode, _ keys: [String]) -> [String] {
    switch mode {
    case .none: return []
    case .single: return keys.suffix(1).map { $0 }
    case .multiple: return keys
    }
}

private func extentOf(
    _ mode: CategoryBarMode, _ series: [CategorySeriesInput], _ categories: Int,
    _ scale: CategoryScale, _ domain: CategoryDomain?, _ pins: [Double]
) -> CategoryExtent? {
    let mine = series.filter { $0.scale == scale }
    if mine.isEmpty { return nil }
    var minValue = 0.0
    var maxValue = 0.0
    for category in 0..<categories {
        var positive = 0.0
        var negative = 0.0
        for item in mine {
            guard item.data.indices.contains(category) else { continue }
            let value = item.data[category]
            guard value.isFinite else { continue }
            if mode == .stack {
                if value >= 0 { positive += value } else { negative += value }
            } else {
                minValue = min(minValue, value)
                maxValue = max(maxValue, value)
            }
        }
        if mode == .stack {
            minValue = min(minValue, negative)
            maxValue = max(maxValue, positive)
        }
    }
    for pin in pins where pin.isFinite {
        minValue = min(minValue, pin)
        maxValue = max(maxValue, pin)
    }
    let lo = domain?.min ?? minValue
    let hi = domain?.max ?? maxValue
    return CategoryExtent(min: lo, max: hi == lo ? hi + 1 : hi)
}

private struct PresentBar { var id: String; var value: Double; var scale: CategoryScale }

private func presentAt(_ series: [CategorySeriesInput], _ category: Int) -> [PresentBar] {
    series.compactMap { item in
        guard item.data.indices.contains(category), item.data[category].isFinite else { return nil }
        return PresentBar(id: item.id, value: item.data[category], scale: item.scale)
    }
}

private func placeVertical(_ options: CategoryLayoutOptions, _ pad: CategoryPad, _ left: CategoryExtent, _ right: CategoryExtent?) -> [CategoryRect] {
    let plotH = max(0, options.height - pad.top - pad.bottom)
    let plotW = max(0, options.width - pad.left - pad.right)
    func yFor(_ scale: CategoryScale) -> (Double) -> Double {
        let extent = scale == .right && right != nil ? right! : left
        let span = extent.max - extent.min == 0 ? 1 : extent.max - extent.min
        return { value in pad.top + ((extent.max - value) / span) * plotH }
    }
    let slot = plotW / Double(max(options.categories, 1))
    var rects: [CategoryRect] = []
    for category in 0..<options.categories {
        let present = presentAt(options.series, category)
        if present.isEmpty { continue }
        let inner = slot * 0.72
        let origin = pad.left + Double(category) * slot + (slot - inner) / 2
        if options.mode == .group {
            let gap = present.count > 1 ? 2.0 : 0
            let barW = (inner - gap * Double(present.count - 1)) / Double(present.count)
            for (index, item) in present.enumerated() {
                let yOf = yFor(item.scale)
                let y = min(yOf(item.value), yOf(0))
                rects.append(CategoryRect(series: item.id, category: category, x: origin + Double(index) * (barW + gap), y: y, width: barW, height: abs(yOf(item.value) - yOf(0)), value: item.value))
            }
        } else if options.mode == .overlay {
            for item in present {
                let yOf = yFor(item.scale)
                let y = min(yOf(item.value), yOf(0))
                rects.append(CategoryRect(series: item.id, category: category, x: origin, y: y, width: inner, height: abs(yOf(item.value) - yOf(0)), value: item.value))
            }
        } else {
            for scale in [CategoryScale.left, .right] {
                var positive = 0.0
                var negative = 0.0
                let yOf = yFor(scale)
                for item in present where item.scale == scale {
                    let start = item.value >= 0 ? positive : negative
                    let end = start + item.value
                    if item.value >= 0 { positive = end } else { negative = end }
                    let y = min(yOf(start), yOf(end))
                    rects.append(CategoryRect(series: item.id, category: category, x: origin, y: y, width: inner, height: abs(yOf(end) - yOf(start)), value: item.value))
                }
            }
        }
    }
    return rects
}

private func placeHorizontal(_ options: CategoryLayoutOptions, _ pad: CategoryPad, _ left: CategoryExtent, _ right: CategoryExtent?) -> [CategoryRect] {
    let plotW = max(0, options.width - pad.left - pad.right)
    let plotH = max(0, options.height - pad.top - pad.bottom)
    func xFor(_ scale: CategoryScale) -> (Double) -> Double {
        let extent = scale == .right && right != nil ? right! : left
        let span = extent.max - extent.min == 0 ? 1 : extent.max - extent.min
        return { value in pad.left + ((value - extent.min) / span) * plotW }
    }
    let slot = plotH / Double(max(options.categories, 1))
    var rects: [CategoryRect] = []
    for category in 0..<options.categories {
        let present = presentAt(options.series, category)
        if present.isEmpty { continue }
        let inner = slot * 0.72
        let origin = pad.top + Double(category) * slot + (slot - inner) / 2
        if options.mode == .group {
            let gap = present.count > 1 ? 2.0 : 0
            let barH = (inner - gap * Double(present.count - 1)) / Double(present.count)
            for (index, item) in present.enumerated() {
                let xOf = xFor(item.scale)
                let x = min(xOf(item.value), xOf(0))
                rects.append(CategoryRect(series: item.id, category: category, x: x, y: origin + Double(index) * (barH + gap), width: abs(xOf(item.value) - xOf(0)), height: barH, value: item.value))
            }
        } else if options.mode == .overlay {
            for item in present {
                let xOf = xFor(item.scale)
                let x = min(xOf(item.value), xOf(0))
                rects.append(CategoryRect(series: item.id, category: category, x: x, y: origin, width: abs(xOf(item.value) - xOf(0)), height: inner, value: item.value))
            }
        } else {
            for scale in [CategoryScale.left, .right] {
                var positive = 0.0
                var negative = 0.0
                let xOf = xFor(scale)
                for item in present where item.scale == scale {
                    let start = item.value >= 0 ? positive : negative
                    let end = start + item.value
                    if item.value >= 0 { positive = end } else { negative = end }
                    let x = min(xOf(start), xOf(end))
                    rects.append(CategoryRect(series: item.id, category: category, x: x, y: origin, width: abs(xOf(end) - xOf(start)), height: inner, value: item.value))
                }
            }
        }
    }
    return rects
}

private func acrossLine(
    _ orientation: CategoryOrientation, _ pad: CategoryPad, _ width: Double, _ height: Double,
    _ left: CategoryExtent, _ right: CategoryExtent?, _ value: Double, _ scale: CategoryScale
) -> CategoryLine {
    let extent = scale == .right && right != nil ? right! : left
    let span = extent.max - extent.min == 0 ? 1 : extent.max - extent.min
    if orientation == .horizontal {
        let plotW = max(0, width - pad.left - pad.right)
        let x = pad.left + ((value - extent.min) / span) * plotW
        return CategoryLine(x1: x, y1: pad.top, x2: x, y2: height - pad.bottom)
    }
    let plotH = max(0, height - pad.top - pad.bottom)
    let y = pad.top + ((extent.max - value) / span) * plotH
    return CategoryLine(x1: pad.left, y1: y, x2: width - pad.right, y2: y)
}

private func niceTicks(_ minValue: Double, _ maxValue: Double, _ count: Int) -> [Double] {
    let span = maxValue - minValue
    let step = niceStep(span, count: count)
    var value = ceil(minValue / step) * step
    var ticks: [Double] = []
    while value <= maxValue + step * 1e-6 {
        ticks.append(jsToPrecision(value, precision: 12).asDouble)
        value += step
    }
    return ticks.isEmpty ? [minValue, maxValue] : ticks
}

private func niceStep(_ span: Double, count: Int) -> Double {
    if !(span > 0) { return 1 }
    let rough = span / Double(max(1, count))
    let power = pow(10, floor(log10(rough)))
    let error = rough / power
    let nice: Double = error >= 7.5 ? 10 : error >= 3.5 ? 5 : error >= 1.5 ? 2 : 1
    return nice * power
}

private func sparklinePlace(_ values: [Double?], _ width: Double, _ height: Double, _ pad: Double) -> (x: (Int) -> Double, y: (Double) -> Double) {
    let finite = values.compactMap { $0 }
    let minValue = finite.min() ?? 0
    let maxValue = finite.max() ?? 1
    let span = maxValue - minValue == 0 ? 1 : maxValue - minValue
    let steps = Double(max(values.count - 1, 1))
    return (
        { index in pad + (Double(index) / steps) * (width - pad * 2) },
        { value in pad + (1 - (value - minValue) / span) * (height - pad * 2) }
    )
}

private func spread(_ input: [Double], spacing: Double, limit: Double) -> [Double] {
    var ys = input
    if ys.isEmpty { return ys }
    if ys.count > 1 {
        for index in 1..<ys.count { ys[index] = max(ys[index], ys[index - 1] + spacing) }
    }
    ys[ys.count - 1] = min(ys[ys.count - 1], limit)
    if ys.count > 1 {
        for index in stride(from: ys.count - 2, through: 0, by: -1) {
            ys[index] = min(ys[index], ys[index + 1] - spacing)
        }
    }
    for index in ys.indices { ys[index] = max(ys[index], -limit) }
    return ys
}

func round2(_ value: Double) -> Double {
    let rounded = (value * 100).rounded() / 100
    return rounded == 0 ? 0 : rounded
}

private func format2(_ value: Double) -> String { String(format: "%.2f", round2(value)) }

private extension String {
    var asDouble: Double { Double(self) ?? 0 }
}
