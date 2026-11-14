import Foundation

/// A chart time. A number above `1e11` in absolute value is milliseconds.
/// A text value is an ISO date, a numeric string, or a category label.
public enum ChartTime: Hashable, Sendable {
    case number(Double)
    case text(String)
    case date(Date)

    public init(_ value: Double) { self = .number(value) }
    public init(_ value: Int) { self = .number(Double(value)) }
    public init(_ value: String) { self = .text(value) }
    public init(_ value: Date) { self = .date(value) }

    public static func unix(_ seconds: Int) -> ChartTime { .number(Double(seconds)) }
}

public let ordinalStep = 86_400
private let millisecondThreshold = 1e11

public func toUnixSeconds(_ time: ChartTime) -> Int? {
    let value: Double
    let isMilliseconds: Bool
    switch time {
    case let .date(date):
        value = date.timeIntervalSince1970 * 1000
        isMilliseconds = true
    case let .text(raw):
        if let parsed = parseDate(raw) {
            value = parsed.timeIntervalSince1970 * 1000
            isMilliseconds = true
        } else {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let number = Double(trimmed), number.isFinite else { return nil }
            value = number
            isMilliseconds = abs(number) > millisecondThreshold
        }
    case let .number(number):
        value = number
        isMilliseconds = abs(number) > millisecondThreshold
    }
    guard value.isFinite else { return nil }
    return Int(floor(isMilliseconds ? value / 1000 : value))
}

public func ordinalIndex(_ time: ChartTime, categories: [String]) -> Int? {
    switch time {
    case let .number(value):
        guard value.isFinite, value.rounded() == value else { return nil }
        let index = Int(value)
        return index >= 0 && index < categories.count ? index : nil
    case let .text(label):
        let index = categories.firstIndex(of: label)
        return index
    case .date:
        return nil
    }
}

public func ordinalTime(_ time: ChartTime, categories: [String]) -> Int? {
    guard let index = ordinalIndex(time, categories: categories) else { return nil }
    return index * ordinalStep
}

public func ordinalLabel(_ time: Int, categories: [String]) -> String {
    let index = Int((Double(time) / Double(ordinalStep)).rounded())
    guard categories.indices.contains(index) else { return "" }
    return categories[index]
}

public func seriesTime(_ time: ChartTime, categories: [String]?) -> Int? {
    if let categories { return ordinalTime(time, categories: categories) }
    return toUnixSeconds(time)
}

public func defaultTimeLabel(unix seconds: Int, timeVisible: Bool = false) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    let day = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    guard timeVisible else { return day }
    return String(format: "%@ %02d:%02d", day, parts.hour ?? 0, parts.minute ?? 0)
}

public enum RangePreset: String, CaseIterable, Sendable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case yearToDate = "YTD"
    case oneYear = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case all = "All"
}

public struct TimeWindow: Equatable, Sendable {
    public var from: Int
    public var to: Int
    public init(from: Int, to: Int) {
        self.from = from
        self.to = to
    }
}

public func presetRange(first: Int, last: Int, preset: RangePreset) -> TimeWindow? {
    guard let from = presetStart(preset, last: last) else { return nil }
    if from <= first { return nil }
    return TimeWindow(from: from, to: last)
}

private func presetStart(_ preset: RangePreset, last: Int) -> Int? {
    let day = 86_400
    switch preset {
    case .oneDay: return last - day
    case .oneWeek: return last - 7 * day
    case .oneMonth: return monthsBefore(last, months: 1)
    case .threeMonths: return monthsBefore(last, months: 3)
    case .oneYear: return monthsBefore(last, months: 12)
    case .threeYears: return monthsBefore(last, months: 36)
    case .fiveYears: return monthsBefore(last, months: 60)
    case .yearToDate:
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let year = calendar.component(.year, from: Date(timeIntervalSince1970: TimeInterval(last)))
        var parts = DateComponents()
        parts.year = year
        parts.month = 1
        parts.day = 1
        parts.timeZone = TimeZone(secondsFromGMT: 0)
        return Int(calendar.date(from: parts)?.timeIntervalSince1970 ?? 0)
    case .all:
        return nil
    }
}

func monthsBefore(_ seconds: Int, months: Int) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    var first = DateComponents()
    first.year = parts.year
    first.month = parts.month
    first.day = 1
    first.timeZone = TimeZone(secondsFromGMT: 0)
    let monthStart = calendar.date(from: first) ?? date
    let shifted = calendar.date(byAdding: .month, value: -months, to: monthStart) ?? monthStart
    let length = calendar.range(of: .day, in: .month, for: shifted)?.count ?? 28
    let day = min(parts.day ?? 1, length)
    var final = calendar.dateComponents([.year, .month], from: shifted)
    final.day = day
    final.hour = parts.hour
    final.minute = parts.minute
    final.second = parts.second
    final.timeZone = TimeZone(secondsFromGMT: 0)
    return Int(calendar.date(from: final)?.timeIntervalSince1970 ?? Double(seconds))
}

private func parseDate(_ raw: String) -> Date? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return nil }
    if trimmed.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: trimmed)
    }
    let internet = ISO8601DateFormatter()
    internet.formatOptions = [.withInternetDateTime]
    if let date = internet.date(from: trimmed) { return date }
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: trimmed) { return date }
    if trimmed.contains("T"), !trimmed.contains("Z"), trimmed.range(of: #"[+-]\d{2}:?\d{2}$"#, options: .regularExpression) == nil {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = trimmed.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: trimmed)
    }
    return nil
}
