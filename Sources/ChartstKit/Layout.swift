import Foundation

public enum ChartMathError: Error, Equatable, Sendable {
    case negativeValue(name: String, index: Int, value: Double)
    case invalidQuantize(String)
    case bucketSize
    case notATree
}

public struct ChartRect: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct PieArc: Equatable, Sendable {
    public var index: Int
    public var value: Double
    public var share: Double
    public var startAngle: Double
    public var endAngle: Double
    public var midAngle: Double
}

public enum QuantizeScale: String, Sendable {
    case equal
    case quantile
}

public struct Quantizer: Sendable {
    public var thresholds: [Double]
    public var step: @Sendable (Double) -> Int
}

public final class TreeNode {
    public var children: [TreeNode]
    public init(children: [TreeNode] = []) { self.children = children }
}

public struct TreeLayoutNode: Equatable, Sendable {
    public var depth: Int
    public var breadth: Double
}

public struct TreeLayout: Equatable, Sendable {
    public var nodes: [TreeLayoutNode]
    public var levels: Int
    public var leaves: Int
}

public func sum(_ values: [Double]) -> Double {
    values.reduce(0, +)
}

public func extent(_ values: [Double]) -> (min: Double, max: Double) {
    values.reduce((min: Double.infinity, max: -Double.infinity)) { partial, value in
        (min: min(partial.min, value), max: max(partial.max, value))
    }
}

public func symmetricExtent(_ values: [Double]) -> (min: Double, max: Double) {
    let maxAbs = values.reduce(0) { partial, value in
        value.isFinite ? max(partial, abs(value)) : partial
    }
    return maxAbs == 0 ? (0, 0) : (-maxAbs, maxAbs)
}

public func pieArcs(_ values: [Double]) throws -> [PieArc] {
    try assertNonNegative("pieArcs", values)
    let total = sum(values)
    var angle = 0.0
    return values.enumerated().map { index, value in
        let share = total > 0 ? value / total : 0
        let start = angle
        angle += share * (2 * .pi)
        return PieArc(
            index: index,
            value: value,
            share: share,
            startAngle: start,
            endAngle: angle,
            midAngle: (start + angle) / 2
        )
    }
}

public func quantize(
    _ values: [Double],
    count: Int = 5,
    thresholds: [Double]? = nil,
    scale: QuantizeScale = .equal
) throws -> Quantizer {
    if let thresholds, thresholds.contains(where: { !$0.isFinite }) {
        throw ChartMathError.invalidQuantize("thresholds must be finite numbers")
    }
    if thresholds == nil, count < 1 {
        throw ChartMathError.invalidQuantize("count must be an integer >= 1, got \(count)")
    }
    let finite = values.filter(\.isFinite)
    let ends = extent(finite)
    let flat = thresholds == nil && !(ends.max > ends.min)
    let cuts: [Double]
    if let thresholds {
        cuts = thresholds.sorted()
    } else if flat {
        cuts = []
    } else if scale == .quantile {
        cuts = quantileCuts(finite, count: count)
    } else {
        cuts = (1..<count).map { index in
            ends.min + ((ends.max - ends.min) * Double(index)) / Double(count)
        }
    }
    return Quantizer(thresholds: cuts) { value in
        if !value.isFinite { return -1 }
        if flat { return count / 2 }
        var index = 0
        while index < cuts.count, value >= cuts[index] { index += 1 }
        return index
    }
}

public func tidyTree(_ root: TreeNode) throws -> TreeLayout {
    var nodes: [TreeLayoutNode] = []
    var seen = Set<ObjectIdentifier>()
    var leaves = 0
    var levels = 0

    func visit(_ node: TreeNode, depth: Int) throws -> Double {
        if !seen.insert(ObjectIdentifier(node)).inserted { throw ChartMathError.notATree }
        let slot = nodes.count
        nodes.append(TreeLayoutNode(depth: depth, breadth: 0))
        levels = max(levels, depth + 1)
        let childBreadths = try node.children.map { try visit($0, depth: depth + 1) }
        let breadth: Double
        if let first = childBreadths.first, let last = childBreadths.last {
            breadth = (first + last) / 2
        } else {
            breadth = Double(leaves)
            leaves += 1
        }
        nodes[slot].breadth = breadth
        return breadth
    }

    _ = try visit(root, depth: 0)
    return TreeLayout(nodes: nodes, levels: levels, leaves: leaves)
}

public func squarify(_ values: [Double], in rect: ChartRect) throws -> [ChartRect] {
    try assertNonNegative("squarify", values)
    var out = values.map { _ in ChartRect(x: rect.x, y: rect.y, width: 0, height: 0) }
    let total = sum(values)
    let area = max(0, rect.width) * max(0, rect.height)
    if total == 0 || area == 0 { return out }
    let areas = values.map { $0 * area / total }
    let order = areas.indices
        .filter { areas[$0] > 0 }
        .sorted { areas[$0] == areas[$1] ? $0 < $1 : areas[$0] > areas[$1] }
    var free = rect
    var row: [Int] = []
    for index in order {
        let side = min(free.width, free.height)
        let next = row + [index]
        if row.isEmpty || worst(next.map { areas[$0] }, side: side) <= worst(row.map { areas[$0] }, side: side) {
            row = next
        } else {
            free = placeRow(row, areas: areas, free: free, out: &out)
            row = [index]
        }
    }
    if !row.isEmpty { _ = placeRow(row, areas: areas, free: free, out: &out) }
    return out
}

func assertNonNegative(_ name: String, _ values: [Double]) throws {
    for (index, value) in values.enumerated() where !value.isFinite || value < 0 {
        throw ChartMathError.negativeValue(name: name, index: index, value: value)
    }
}

private func quantileCuts(_ values: [Double], count: Int) -> [Double] {
    let sorted = values.sorted()
    guard let first = sorted.first else { return [] }
    var cuts: [Double] = []
    if count > 1 {
        for index in 1..<count {
            cuts.append(sorted[(index * sorted.count) / count])
        }
    }
    return cuts.enumerated().compactMap { index, cut in
        cut > first && (index == 0 || cut != cuts[index - 1]) ? cut : nil
    }
}

private func worst(_ areas: [Double], side: Double) -> Double {
    let total = sum(areas)
    let ends = extent(areas)
    let side2 = side * side
    let total2 = total * total
    return max((side2 * ends.max) / total2, total2 / (side2 * ends.min))
}

private func placeRow(_ row: [Int], areas: [Double], free: ChartRect, out: inout [ChartRect]) -> ChartRect {
    let total = sum(row.map { areas[$0] })
    let vertical = free.width >= free.height
    let thickness = total / (vertical ? free.height : free.width)
    var offset = 0.0
    for index in row {
        let length = areas[index] / thickness
        out[index] = vertical
            ? ChartRect(x: free.x, y: free.y + offset, width: thickness, height: length)
            : ChartRect(x: free.x + offset, y: free.y, width: length, height: thickness)
        offset += length
    }
    if vertical {
        return ChartRect(x: free.x + thickness, y: free.y, width: max(0, free.width - thickness), height: free.height)
    }
    return ChartRect(x: free.x, y: free.y + thickness, width: free.width, height: max(0, free.height - thickness))
}
