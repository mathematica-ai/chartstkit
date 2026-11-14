import SwiftUI

public struct CategoryBarSeries: Identifiable, Sendable {
    public var id: String
    public var name: String
    public var data: [CategoryBarDatum]
    public var color: String?
    public var scale: CategoryScale
    public init(id: String, name: String, data: [CategoryBarDatum], color: String? = nil, scale: CategoryScale = .left) {
        self.id = id
        self.name = name
        self.data = data
        self.color = color
        self.scale = scale
    }
}

public struct CategoryReference: Hashable, Sendable {
    public var value: Double
    public var label: String?
    public var color: String?
    public var scale: CategoryScale
    public init(value: Double, label: String? = nil, color: String? = nil, scale: CategoryScale = .left) {
        self.value = value
        self.label = label
        self.color = color
        self.scale = scale
    }
}

public struct CategoryBand: Hashable, Sendable {
    public var from: Double
    public var to: Double
    public var color: String?
    public var scale: CategoryScale
    public init(from: Double, to: Double, color: String? = nil, scale: CategoryScale = .left) {
        self.from = from
        self.to = to
        self.color = color
        self.scale = scale
    }
}

public struct CategoryBarChart: View {
    public var categories: [String]
    public var series: [CategoryBarSeries]
    public var mode: CategoryBarMode
    public var orientation: CategoryOrientation
    public var domain: CategoryDomain?
    public var rightDomain: CategoryDomain?
    public var reference: CategoryReference?
    public var references: [CategoryReference]
    public var bands: [CategoryBand]
    public var activeIndex: Int?
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var onSelect: ((String, Int) -> Void)?
    public var formatValue: ((String, Double) -> String)?

    @Environment(\.chartTheme) private var environmentTheme
    @Environment(\.chartAccessibility) private var chartAccessibility
    @State private var hover: Int?
    @FocusState private var focused: Bool

    public init(
        categories: [String], series: [CategoryBarSeries], mode: CategoryBarMode = .group,
        orientation: CategoryOrientation = .vertical, domain: CategoryDomain? = nil, rightDomain: CategoryDomain? = nil,
        reference: CategoryReference? = nil, references: [CategoryReference] = [], bands: [CategoryBand] = [],
        activeIndex: Int? = nil, ariaLabel: String = "Bar chart", theme: ChartTheme? = nil,
        onSelect: ((String, Int) -> Void)? = nil, formatValue: ((String, Double) -> String)? = nil
    ) {
        self.categories = categories
        self.series = series
        self.mode = mode
        self.orientation = orientation
        self.domain = domain
        self.rightDomain = rightDomain
        self.reference = reference
        self.references = references
        self.bands = bands
        self.activeIndex = activeIndex
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.onSelect = onSelect
        self.formatValue = formatValue
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        GeometryReader { geo in
            let frame = layout(in: geo.size)
            let marked = hover ?? activeIndex
            Canvas { context, _ in
                drawBands(context, frame: frame, theme: theme, size: geo.size)
                for tick in axisTicks(min: frame.left.min, max: frame.left.max) {
                    let line = frame.across(tick, .left)
                    var path = Path()
                    path.move(to: CGPoint(x: line.x1, y: line.y1))
                    path.addLine(to: CGPoint(x: line.x2, y: line.y2))
                    context.stroke(path, with: .color(chartColor(theme.palette.grid)), lineWidth: 1)
                }
                for rect in frame.rects {
                    let color = colorFor(rect, theme: theme)
                    let active = marked == rect.category
                    let opacity = mode == .overlay ? 0.72 : 1
                    context.fill(Path(CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)), with: .color(chartColor(color).opacity(active || marked == nil ? opacity : 0.45)))
                }
                for item in allReferences {
                    let line = frame.across(item.value, item.scale)
                    var path = Path()
                    path.move(to: CGPoint(x: line.x1, y: line.y1))
                    path.addLine(to: CGPoint(x: line.x2, y: line.y2))
                    context.stroke(path, with: .color(chartColor(item.color, fallback: chartColor(theme.palette.neutral))), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .gesture(SpatialTapGesture().onEnded { value in
                guard let index = categoryAt(value.location, frame: frame, size: geo.size) else { return }
                hover = index
                if categories.indices.contains(index) { onSelect?(categories[index], index) }
            })
        }
        .frame(height: 320)
        .focusable()
        .focused($focused)
        .onKeyPress(.leftArrow) { step(orientation == .horizontal ? 0 : -1); return .handled }
        .onKeyPress(.rightArrow) { step(orientation == .horizontal ? 0 : 1); return .handled }
        .onKeyPress(.upArrow) { step(orientation == .horizontal ? -1 : 0); return .handled }
        .onKeyPress(.downArrow) { step(orientation == .horizontal ? 1 : 0); return .handled }
        .chartAccess(chartAccessibility, title: ariaLabel, summary: ariaLabel, samples: categoricalSamples(series: series.map { (name: $0.name, values: $0.data.map(\.number)) }, categories: categories, formatValue: formatChartNumber), categorical: true)
        .accessibilityAdjustableAction { direction in
            step(direction == .increment ? 1 : -1)
        }
        .overlay(alignment: .topTrailing) { tooltip(theme) }
    }

    private var allReferences: [CategoryReference] {
        (reference.map { [$0] } ?? []) + references
    }

    private func layout(in size: CGSize) -> CategoryFrame {
        let inputs = series.map { item in
            CategorySeriesInput(id: item.id, data: item.data.map { $0.number ?? .nan }, scale: item.scale)
        }
        let pins = allReferences.map { (value: $0.value, scale: $0.scale) } + bands.flatMap {
            [(value: $0.from, scale: $0.scale), (value: $0.to, scale: $0.scale)]
        }
        return categoryFrame(CategoryLayoutOptions(
            mode: mode, series: inputs, categories: categories.count, width: size.width, height: size.height,
            orientation: orientation, domain: domain, rightDomain: rightDomain, pins: pins
        ))
    }

    private func colorFor(_ rect: CategoryRect, theme: ChartTheme) -> String {
        if let series = series.first(where: { $0.id == rect.series }),
           series.data.indices.contains(rect.category),
           let color = series.data[rect.category].color {
            return color
        }
        if let color = series.first(where: { $0.id == rect.series })?.color { return color }
        let index = series.firstIndex { $0.id == rect.series } ?? 0
        return categorical(theme, index)
    }

    private func categoryAt(_ point: CGPoint, frame: CategoryFrame, size: CGSize) -> Int? {
        categoryIndex(x: point.x, y: point.y, width: size.width, height: size.height, pad: frame.pad, count: categories.count, orientation: frame.orientation)
    }

    private func step(_ delta: Int) {
        guard delta != 0, !categories.isEmpty else { return }
        let current = hover ?? activeIndex ?? 0
        hover = min(max(current + delta, 0), categories.count - 1)
        if let hover { onSelect?(categories[hover], hover) }
    }

    private func drawBands(_ context: GraphicsContext, frame: CategoryFrame, theme: ChartTheme, size: CGSize) {
        for (index, band) in bands.enumerated() {
            let start = frame.across(min(band.from, band.to), band.scale)
            let end = frame.across(max(band.from, band.to), band.scale)
            let rect: CGRect
            if orientation == .horizontal {
                rect = CGRect(x: min(start.x1, end.x1), y: frame.pad.top, width: abs(end.x1 - start.x1), height: size.height - frame.pad.top - frame.pad.bottom)
            } else {
                rect = CGRect(x: frame.pad.left, y: min(start.y1, end.y1), width: size.width - frame.pad.left - frame.pad.right, height: abs(end.y1 - start.y1))
            }
            context.fill(Path(rect), with: .color(chartColor(band.color, fallback: chartColor(categorical(theme, index)).opacity(0.15))))
        }
    }

    @ViewBuilder private func tooltip(_ theme: ChartTheme) -> some View {
        if let index = hover ?? activeIndex, categories.indices.contains(index) {
            TooltipBox(
                title: categories[index],
                rows: series.compactMap { item in
                    guard item.data.indices.contains(index), let value = item.data[index].number else { return nil }
                    let text = formatValue?(item.id, value) ?? formatChartNumber(value)
                    return (item.name, text, chartColor(item.color ?? categorical(theme, series.firstIndex { $0.id == item.id } ?? 0)))
                },
                theme: theme
            )
            .padding(8)
        }
    }
}

public struct ScatterSeries: Identifiable, Sendable {
    public var id: String
    public var name: String
    public var data: [ScatterPoint]
    public var color: String?
    public var line: Bool
    public var markers: Bool
    public var lineStyle: ChartTheme.Dash
    public init(id: String, name: String, data: [ScatterPoint], color: String? = nil, line: Bool = false, markers: Bool = true, lineStyle: ChartTheme.Dash = .solid) {
        self.id = id
        self.name = name
        self.data = data
        self.color = color
        self.line = line
        self.markers = markers
        self.lineStyle = lineStyle
    }
}

public struct ScatterPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var color: String?
    public var radius: Double?
    public init(x: Double, y: Double, color: String? = nil, radius: Double? = nil) {
        self.x = x
        self.y = y
        self.color = color
        self.radius = radius
    }
}

public struct ScatterChart: View {
    public var series: [ScatterSeries]
    public var xLabel: String?
    public var yLabel: String?
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var onSelect: ((String, Int) -> Void)?

    @Environment(\.chartTheme) private var environmentTheme
    @Environment(\.chartAccessibility) private var chartAccessibility
    @State private var active: Int?
    @FocusState private var focused: Bool

    public init(series: [ScatterSeries], xLabel: String? = nil, yLabel: String? = nil, ariaLabel: String = "Scatter chart", theme: ChartTheme? = nil, onSelect: ((String, Int) -> Void)? = nil) {
        self.series = series
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.onSelect = onSelect
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        GeometryReader { geo in
            let frame = scatterLayout(series: series.map { ($0.id, $0.data.map { ScatterDatum(x: $0.x, y: $0.y) }) }, width: geo.size.width, height: geo.size.height)
            Canvas { context, size in
                for tick in frame.xTicks {
                    var path = Path()
                    path.move(to: CGPoint(x: frame.xOf(tick), y: 16))
                    path.addLine(to: CGPoint(x: frame.xOf(tick), y: size.height - 32))
                    context.stroke(path, with: .color(chartColor(theme.palette.grid)), lineWidth: 1)
                    context.draw(Text(formatChartNumber(tick)).font(chartFont(theme.axis, mono: true)), at: CGPoint(x: frame.xOf(tick), y: size.height - 16))
                }
                for tick in frame.yTicks {
                    var path = Path()
                    path.move(to: CGPoint(x: 40, y: frame.yOf(tick)))
                    path.addLine(to: CGPoint(x: size.width - 16, y: frame.yOf(tick)))
                    context.stroke(path, with: .color(chartColor(theme.palette.grid)), lineWidth: 1)
                }
                for (index, item) in series.enumerated() where item.line {
                    let color = chartColor(item.color ?? categorical(theme, index))
                    var path = Path()
                    var started = false
                    for point in item.data where point.x.isFinite && point.y.isFinite {
                        let spot = CGPoint(x: frame.xOf(point.x), y: frame.yOf(point.y))
                        if started { path.addLine(to: spot) } else { path.move(to: spot); started = true }
                    }
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: dashPattern(item.lineStyle)))
                }
                for (offset, point) in frame.points.enumerated() {
                    let seriesIndex = series.firstIndex { $0.id == point.series } ?? 0
                    guard series.indices.contains(seriesIndex), series[seriesIndex].markers else { continue }
                    let chosen = active == offset
                    let radius = CGFloat((series[seriesIndex].data.indices.contains(point.index) ? series[seriesIndex].data[point.index].radius : nil) ?? (chosen ? 6 : 3.5))
                    let color = chartColor(series[seriesIndex].data.indices.contains(point.index) ? series[seriesIndex].data[point.index].color : nil, fallback: chartColor(series[seriesIndex].color ?? categorical(theme, seriesIndex)))
                    let rect = CGRect(x: point.px - radius, y: point.py - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            .gesture(SpatialTapGesture().onEnded { value in
                guard let index = nearest(value.location, frame: frame) else { return }
                active = index
                let point = frame.points[index]
                onSelect?(point.series, point.index)
            })
        }
        .frame(height: 360)
        .focusable()
        .focused($focused)
        .onKeyPress(.rightArrow) { move(1); return .handled }
        .onKeyPress(.leftArrow) { move(-1); return .handled }
        .chartAccess(
            chartAccessibility,
            title: ariaLabel,
            summary: ariaLabel,
            samples: series.map { item in
                ChartSeriesSample(name: item.name, continuous: item.line, points: item.data.enumerated().compactMap { index, point in
                    guard point.x.isFinite, point.y.isFinite else { return nil }
                    return ChartPointSample(x: point.x, y: point.y, label: "\(formatChartNumber(point.x)), \(formatChartNumber(point.y))")
                })
            },
            categorical: false
        )
        .accessibilityAdjustableAction { direction in
            move(direction == .increment ? 1 : -1)
        }
    }

    private func nearest(_ point: CGPoint, frame: ScatterFrame) -> Int? {
        frame.points.enumerated().min { lhs, rhs in
            hypot(point.x - lhs.element.px, point.y - lhs.element.py) < hypot(point.x - rhs.element.px, point.y - rhs.element.py)
        }?.offset
    }

    private func move(_ delta: Int) {
        let count = series.reduce(0) { $0 + $1.data.count }
        guard count > 0 else { return }
        let next = min(max((active ?? 0) + delta, 0), count - 1)
        active = next
    }
}

public struct PolarBarSeries: Identifiable, Sendable {
    public var id: String
    public var name: String
    public var data: [Double]
    public var color: String?
    public init(id: String, name: String, data: [Double], color: String? = nil) {
        self.id = id
        self.name = name
        self.data = data
        self.color = color
    }
}

public struct PolarScatterSeries: Identifiable, Sendable {
    public var id: String
    public var name: String
    public var data: [(angle: Double, radius: Double)]
    public var color: String?
    public init(id: String, name: String, data: [(angle: Double, radius: Double)], color: String? = nil) {
        self.id = id
        self.name = name
        self.data = data
        self.color = color
    }
}

public enum PolarChartMode {
    case bar
    case line
    case scatter
}

public struct PolarChart: View {
    public var mode: PolarChartMode
    public var categories: [String]
    public var series: [PolarBarSeries]
    public var points: [PolarScatterSeries]
    public var direction: PolarDirection
    public var unit: String?
    public var ariaLabel: String
    public var themeOverride: ChartTheme?

    @Environment(\.chartTheme) private var environmentTheme
    @Environment(\.chartAccessibility) private var chartAccessibility
    @State private var active: Int = 0
    @FocusState private var focused: Bool

    public init(
        mode: PolarChartMode = .bar, categories: [String] = [], series: [PolarBarSeries] = [],
        points: [PolarScatterSeries] = [], direction: PolarDirection = .clockwise, unit: String? = nil,
        ariaLabel: String = "Polar chart", theme: ChartTheme? = nil
    ) {
        self.mode = mode
        self.categories = categories
        self.series = series
        self.points = points
        self.direction = direction
        self.unit = unit
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.38
            for ring in 1...4 {
                let r = radius * CGFloat(ring) / 4
                var path = Path()
                path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                context.stroke(path, with: .color(chartColor(theme.palette.grid)), lineWidth: 1)
            }
            switch mode {
            case .bar: drawBars(context, center: center, radius: radius, theme: theme)
            case .line: drawLine(context, center: center, radius: radius, theme: theme)
            case .scatter: drawPoints(context, center: center, radius: radius, theme: theme)
            }
            if let unit {
                context.draw(Text(unit).font(chartFont(theme.axis, mono: true)), at: CGPoint(x: center.x, y: center.y - radius - 12))
            }
        }
        .frame(height: 360)
        .focusable()
        .focused($focused)
        .onKeyPress(.rightArrow) { stepPolar(1); return .handled }
        .onKeyPress(.leftArrow) { stepPolar(-1); return .handled }
        .chartAccess(
            chartAccessibility,
            title: ariaLabel,
            summary: ariaLabel,
            samples: categoricalSamples(
                series: series.map { (name: $0.name, values: $0.data.map { Optional($0) }) } + points.map { item in (name: item.name, values: item.data.map { Optional($0.radius) }) },
                categories: categories.isEmpty ? points.flatMap { $0.data.map { formatChartNumber($0.angle) } } : categories,
                formatValue: formatChartNumber
            ),
            categorical: true
        )
        .accessibilityAdjustableAction { direction in
            stepPolar(direction == .increment ? 1 : -1)
        }
        .accessibilityValue(polarValue)
    }

    private func drawBars(_ context: GraphicsContext, center: CGPoint, radius: CGFloat, theme: ChartTheme) {
        let count = max(categories.count, 1)
        let maxValue = series.flatMap(\.data).max() ?? 1
        for (seriesIndex, item) in series.enumerated() {
            for (index, value) in item.data.enumerated() where index < count && value > 0 {
                let angles = wedgeAngles(index: index, count: count, direction: direction)
                let outer = CGFloat(barRadius(value: value, max: maxValue, radius: radius))
                let path = wedge(center: center, inner: 0, outer: outer, start: angles.0, end: angles.1)
                let chosen = index == active
                context.fill(path, with: .color(chartColor(item.color ?? categorical(theme, seriesIndex)).opacity(chosen ? 1 : 0.72)))
                if chosen {
                    context.stroke(path, with: .color(chartColor(theme.palette.text)), lineWidth: 1.5)
                }
            }
        }
    }

    private var slotCount: Int {
        switch mode {
        case .bar, .line:
            return max(categories.count, series.map(\.data.count).max() ?? 0, 1)
        case .scatter:
            return max(points.flatMap(\.data).count, 1)
        }
    }

    private func stepPolar(_ delta: Int) {
        let count = slotCount
        active = min(max(active + delta, 0), count - 1)
    }

    private var polarValue: String {
        if active < categories.count {
            let value = series.first?.data.indices.contains(active) == true ? series[0].data[active] : nil
            let number = value.map { formatChartNumber($0) } ?? ""
            return number.isEmpty ? categories[active] : "\(categories[active]), \(number)"
        }
        return ariaLabel
    }

    private func drawLine(_ context: GraphicsContext, center: CGPoint, radius: CGFloat, theme: ChartTheme) {
        let count = max(categories.count, 1)
        let maxValue = series.flatMap(\.data).max() ?? 1
        for (seriesIndex, item) in series.enumerated() {
            var path = Path()
            for (index, value) in item.data.enumerated() where index < count {
                let angle = wedgeAngles(index: index, count: count, direction: direction).0 + (wedgeAngles(index: index, count: count, direction: direction).1 - wedgeAngles(index: index, count: count, direction: direction).0) / 2
                let r = CGFloat(barRadius(value: max(value, 0), max: maxValue, radius: radius))
                let point = CGPoint(x: center.x + CGFloat(sin(angle)) * r, y: center.y - CGFloat(cos(angle)) * r)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            let color = chartColor(item.color ?? categorical(theme, seriesIndex))
            context.fill(path, with: .color(color.opacity(0.16)))
            context.stroke(path, with: .color(color), lineWidth: 1.5)
        }
    }

    private func drawPoints(_ context: GraphicsContext, center: CGPoint, radius: CGFloat, theme: ChartTheme) {
        let maxRadius = points.flatMap { $0.data.map(\.radius) }.max() ?? 1
        for (seriesIndex, item) in points.enumerated() {
            for point in item.data {
                let angle = direction == .clockwise ? point.angle * .pi / 180 : -point.angle * .pi / 180
                let r = CGFloat(barRadius(value: point.radius, max: maxRadius, radius: radius))
                let spot = CGPoint(x: center.x + CGFloat(sin(angle)) * r, y: center.y - CGFloat(cos(angle)) * r)
                let dot = CGRect(x: spot.x - 4, y: spot.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dot), with: .color(chartColor(item.color ?? categorical(theme, seriesIndex))))
            }
        }
    }
}
