import SwiftUI
import Charts
import UIKit

// MARK: - Interactive FRED Chart
struct InteractiveFREDChart: View {
    let series: FREDSeries
    let observations: [Observation]
    let isSmoothed: Bool
    let showRecessions: Bool
    let dateRange: ChartDateRange
    let zoomDomain: ClosedRange<Date>?
    @Binding var selectedObservation: Observation?

    @State private var rawSelectedDate: Date?
    @State private var displayPoints: [Observation] = []
    @State private var yDomain: ClosedRange<Double> = 0...10
    @State private var activeDomain: ClosedRange<Date> = Date.distantPast...Date.distantFuture
    @State private var relevantRecessions: [USRecession] = []
    @State private var isComputing = false

    var body: some View {
        ZStack {
            Chart {
                // US Recession shaded bands (like official FRED)
                ForEach(relevantRecessions) { recession in
                    RectangleMark(
                        xStart: .value("Recession Start", recession.start),
                        xEnd: .value("Recession End", recession.end)
                    )
                    .foregroundStyle(Color.gray.opacity(0.20))
                }

                // Main series data line
                ForEach(displayPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(isSmoothed ? .catmullRom : .linear)
                    .foregroundStyle(BetterTheme.cyan)
                    .lineStyle(StrokeStyle(lineWidth: isSmoothed ? 2.2 : 1.8))

                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Baseline", yDomain.lowerBound),
                        yEnd: .value("Value", point.value)
                    )
                    .interpolationMethod(isSmoothed ? .catmullRom : .linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BetterTheme.cyan.opacity(0.28), BetterTheme.cyan.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Touch-and-drag selection indicator
                if let selected = selectedObservation {
                    RuleMark(x: .value("Selected Date", selected.date))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .annotation(position: .top, spacing: 6) {
                            FloatingTooltip(observation: selected, units: series.units)
                        }

                    PointMark(
                        x: .value("Selected Date", selected.date),
                        y: .value("Selected Value", selected.value)
                    )
                    .symbolSize(54)
                    .foregroundStyle(BetterTheme.cyan)
                    .annotation(position: .overlay) {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .transaction { $0.animation = nil }
            .chartXScale(domain: activeDomain)
            .chartYScale(domain: yDomain)
            .chartXSelection(value: $rawSelectedDate)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel(format: .dateTime.year().month(.abbreviated))
                        .foregroundStyle(BetterTheme.mutedOnNavy)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(String(format: "%.1f", val))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }
                    }
                }
            }

            if isComputing && displayPoints.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: BetterTheme.cyan))
                    Text("Rendering \(series.id)...")
                        .font(.caption2)
                        .foregroundStyle(BetterTheme.mutedOnNavy)
                }
            }
        }
        .onAppear {
            recalculate()
        }
        .onChange(of: dateRange) { _, _ in
            recalculate()
        }
        .onChange(of: isSmoothed) { _, _ in
            recalculate()
        }
        .onChange(of: zoomDomain) { _, _ in
            recalculate()
        }
        .onChange(of: observations.count) { _, _ in
            recalculate()
        }
        .onChange(of: showRecessions) { _, _ in
            recalculate()
        }
        .onChange(of: rawSelectedDate) { _, newDate in
            guard let newDate else {
                selectedObservation = nil
                return
            }
            findClosestObservation(to: newDate)
        }
    }

    private func recalculate() {
        guard !observations.isEmpty else {
            displayPoints = []
            return
        }

        let base: [Observation]
        if let startDate = dateRange.startDate(from: observations.last?.date ?? .now) {
            base = observations.filter { $0.date >= startDate }
        } else {
            base = observations
        }

        let computedPoints: [Observation]
        if isSmoothed {
            computedPoints = base.smoothed(window: series.frequency == "Daily" ? 14 : 5)
        } else {
            computedPoints = base
        }

        let domain: ClosedRange<Date>
        if let zoomDomain {
            domain = zoomDomain
        } else if let first = computedPoints.first?.date, let last = computedPoints.last?.date, first < last {
            domain = first...last
        } else {
            domain = Date.distantPast...Date.distantFuture
        }

        let values = computedPoints.map(\.value)
        let computedYDomain: ClosedRange<Double>
        if let minVal = values.min(), let maxVal = values.max() {
            let padding = (maxVal - minVal) * 0.08
            computedYDomain = Swift.max(0, minVal - padding)...(maxVal + padding)
        } else {
            computedYDomain = 0...10
        }

        let recessions: [USRecession]
        if showRecessions {
            recessions = USRecession.all.filter { r in
                r.end >= domain.lowerBound && r.start <= domain.upperBound
            }
        } else {
            recessions = []
        }

        self.displayPoints = computedPoints
        self.yDomain = computedYDomain
        self.activeDomain = domain
        self.relevantRecessions = recessions
    }

    private func findClosestObservation(to target: Date) {
        guard !displayPoints.isEmpty else { return }
        var closest = displayPoints[0]
        var minDiff = abs(closest.date.timeIntervalSince(target))

        for point in displayPoints {
            let diff = abs(point.date.timeIntervalSince(target))
            if diff < minDiff {
                minDiff = diff
                closest = point
            }
        }

        if selectedObservation?.id != closest.id {
            selectedObservation = closest
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Floating Tooltip Annotation
struct FloatingTooltip: View {
    let observation: Observation
    let units: String

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(observation.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.8))
            Text(formattedValue)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(BetterTheme.ink.opacity(0.92))
                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BetterTheme.cyan.opacity(0.5), lineWidth: 1)
        )
    }

    private var formattedValue: String {
        if units == "Percent" {
            return String(format: "%.2f%%", observation.value)
        } else {
            return String(format: "%.2f %@", observation.value, units)
        }
    }
}

// MARK: - Scrubber HUD Card (Sticky above chart)
struct ScrubberHUDView: View {
    let series: FREDSeries
    let activeObservation: Observation?
    let previousObservation: Observation?
    let isInspecting: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(isInspecting ? "INSPECTING POINT" : "LATEST OBSERVATION")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.0)
                        .foregroundStyle(isInspecting ? BetterTheme.lime : BetterTheme.mutedOnNavy)
                    if isInspecting {
                        Circle()
                            .fill(BetterTheme.lime)
                            .frame(width: 6, height: 6)
                    }
                }
                if let obs = activeObservation {
                    Text(obs.date.formatted(date: .long, time: .omitted))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            }

            Spacer()

            if let obs = activeObservation {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedValue(obs.value))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(BetterTheme.cyan)

                    if let prev = previousObservation {
                        let delta = obs.value - prev.value
                        let pctChange = prev.value != 0 ? (delta / prev.value) * 100 : 0
                        HStack(spacing: 3) {
                            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(String(format: "%+.2f (%+.2f%%)", delta, pctChange))
                        }
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(delta >= 0 ? BetterTheme.lime : BetterTheme.coral)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BetterTheme.navy.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isInspecting ? BetterTheme.cyan.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func formattedValue(_ val: Double) -> String {
        if series.units == "Percent" {
            return String(format: "%.2f%%", val)
        } else {
            return String(format: "%.2f", val)
        }
    }
}

// MARK: - Exportable Chart Card (Rendered at retina scale for PNG export & clipboard)
struct ExportableChartCard: View {
    let series: FREDSeries
    let observations: [Observation]
    let isSmoothed: Bool
    let showRecessions: Bool
    let dateRange: ChartDateRange
    var zoomDomain: ClosedRange<Date>? = nil

    private var displayObservations: [Observation] {
        let base: [Observation]
        if let zoomDomain {
            base = observations.filter { $0.date >= zoomDomain.lowerBound && $0.date <= zoomDomain.upperBound }
        } else if let startDate = dateRange.startDate(from: observations.last?.date ?? .now) {
            base = observations.filter { $0.date >= startDate }
        } else {
            base = observations
        }
        return isSmoothed ? base.smoothed(window: series.frequency == "Daily" ? 14 : 5) : base
    }

    private var activeDomain: ClosedRange<Date> {
        if let zoomDomain {
            return zoomDomain
        }
        if let first = displayObservations.first?.date,
           let last = displayObservations.last?.date,
           first < last {
            return first...last
        }
        if let startDate = dateRange.startDate(from: observations.last?.date ?? .now),
           let last = observations.last?.date {
            return startDate...last
        }
        if let first = observations.first?.date,
           let last = observations.last?.date {
            return first...last
        }
        return Date.distantPast...Date.distantFuture
    }

    private var yDomain: ClosedRange<Double> {
        let values = displayObservations.map(\.value)
        if let minVal = values.min(), let maxVal = values.max() {
            let padding = Swift.max(0.1, (maxVal - minVal) * 0.08)
            return Swift.max(0, minVal - padding)...(maxVal + padding)
        }
        return 0...10
    }

    private var relevantRecessions: [USRecession] {
        guard showRecessions else { return [] }
        return USRecession.all.compactMap { r -> USRecession? in
            guard r.end >= activeDomain.lowerBound && r.start <= activeDomain.upperBound else { return nil }
            let clampedStart = Swift.max(r.start, activeDomain.lowerBound)
            let clampedEnd = Swift.min(r.end, activeDomain.upperBound)
            return USRecession(name: r.name, start: clampedStart, end: clampedEnd)
        }
    }

    private var latest: Observation? { displayObservations.last }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(series.id)
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(BetterTheme.coral)

                        Text("•")
                            .foregroundStyle(Color.white.opacity(0.4))

                        Text(series.frequency)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BetterTheme.mutedOnNavy)

                        Text(zoomDomain != nil ? "ZOOMED" : dateRange.rawValue)
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BetterTheme.navy)
                            .foregroundStyle(BetterTheme.coral)
                            .cornerRadius(4)

                        if isSmoothed {
                            Text("SMOOTHED")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BetterTheme.lime.opacity(0.2))
                                .foregroundStyle(BetterTheme.lime)
                                .cornerRadius(4)
                        } else {
                            Text("RAW FIDELITY")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BetterTheme.cyan.opacity(0.2))
                                .foregroundStyle(BetterTheme.cyan)
                                .cornerRadius(4)
                        }
                    }

                    Text(series.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(series.units)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BetterTheme.mutedOnNavy)

                        Text("•")
                            .foregroundStyle(Color.white.opacity(0.3))

                        Text("\(activeDomain.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(activeDomain.upperBound.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BetterTheme.cyan)
                    }
                }

                Spacer()

                if let latest {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(latest.valueFormatted(series.units))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(BetterTheme.cyan)

                        Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                }
            }

            // Chart area
            Chart {
                ForEach(relevantRecessions) { recession in
                    RectangleMark(
                        xStart: .value("Recession Start", recession.start),
                        xEnd: .value("Recession End", recession.end)
                    )
                    .foregroundStyle(Color.gray.opacity(0.22))
                }

                ForEach(displayObservations) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(isSmoothed ? .catmullRom : .linear)
                    .foregroundStyle(BetterTheme.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.0))

                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Baseline", yDomain.lowerBound),
                        yEnd: .value("Value", point.value)
                    )
                    .interpolationMethod(isSmoothed ? .catmullRom : .linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BetterTheme.cyan.opacity(0.30), BetterTheme.cyan.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXScale(domain: activeDomain)
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel(format: dateRange == .oneYear ? .dateTime.month(.abbreviated).year(.twoDigits) : .dateTime.year())
                        .foregroundStyle(BetterTheme.mutedOnNavy)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(String(format: "%.1f", val))
                                .font(.caption2)
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }
                    }
                }
            }
            .frame(height: 240)

            // Footer
            HStack {
                Text("Source: \(series.source)")
                    .font(.caption2)
                    .foregroundStyle(BetterTheme.mutedOnNavy)
                Spacer()
                if showRecessions && !relevantRecessions.isEmpty {
                    Text("Shaded areas indicate U.S. recessions")
                        .font(.caption2.italic())
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                Text("• Better-FRED")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BetterTheme.cyan)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BetterTheme.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

private extension Observation {
    func valueFormatted(_ units: String) -> String {
        if units == "Percent" {
            return String(format: "%.2f%%", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}
