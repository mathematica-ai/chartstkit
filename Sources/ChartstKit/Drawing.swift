import SwiftUI

func chartColor(_ raw: String?, fallback: Color = .clear) -> Color {
    guard let raw, let parsed = parseColor(raw) else { return fallback }
    return chartColor(parsed)
}

func chartColor(_ parsed: RGBA) -> Color {
    Color(.sRGB, red: parsed.r / 255, green: parsed.g / 255, blue: parsed.b / 255, opacity: parsed.a)
}

func chartFont(_ text: ChartTheme.TextStyle, mono: Bool) -> Font {
    let size = text.size ?? (mono ? 11 : 14)
    let weight: Font.Weight
    switch text.weight ?? 400 {
    case 600...: weight = .semibold
    case 500...: weight = .medium
    default: weight = .regular
    }
    return .system(size: size, weight: weight, design: mono ? .monospaced : .default)
}

func dashPattern(_ style: ChartTheme.Dash, width: CGFloat = 1) -> [CGFloat] {
    switch style {
    case .solid: return []
    case .dashed: return [4 * width, 3 * width]
    case .dotted: return [width, 2 * width]
    }
}

func formatChartNumber(_ value: Double) -> String {
    guard value.isFinite else { return "" }
    if abs(value) < 1e15, value.rounded() == value { return String(Int(value)) }
    return String(format: "%g", value)
}

func formatShare(_ share: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 1
    return formatter.string(from: NSNumber(value: share)) ?? formatChartNumber(share * 100) + "%"
}

func clipLabel(_ text: String, max: Int = 20) -> String {
    guard text.count > max else { return text }
    return String(text.prefix(max - 1)) + "…"
}

struct TooltipBox: View {
    var title: String
    var rows: [(label: String, value: String, color: Color)]
    var theme: ChartTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(chartFont(theme.axis, mono: true)).foregroundStyle(chartColor(theme.palette.text))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1).fill(row.color).frame(width: 8, height: 8)
                    Text(row.label).font(chartFont(theme.axis, mono: true))
                    Text(row.value).font(chartFont(theme.value, mono: true))
                }
                .foregroundStyle(chartColor(theme.palette.text))
            }
        }
        .padding(8)
        .background(chartColor(theme.palette.background), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(chartColor(theme.palette.grid), lineWidth: 1))
    }
}

func hatch(in rect: CGRect, color: Color, spacing: CGFloat = 6, width: CGFloat = 1) -> some View {
    Canvas { context, _ in
        var path = Path()
        var offset: CGFloat = 0
        while offset < rect.width + rect.height {
            path.move(to: CGPoint(x: offset - rect.height, y: rect.height))
            path.addLine(to: CGPoint(x: offset, y: 0))
            offset += spacing
        }
        context.stroke(path, with: .color(color), lineWidth: width)
    }
    .frame(width: rect.width, height: rect.height)
    .clipShape(Rectangle())
}
