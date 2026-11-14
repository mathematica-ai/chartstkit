import SwiftUI

public struct Sparkline: View {
    public var data: [Double?]
    public var width: CGFloat
    public var height: CGFloat
    public var color: String?
    public var area: Bool
    public var ariaLabel: String

    @Environment(\.chartTheme) private var environmentTheme
    @Environment(\.chartAccessibility) private var chartAccessibility

    public init(data: [Double?], width: CGFloat = 80, height: CGFloat = 22, color: String? = nil, area: Bool = false, ariaLabel: String = "Sparkline") {
        self.data = data
        self.width = width
        self.height = height
        self.color = color
        self.area = area
        self.ariaLabel = ariaLabel
    }

    public var body: some View {
        let theme = environmentTheme
        let runs = sparklineRuns(data.map { SparklineDatum.number($0) }, width: width, height: height)
        let stroke = chartColor(color, fallback: chartColor(theme.palette.text, fallback: .primary))
        Canvas { context, _ in
            if area, let baseline = runs.flatMap(\.self).map(\.y).max() {
                for run in runs {
                    guard let first = run.first, let last = run.last else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x: first.x, y: first.y))
                    for point in run.dropFirst() { path.addLine(to: CGPoint(x: point.x, y: point.y)) }
                    path.addLine(to: CGPoint(x: last.x, y: baseline))
                    path.addLine(to: CGPoint(x: first.x, y: baseline))
                    path.closeSubpath()
                    context.fill(path, with: .color(stroke.opacity(0.12)))
                }
            }
            for run in runs {
                var path = Path()
                guard let first = run.first else { continue }
                path.move(to: CGPoint(x: first.x, y: first.y))
                for point in run.dropFirst() { path.addLine(to: CGPoint(x: point.x, y: point.y)) }
                context.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: width, height: height)
        .chartAccess(chartAccessibility, title: ariaLabel, summary: ariaLabel, samples: sparklineSamples(data), categorical: false)
    }
}

public struct PieChart: View {
    public var data: [PieDatum]
    public var innerRadius: Double
    public var maxSlices: Int
    public var otherLabel: String
    public var unit: String?
    public var emphasis: PieEmphasis
    public var selectionMode: PieSelectionMode
    public var drillOther: Bool
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var unstyled: Bool
    public var onSelectionChange: (([String]) -> Void)?

    @Environment(\.chartTheme) private var environmentTheme
    @Environment(\.chartAccessibility) private var chartAccessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state: PieChartState
    @State private var tooltip: String?
    @FocusState private var focused: Bool

    public init(
        data: [PieDatum],
        innerRadius: Double = 0,
        maxSlices: Int = .max,
        otherLabel: String = "Other",
        unit: String? = nil,
        emphasis: PieEmphasis = .dim,
        selectionMode: PieSelectionMode = .none,
        drillOther: Bool = false,
        ariaLabel: String = "Pie chart",
        theme: ChartTheme? = nil,
        unstyled: Bool = false,
        onSelectionChange: (([String]) -> Void)? = nil
    ) {
        self.data = data
        self.innerRadius = min(0.95, max(0, innerRadius))
        self.maxSlices = maxSlices
        self.otherLabel = otherLabel
        self.unit = unit
        self.emphasis = emphasis
        self.selectionMode = selectionMode
        self.drillOther = drillOther
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.unstyled = unstyled
        self.onSelectionChange = onSelectionChange
        _state = State(initialValue: PieChartState(data: data, maxSlices: maxSlices, otherLabel: otherLabel, selectionMode: selectionMode, drillOther: drillOther))
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let slices = state.slices.filter { !$0.hidden }
        let total = slices.reduce(0) { $0 + $1.value }
        VStack(alignment: .leading, spacing: 12) {
            if state.drilled {
                Button("Back") { state.back() }
                    .font(chartFont(theme.label, mono: true))
            }
            GeometryReader { geo in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let outer = min(size.width, size.height) * 0.34
                    let inner = outer * innerRadius
                    for slice in slices {
                        let path = wedge(center: center, inner: inner, outer: outer, start: slice.startAngle, end: slice.endAngle)
                        let fill = unstyled ? Color.primary : chartColor(slice.color ?? categorical(theme, slice.index), fallback: .primary)
                        let dimmed = emphasis == .dim && state.activeKey != nil && state.activeKey != slice.key
                        context.fill(path, with: .color(dimmed ? fill.opacity(theme.pie.dimOpacity) : fill))
                        if slice.selected {
                            context.stroke(path, with: .color(chartColor(theme.pie.selectionColor)), lineWidth: theme.pie.selectionWidth)
                        }
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { value in
                    guard let slice = hit(value.location, size: geo.size) else { return }
                    state.activate(slice.key)
                    tooltip = "\(slice.label) \(formatShare(slice.share))"
                })
                .gesture(SpatialTapGesture().onEnded { value in
                    guard let slice = hit(value.location, size: geo.size) else { return }
                    state.activate(slice.key)
                    state.click(slice.key)
                    tooltip = "\(slice.label) \(formatShare(slice.share))"
                    onSelectionChange?(state.selectedKeys)
                })
            }
            .frame(height: 280)
            .overlay(alignment: .center) {
                if innerRadius > 0 {
                    VStack(spacing: 2) {
                        Text(formatChartNumber(total)).font(chartFont(theme.pie.center, mono: true))
                        if let unit { Text(unit).font(chartFont(theme.pie.centerUnit, mono: true)) }
                    }
                    .foregroundStyle(chartColor(theme.palette.text))
                }
            }
            .overlay(alignment: .topLeading) {
                if let tooltip {
                    Text(tooltip).font(chartFont(theme.axis, mono: true)).padding(6)
                        .background(chartColor(theme.palette.background), in: RoundedRectangle(cornerRadius: 4))
                }
            }
            .focusable()
            .focused($focused)
            .onKeyPress(.leftArrow) { state.move(by: -1); return .handled }
            .onKeyPress(.rightArrow) { state.move(by: 1); return .handled }
            .onKeyPress(.return) { selectFocused(); return .handled }
            .onKeyPress(.space) { selectFocused(); return .handled }
            .onKeyPress(.escape) {
                if !state.selectedKeys.isEmpty { state.clearSelection() }
                else { state.back() }
                return .handled
            }
            legend(theme, slices: state.slices)
        }
        .accessibilityElement(children: .contain)
        .chartAccess(
            chartAccessibility,
            title: ariaLabel,
            summary: ariaLabel,
            samples: pieSeriesSamples(slices: state.slices.filter { !$0.hidden }.map { (label: $0.label, share: $0.share) }),
            categorical: true
        )
        .accessibilityAdjustableAction { direction in
            state.move(by: direction == .increment ? 1 : -1)
        }
        .onChange(of: data) { _, newValue in
            state = PieChartState(data: newValue, maxSlices: maxSlices, otherLabel: otherLabel, selectionMode: selectionMode, drillOther: drillOther)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: state.slices.map(\.midAngle))
    }

    private func selectFocused() {
        guard let key = state.activeKey ?? state.visible.first?.key else { return }
        state.click(key)
        onSelectionChange?(state.selectedKeys)
    }

    private func legend(_ theme: ChartTheme, slices: [PieSlice]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(slices, id: \.key) { slice in
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(chartColor(slice.color ?? categorical(theme, slice.index)))
                        .frame(width: 10, height: 10)
                        .opacity(slice.hidden ? 0.35 : 1)
                    Text(slice.label).font(chartFont(theme.label, mono: true))
                    Spacer()
                    Text(formatShare(slice.shareOfAll)).font(chartFont(theme.value, mono: true))
                }
                .contentShape(Rectangle())
                .onTapGesture { state.hide(slice.key); onSelectionChange?(state.selectedKeys) }
                .simultaneousGesture(LongPressGesture().onEnded { _ in state.hide(slice.key, only: true) })
                .foregroundStyle(chartColor(theme.palette.text))
            }
        }
    }

    private func hit(_ point: CGPoint, size: CGSize) -> PieSlice? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let outer = min(size.width, size.height) * 0.34
        let distance = hypot(dx, dy)
        if distance > outer || distance < outer * innerRadius { return nil }
        var angle = atan2(dx, -dy)
        if angle < 0 { angle += 2 * .pi }
        return state.visible.first { slice in
            let end = slice.endAngle >= 2 * .pi - 1e-6 ? 2 * .pi + 0.001 : slice.endAngle
            return angle >= slice.startAngle && angle < end
        }
    }
}

public struct Heatmap: View {
    public var rows: [String]
    public var columns: [String]
    public var values: [[Double?]]
    public var steps: Int
    public var thresholds: [Double]?
    public var scale: QuantizeScale
    public var unit: String?
    public var emphasis: HeatmapEmphasis
    public var selectionMode: HeatmapSelectionMode
    public var markExtreme: String?
    public var showValues: Bool
    public var ariaLabel: String
    public var themeOverride: ChartTheme?
    public var unstyled: Bool
    public var onSelectionChange: ((HeatmapRange?, Int, Double?) -> Void)?

    @Environment(\.chartTheme) private var environmentTheme
    @Environment(\.chartAccessibility) private var chartAccessibility
    @State private var active: HeatmapPosition?
    @State private var selection: HeatmapRange?
    @State private var anchor: HeatmapPosition?
    @State private var hiddenSteps: [Int] = []
    @FocusState private var focused: Bool

    public init(
        rows: [String], columns: [String], values: [[Double?]], steps: Int = 5, thresholds: [Double]? = nil,
        scale: QuantizeScale = .equal, unit: String? = nil, emphasis: HeatmapEmphasis = .crosshair,
        selectionMode: HeatmapSelectionMode = .none, markExtreme: String? = nil, showValues: Bool = false,
        ariaLabel: String = "Heatmap", theme: ChartTheme? = nil, unstyled: Bool = false,
        onSelectionChange: ((HeatmapRange?, Int, Double?) -> Void)? = nil
    ) {
        self.rows = rows
        self.columns = columns
        self.values = values
        self.steps = steps
        self.thresholds = thresholds
        self.scale = scale
        self.unit = unit
        self.emphasis = emphasis
        self.selectionMode = selectionMode
        self.markExtreme = markExtreme
        self.showValues = showValues
        self.ariaLabel = ariaLabel
        self.themeOverride = theme
        self.unstyled = unstyled
        self.onSelectionChange = onSelectionChange
    }

    public var body: some View {
        let theme = themeOverride ?? environmentTheme
        let built = (try? heatmapGrid(rows: rows, columns: columns, value: { _, _, r, c in
            guard values.indices.contains(r), values[r].indices.contains(c) else { return nil }
            return values[r][c]
        }, count: steps, thresholds: thresholds, scale: scale))
        let grid = built?.grid ?? []
        let cuts = built?.thresholds ?? []
        let layout = heatmapLayout(rows: rows.count, cols: columns.count, gap: theme.heatmap.gap)
        let stepCount = max(cuts.count + 1, 1)
        ScrollView([.horizontal, .vertical]) {
            Canvas { context, _ in
                for cells in grid {
                    for cell in cells {
                        let box = layout.cell(cell.r, cell.c, gap: theme.heatmap.gap)
                        let rect = CGRect(x: box.x, y: box.y, width: box.size, height: box.size)
                        let missing = cell.value == nil
                        let color = stepColor(step: cell.step, count: stepCount, palette: theme.palette.sequential)
                        let filtered = hiddenSteps.contains(cell.step)
                        let dimmed = isDimmed(emphasis: emphasis, active: active, range: selection, r: cell.r, c: cell.c)
                        if missing || unstyled {
                            context.fill(Path(rect), with: .color(chartColor(theme.heatmap.missingFill)))
                            strokeHatch(context, rect: rect, color: chartColor(theme.heatmap.missingHatch))
                        } else {
                            var fill = chartColor(color, fallback: .gray)
                            if filtered { fill = fill.opacity(theme.heatmap.filteredOpacity) }
                            else if dimmed { fill = fill.opacity(theme.heatmap.dimOpacity) }
                            context.fill(Path(rect), with: .color(fill))
                        }
                        if inRange(selection, cell.r, cell.c) {
                            context.stroke(Path(rect), with: .color(chartColor(theme.heatmap.selectionColor)), lineWidth: 2)
                        }
                        if showValues, let value = cell.value, box.size >= 18 {
                            context.draw(Text(formatChartNumber(value)).font(.system(size: 9, design: .monospaced)), at: CGPoint(x: rect.midX, y: rect.midY))
                        }
                    }
                }
            }
            .frame(width: layout.width, height: layout.height)
            .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { value in
                guard let pos = cellAt(layout, x: value.location.x, y: value.location.y, clamp: selectionMode == .range) else { return }
                active = pos
                if selectionMode == .range, let anchor {
                    selection = normaliseRange(anchor, pos)
                }
            }.onEnded { value in
                guard selectionMode == .range, let pos = cellAt(layout, x: value.location.x, y: value.location.y) else { return }
                commit(pos)
            })
            .simultaneousGesture(SpatialTapGesture().onEnded { value in
                guard let pos = cellAt(layout, x: value.location.x, y: value.location.y) else { return }
                active = pos
                commit(pos)
            })
        }
        .focusable()
        .focused($focused)
        .onKeyPress(.leftArrow) { nudge(0, -1); return .handled }
        .onKeyPress(.rightArrow) { nudge(0, 1); return .handled }
        .onKeyPress(.upArrow) { nudge(-1, 0); return .handled }
        .onKeyPress(.downArrow) { nudge(1, 0); return .handled }
        .onKeyPress(.escape) { selection = nil; anchor = nil; publish(); return .handled }
        .onKeyPress(.return) { if let active { commit(active) }; return .handled }
        .chartAccess(
            chartAccessibility,
            title: ariaLabel,
            summary: ariaLabel,
            samples: heatmapSeriesSamples(rows: rows, columns: columns, values: values, formatValue: formatChartNumber),
            categorical: true
        )
        .accessibilityAdjustableAction { direction in
            nudge(0, direction == .increment ? 1 : -1)
        }
        .overlay(alignment: .bottomLeading) { legend(theme, cuts: cuts, stepCount: stepCount) }
    }

    private func commit(_ pos: HeatmapPosition) {
        guard selectionMode != .none else { return }
        let next = selectionMode == .range ? normaliseRange(anchor ?? pos, pos) : normaliseRange(pos, pos)
        if next == selection { selection = nil; anchor = nil }
        else { selection = next; anchor = pos }
        publish()
    }

    private func publish() {
        guard let selection else { onSelectionChange?(nil, 0, nil); return }
        let built = try? heatmapGrid(rows: rows, columns: columns, value: { _, _, r, c in
            values.indices.contains(r) && values[r].indices.contains(c) ? values[r][c] : nil
        }, count: steps, thresholds: thresholds, scale: scale)
        let stats = built.map { rangeStats($0.grid, range: selection, hiddenSteps: hiddenSteps) }
        onSelectionChange?(selection, stats?.count ?? 0, stats?.mean)
    }

    private func nudge(_ dr: Int, _ dc: Int) {
        let r = min(max((active?.r ?? 0) + dr, 0), max(0, rows.count - 1))
        let c = min(max((active?.c ?? 0) + dc, 0), max(0, columns.count - 1))
        active = HeatmapPosition(r: r, c: c)
    }

    private func legend(_ theme: ChartTheme, cuts: [Double], stepCount: Int) -> some View {
        HStack(spacing: 8) {
            if let unit { Text(unit).font(chartFont(theme.axis, mono: true)) }
            ForEach(1...stepCount, id: \.self) { step in
                let hidden = hiddenSteps.contains(step)
                Button {
                    hiddenSteps = hideKeys((1...stepCount).map(String.init), hidden: hiddenSteps.map(String.init), key: String(step)).compactMap(Int.init)
                } label: {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(chartColor(stepColor(step: step, count: stepCount, palette: theme.palette.sequential))).frame(width: 12, height: 12)
                        Text(stepLabel(step, cuts: cuts)).font(chartFont(theme.axis, mono: true))
                    }
                    .opacity(hidden ? 0.35 : 1)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(chartColor(theme.palette.text))
        .padding(.top, 8)
    }

    private func stepLabel(_ step: Int, cuts: [Double]) -> String {
        if cuts.isEmpty { return "all" }
        if step <= 1 { return "≤ \(formatChartNumber(cuts[0]))" }
        if step > cuts.count { return "≥ \(formatChartNumber(cuts[cuts.count - 1]))" }
        return "\(formatChartNumber(cuts[step - 2]))–\(formatChartNumber(cuts[step - 1]))"
    }
}

func categorical(_ theme: ChartTheme, _ index: Int) -> String {
    let colors = theme.palette.categorical
    guard !colors.isEmpty else { return theme.palette.neutral }
    return colors[index % colors.count]
}

func wedge(center: CGPoint, inner: CGFloat, outer: CGFloat, start: Double, end: Double) -> Path {
    var path = Path()
    let span = end - start
    if span >= 2 * .pi - 1e-6 {
        path.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
        if inner > 0 {
            path.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
        }
        return path
    }
    func point(_ angle: Double, _ radius: CGFloat) -> CGPoint {
        CGPoint(x: center.x + CGFloat(sin(angle)) * radius, y: center.y - CGFloat(cos(angle)) * radius)
    }
    path.move(to: point(start, outer))
    path.addArc(center: center, radius: outer, startAngle: .radians(start - .pi / 2), endAngle: .radians(end - .pi / 2), clockwise: false)
    if inner > 0 {
        path.addLine(to: point(end, inner))
        path.addArc(center: center, radius: inner, startAngle: .radians(end - .pi / 2), endAngle: .radians(start - .pi / 2), clockwise: true)
    } else {
        path.addLine(to: center)
    }
    path.closeSubpath()
    return path
}

func strokeHatch(_ context: GraphicsContext, rect: CGRect, color: Color) {
    var path = Path()
    var offset: CGFloat = 0
    while offset < rect.width + rect.height {
        path.move(to: CGPoint(x: rect.minX + offset - rect.height, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + offset, y: rect.minY))
        offset += 6
    }
    context.stroke(path, with: .color(color.opacity(0.7)), lineWidth: 1)
}
