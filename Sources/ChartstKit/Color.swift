import Foundation

public struct RGBA: Equatable, Sendable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

public func parseColor(_ color: String?) -> RGBA? {
    guard let color else { return nil }
    let value = color.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return nil }
    return fromHex(value) ?? fromRGB(value) ?? fromOklch(value)
}

public func formatRGBA(_ color: RGBA) -> String {
    let channels = "\(byte(color.r)), \(byte(color.g)), \(byte(color.b))"
    if color.a >= 1 { return "rgb(\(channels))" }
    return "rgba(\(channels), \(trimNumber(color.a)))"
}

public func withAlpha(_ color: String?, _ alpha: Double) -> String? {
    guard let parsed = parseColor(color) else { return nil }
    return formatRGBA(RGBA(r: parsed.r, g: parsed.g, b: parsed.b, a: alpha))
}

/// sRGB form of a colour. A six-digit hex with full opacity stays hex.
public func toSRGB(_ color: String) -> String? {
    guard let parsed = parseColor(color) else { return nil }
    let trimmed = color.trimmingCharacters(in: .whitespacesAndNewlines)
    if parsed.a >= 1, trimmed.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil {
        return trimmed
    }
    return formatRGBA(parsed)
}

func byte(_ value: Double) -> Int {
    Int(max(0, min(255, value.rounded())))
}

private func trimNumber(_ value: Double) -> String {
    if value == value.rounded() { return String(Int(value)) }
    var text = String(format: "%.6f", value)
    while text.last == "0" { text.removeLast() }
    if text.last == "." { text.removeLast() }
    return text
}

private func clamp01(_ value: Double) -> Double {
    max(0, min(1, value))
}

private func channel(_ raw: String) -> Double? {
    let percent = raw.hasSuffix("%")
    let number = percent ? String(raw.dropLast()) : raw
    guard let value = Double(number), value.isFinite else { return nil }
    return percent ? (value / 100) * 255 : value
}

private func alphaOf(_ raw: String?) -> Double {
    guard let raw else { return 1 }
    let percent = raw.hasSuffix("%")
    let number = percent ? String(raw.dropLast()) : raw
    guard let value = Double(number), value.isFinite else { return 1 }
    return clamp01(percent ? value / 100 : value)
}

private func fromHex(_ input: String) -> RGBA? {
    guard let match = input.range(of: "^#([0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$", options: .regularExpression) else {
        return nil
    }
    let hex = String(input[input.index(input.startIndex, offsetBy: 1)..<input.endIndex])
    let full: String
    if hex.count <= 4 {
        full = hex.map { "\($0)\($0)" }.joined()
    } else {
        full = hex
    }
    func at(_ index: Int) -> Double {
        let start = full.index(full.startIndex, offsetBy: index)
        let end = full.index(start, offsetBy: 2)
        return Double(Int(full[start..<end], radix: 16) ?? 0)
    }
    return RGBA(r: at(0), g: at(2), b: at(4), a: full.count == 8 ? at(6) / 255 : 1)
}

private func fromRGB(_ input: String) -> RGBA? {
    let pattern = #"^rgba?\(\s*([0-9.]+%?)\s*[,\s]\s*([0-9.]+%?)\s*[,\s]\s*([0-9.]+%?)(?:\s*[,/]\s*([0-9.]+%?))?\s*\)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
    let range = NSRange(input.startIndex..<input.endIndex, in: input)
    guard let match = regex.firstMatch(in: input, range: range) else { return nil }
    func group(_ index: Int) -> String? {
        let part = match.range(at: index)
        guard part.location != NSNotFound, let span = Range(part, in: input) else { return nil }
        return String(input[span])
    }
    guard let r = group(1).flatMap(channel),
          let g = group(2).flatMap(channel),
          let b = group(3).flatMap(channel) else { return nil }
    return RGBA(r: r, g: g, b: b, a: alphaOf(group(4)))
}

private func linearToSRGB(_ value: Double) -> Double {
    let clamped = clamp01(value)
    let encoded = clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * pow(clamped, 1 / 2.4) - 0.055
    return Double(byte(encoded * 255))
}

private func fromOklch(_ input: String) -> RGBA? {
    let pattern = #"^oklch\(\s*([0-9.]+%?|none)\s+([0-9.]+%?|none)\s+([0-9.]+(?:deg)?|none)(?:\s*/\s*([0-9.]+%?))?\s*\)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
    let range = NSRange(input.startIndex..<input.endIndex, in: input)
    guard let match = regex.firstMatch(in: input, range: range) else { return nil }
    func group(_ index: Int) -> String? {
        let part = match.range(at: index)
        guard part.location != NSNotFound, let span = Range(part, in: input) else { return nil }
        return String(input[span])
    }
    func unit(_ raw: String) -> Double {
        if raw.lowercased() == "none" { return 0 }
        if raw.hasSuffix("%") { return (Double(raw.dropLast()) ?? .nan) / 100 }
        return Double(raw) ?? .nan
    }
    guard let lRaw = group(1), let cRaw = group(2), let hRaw = group(3) else { return nil }
    let lightness = unit(lRaw)
    let chroma = unit(cRaw)
    let hue = unit(hRaw.replacingOccurrences(of: "deg", with: "", options: .caseInsensitive)) * .pi / 180
    guard [lightness, chroma, hue].allSatisfy(\.isFinite) else { return nil }
    let a = chroma * cos(hue)
    let b = chroma * sin(hue)
    let l_ = lightness + 0.3963377774 * a + 0.2158037573 * b
    let m_ = lightness - 0.1055613458 * a - 0.0638541728 * b
    let s_ = lightness - 0.0894841775 * a - 1.291485548 * b
    let l = l_ * l_ * l_
    let m = m_ * m_ * m_
    let s = s_ * s_ * s_
    return RGBA(
        r: linearToSRGB(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
        g: linearToSRGB(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
        b: linearToSRGB(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s),
        a: alphaOf(group(4))
    )
}
