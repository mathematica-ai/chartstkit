import XCTest
@testable import ChartstKit

final class ChartstKitTests: XCTestCase {
    func testUnixSeconds() {
        XCTAssertEqual(toUnixSeconds(.number(1_700_000_000)), 1_700_000_000)
        XCTAssertEqual(toUnixSeconds(.number(1_700_000_000_000)), 1_700_000_000)
        XCTAssertEqual(toUnixSeconds(.text("1700000000")), 1_700_000_000)
        XCTAssertEqual(toUnixSeconds(.text("")), nil)
        XCTAssertEqual(toUnixSeconds(.text("2026-01-02")), 1_767_312_000)
        XCTAssertNil(toUnixSeconds(.text("not-a-time")))
    }

    func testOrdinalAxis() {
        let categories = ["Mon", "Tue"]
        XCTAssertEqual(ordinalTime(.text("Tue"), categories: categories), 86_400)
        XCTAssertEqual(ordinalTime(.number(0), categories: categories), 0)
        XCTAssertNil(ordinalTime(.number(5), categories: categories))
        XCTAssertEqual(ordinalLabel(86_400, categories: categories), "Tue")
    }

    func testPresets() {
        let june15 = Int(DateComponents(calendar: utc, timeZone: utc.timeZone, year: 2026, month: 6, day: 15).date!.timeIntervalSince1970)
        XCTAssertEqual(presetRange(first: 0, last: june15, preset: .oneDay)?.from, june15 - 86_400)
        XCTAssertEqual(presetRange(first: 0, last: june15, preset: .yearToDate)?.from, Int(DateComponents(calendar: utc, timeZone: utc.timeZone, year: 2026, month: 1, day: 1).date!.timeIntervalSince1970))
        XCTAssertNil(presetRange(first: 0, last: june15, preset: .all))
        XCTAssertEqual(monthsBefore(june15, months: 1), Int(DateComponents(calendar: utc, timeZone: utc.timeZone, year: 2026, month: 5, day: 15).date!.timeIntervalSince1970))
        let march31 = Int(DateComponents(calendar: utc, timeZone: utc.timeZone, year: 2026, month: 3, day: 31).date!.timeIntervalSince1970)
        XCTAssertEqual(monthsBefore(march31, months: 1), Int(DateComponents(calendar: utc, timeZone: utc.timeZone, year: 2026, month: 2, day: 28).date!.timeIntervalSince1970))
    }

    func testBinning() {
        XCTAssertEqual(bin([]), [])
        let counts = bin([1, 2, 3, 4], bins: 2)
        XCTAssertEqual(counts.map(\.count), [2, 2])
        XCTAssertEqual(counts.map(\.label), ["1–2.500", "2.500–4"])
        let edges = bin([0, 10, 20], edges: [0, 10, 20])
        XCTAssertEqual(edges.map(\.count), [1, 2])
        XCTAssertEqual(bin([1, 2, 3, 4, 5, 6, 7, 8]).count, 4)
    }

    func testPrecision() {
        XCTAssertEqual(jsToPrecision(0, precision: 4), "0.000")
        XCTAssertEqual(jsToPrecision(12, precision: 4), "12.00")
        XCTAssertEqual(jsToPrecision(1.23456, precision: 4), "1.235")
        XCTAssertEqual(jsToPrecision(123_456, precision: 4), "1.235e+5")
        XCTAssertEqual(jsToPrecision(0.0001234, precision: 4), "0.0001234")
    }

    func testCandlesAndStats() throws {
        XCTAssertTrue(isUp(OHLC(time: .unix(1), open: 1, high: 2, low: 1, close: 2)))
        XCTAssertFalse(isUp(OHLC(time: .unix(1), open: 2, high: 2, low: 1, close: 1)))
        let rows = [
            OHLC(time: .unix(1), open: 1, high: 3, low: 1, close: 2),
            OHLC(time: .unix(2), open: 2, high: 4, low: 0, close: 3),
        ]
        let aggregated = try aggregateCandles(rows, bucketSize: 2)
        XCTAssertEqual(aggregated.count, 1)
        XCTAssertEqual(aggregated[0].open, 1)
        XCTAssertEqual(aggregated[0].high, 4)
        XCTAssertEqual(aggregated[0].low, 0)
        XCTAssertEqual(aggregated[0].close, 3)
        let normalized = normalizeCandles(rows.reversed())
        XCTAssertEqual(normalized.map(\.time), [1, 2])
        let stats = visibleStats(normalized, from: 0, to: 1)
        XCTAssertEqual(stats?.open, 1)
        XCTAssertEqual(stats?.close, 3)
        XCTAssertEqual(stats?.high, 4)
        XCTAssertEqual(stats?.low, 0)
        XCTAssertEqual(stats?.bars, 2)
        XCTAssertEqual(stats?.change, 200)
    }

    func testLiveAndZoom() {
        let before = [PlotRow(time: 1, open: 1, high: 1, low: 1, close: 1)]
        var same = before
        same[0].close = 2
        XCTAssertEqual(tickDirection(previous: before, next: same), .up)
        XCTAssertNil(tickDirection(previous: before, next: before))
        var appended = before
        appended.append(PlotRow(time: 2, open: 1, high: 1, low: 1, close: 0))
        XCTAssertEqual(tickDirection(previous: before, next: appended), .down)
        XCTAssertEqual(nextBucketSize(current: 1, pxPerRawBar: 2, minBarWidth: 6, rawCount: 100), 4)
        let zoomed = zoomRange(LogicalRange(from: 0, to: 10), anchor: 5, delta: 0)
        XCTAssertEqual(zoomed?.from, 0)
        XCTAssertEqual(zoomed?.to, 10)
        XCTAssertNil(zoomRange(LogicalRange(from: 0, to: 2), anchor: 1, delta: -1000))
        XCTAssertNil(zoomRange(LogicalRange(from: 0, to: 100), anchor: 50, delta: .nan))
        XCTAssertNil(zoomRange(LogicalRange(from: 0, to: 100), anchor: 50, delta: 1e9))
        XCTAssertTrue(isLive(nil, lastIndex: 4))
        XCTAssertFalse(isLive(LogicalRange(from: 0, to: 2), lastIndex: 4))
    }

    func testBandsAndHide() {
        let bands = [BandItem(from: .unix(0), to: .unix(10), key: "risk")]
        let hit = bandAt(bands, time: 5, times: [0, 5, 10])
        XCTAssertEqual(hit?.key, "risk")
        XCTAssertEqual(hit?.bars, 2)
        XCTAssertNil(bandAt(bands, time: 10, times: [0, 5, 10]))
        XCTAssertEqual(hideKeys(["a", "b", "c"], hidden: [], key: "a"), ["a"])
        XCTAssertEqual(hideKeys(["a", "b", "c"], hidden: ["a"], key: "a"), [])
        XCTAssertEqual(hideKeys(["a", "b", "c"], hidden: [], key: "b", only: true), ["a", "c"])
        XCTAssertEqual(hideKeys(["a"], hidden: [], key: "a"), [])
    }

    func testColorsAndTheme() {
        XCTAssertEqual(toSRGB("#ce5a3a"), "#ce5a3a")
        XCTAssertEqual(toSRGB("#fff"), "rgb(255, 255, 255)")
        XCTAssertEqual(withAlpha("#000000", 0.5), "rgba(0, 0, 0, 0.5)")
        XCTAssertEqual(p1Theme(.dark).palette.up, "#d4d0cb")
        XCTAssertEqual(p1Theme(.dark).palette.down, "#ce5a3a")
        XCTAssertEqual(p1Theme(.dark, colourBlind: true).palette.up, "#0064fa")
        XCTAssertEqual(p1Theme(.dark, colourBlind: true).palette.down, "#f9a325")
        XCTAssertEqual(p1Theme(.light).palette.background, "#ffffff")
        XCTAssertEqual(p1Accents(.dark).lastPrice, "#ce5a3a")
        XCTAssertEqual(ChartTheme.default.bands.opacity, 0.15)
    }

    func testPieHeatmapAndLayout() throws {
        let slices = pieSlices([
            PieDatum(label: "b", value: 1),
            PieDatum(label: "a", value: 3),
            PieDatum(label: "c", value: 2),
        ], maxSlices: 2)
        XCTAssertEqual(slices.map(\.label), ["a", "Other"])
        XCTAssertEqual(slices[1].members.map(\.label), ["c", "b"])
        XCTAssertEqual(try pieArcs([1, 1, 2]).map(\.share), [0.25, 0.25, 0.5])
        XCTAssertThrowsError(try pieArcs([-1]))
        let hidden = hideSlices(slices, hidden: ["other"])
        XCTAssertEqual(hidden[1].hidden, true)
        XCTAssertEqual(hidden[0].share, 1)
        var state = PieChartState(data: [
            PieDatum(label: "a", value: 2),
            PieDatum(label: "b", value: 1),
        ], selectionMode: .single)
        state.click("a")
        XCTAssertEqual(state.selectedKeys, ["a"])
        state.click("a")
        XCTAssertEqual(state.selectedKeys, [])
        let quantizer = try quantize([0, 10], count: 2)
        XCTAssertEqual(quantizer.thresholds, [5])
        XCTAssertEqual(quantizer.step(4), 0)
        XCTAssertEqual(quantizer.step(5), 1)
        let grid = try heatmapGrid(rows: ["d0", "d1"], columns: ["h0", "h1"], value: { _, _, r, c in
            [[1.0, 3], [2, nil]][r][c]
        }, count: 2).grid
        XCTAssertEqual(grid[0][0].step, 1)
        XCTAssertEqual(grid[0][1].step, 2)
        XCTAssertEqual(grid[1][1].step, 0)
        let range = normaliseRange(HeatmapPosition(r: 1, c: 0), HeatmapPosition(r: 0, c: 1))
        XCTAssertEqual(range, HeatmapRange(r0: 0, r1: 1, c0: 0, c1: 1))
        XCTAssertTrue(inRange(range, 1, 1))
        XCTAssertTrue(isDimmed(emphasis: .cell, active: HeatmapPosition(r: 0, c: 0), range: nil, r: 0, c: 1))
        XCTAssertFalse(isDimmed(emphasis: .crosshair, active: HeatmapPosition(r: 0, c: 0), range: nil, r: 0, c: 1))
        let tiles = try squarify([1, 1], in: ChartRect(x: 0, y: 0, width: 2, height: 2))
        XCTAssertEqual(tiles.reduce(0) { $0 + $1.width * $1.height }, 4, accuracy: 0.0001)
        XCTAssertEqual(symmetricExtent([1, -4, .nan]).min, -4)
        XCTAssertEqual(symmetricExtent([0, 0]).max, 0)
    }

    func testCategoryScatterPolarSparkline() {
        let frame = categoryFrame(CategoryLayoutOptions(
            mode: .group,
            series: [CategorySeriesInput(id: "a", data: [10])],
            categories: 1, width: 640, height: 320
        ))
        XCTAssertEqual(frame.rects.count, 1)
        XCTAssertEqual(frame.rects[0].y, 16, accuracy: 0.001)
        XCTAssertEqual(frame.rects[0].height, 276, accuracy: 0.001)
        let stack = categoryLayout(CategoryLayoutOptions(
            mode: .stack,
            series: [
                CategorySeriesInput(id: "a", data: [2, -1]),
                CategorySeriesInput(id: "b", data: [3, -2]),
            ],
            categories: 2, width: 200, height: 100
        ))
        XCTAssertEqual(stack.count, 4)
        let scatter = scatterLayout(series: [("obs", [ScatterDatum(x: 1, y: 2), ScatterDatum(x: .nan, y: 1)])], width: 640, height: 360)
        XCTAssertEqual(scatter.points.count, 1)
        XCTAssertEqual(polarPoint(cx: 0, cy: 0, radius: 10, angle: 0).1, -10)
        XCTAssertEqual(wedgeAngles(index: 0, count: 4, direction: .clockwise).1, .pi / 2, accuracy: 0.0001)
        XCTAssertEqual(barRadius(value: 5, max: 10, radius: 100), 50)
        let paths = sparklinePaths([.number(1), .number(nil), .number(4)], width: 80, height: 22)
        XCTAssertEqual(paths.count, 2)
        XCTAssertTrue(paths[0].hasPrefix("M "))
        XCTAssertNotNil(sparklineArea([.number(1), .number(2)], width: 80, height: 22))
        let rows = seriesRows([
            TimeSeriesPoint(time: .unix(2), value: 1),
            TimeSeriesPoint(time: .unix(1), value: 3),
            TimeSeriesPoint(time: .unix(2), value: .nan),
            TimeSeriesPoint(time: .unix(2), value: 4),
        ], categories: nil)
        XCTAssertEqual(rows.map(\.value), [3, 4])
        let ribbon = ribbonSamples(
            upper: [TimeSeriesPoint(time: .unix(1), value: 3)],
            lower: [TimeSeriesPoint(time: .unix(1), value: 1), TimeSeriesPoint(time: .unix(2), value: 2)],
            categories: nil
        )
        XCTAssertEqual(ribbon.count, 1)
        XCTAssertEqual(ribbon[0].lower, 1)
    }

    func testTimelineAndTree() throws {
        let ranges = timelineRanges([
            TimelineItem(start: .unix(10), end: .unix(20), eta: .unix(4), state: "active", label: "Run"),
        ])
        XCTAssertEqual(ranges.map(\.key), ["arrival", "active"])
        XCTAssertEqual(timeGrid([.unix(0), .unix(3600)], step: 3600), [0, 3600])
        let child = TreeNode()
        let root = TreeNode(children: [child, TreeNode()])
        let laid = try tidyTree(root)
        XCTAssertEqual(laid.leaves, 2)
        XCTAssertEqual(laid.levels, 2)
        child.children = [root]
        XCTAssertThrowsError(try tidyTree(root))
    }

    func testViewsBuild() {
        _ = Sparkline(data: [1, nil, 4], area: true)
        _ = PieChart(data: [PieDatum(label: "A", value: 2)], innerRadius: 0.6, selectionMode: .multiple, drillOther: true)
        _ = Heatmap(rows: ["Mon"], columns: ["AM"], values: [[1]], selectionMode: .range)
        _ = CategoryBarChart(categories: ["Temp"], series: [CategoryBarSeries(id: "mae", name: "MAE", data: [1.2])], mode: .stack)
        _ = ScatterChart(series: [ScatterSeries(id: "obs", name: "Observed", data: [ScatterPoint(x: 1, y: 2)])])
        _ = PolarChart(categories: ["N", "E"], series: [PolarBarSeries(id: "obs", name: "Observed", data: [1, 2])])
        _ = LineChart(data: [LinePoint(time: .unix(1), value: 2)], variant: .area, bands: [BandItem(from: .unix(1), to: .unix(2), key: "trend")])
        _ = BarChart(data: [LinePoint(time: .unix(1), value: -1)])
        _ = HistogramChart(data: [LinePoint(time: .unix(1), value: 2)], mode: .diverging)
        _ = CandlestickChart(data: [OHLC(time: .unix(1), open: 1, high: 2, low: 0, close: 2)], coloring: .trend)
        _ = TimeSeriesChart(
            series: [TimeSeriesSpec(id: "visitors", name: "Visitors", kind: .histogram, data: [TimeSeriesPoint(time: .unix(86_400), value: 3)])],
            ribbons: [TimeSeriesRibbon(upper: [TimeSeriesPoint(time: .unix(86_400), value: 4)], lower: [TimeSeriesPoint(time: .unix(86_400), value: 1)])],
            profile: .terminal
        )
        _ = ChartPanes(panes: [HistogramPane(id: "volume", title: "Volume", data: [LinePoint(time: .unix(1), value: 2)])])
        _ = TimelineChart(lanes: [TimelineLane(id: "lane", title: "Lane", items: [TimelineItem(start: .unix(1), end: .unix(3), state: "confirmed", label: "Done")])])
        _ = ChartThemeProvider(p1Theme(.light, colourBlind: true)) { Sparkline(data: [1, 2, 3]) }
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
