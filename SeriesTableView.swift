import SwiftUI
import UIKit

struct SeriesTableView: View {
    let series: FREDSeries
    let observations: [Observation]
    let dateRange: ChartDateRange

    @State private var searchText = ""
    @State private var isAscending = false // default newest first
    @State private var copiedFeedback = false

    private var filteredObservations: [Observation] {
        var list: [Observation]
        if let startDate = dateRange.startDate(from: observations.last?.date ?? .now) {
            list = observations.filter { $0.date >= startDate }
        } else {
            list = observations
        }

        if !searchText.isEmpty {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            list = list.filter { obs in
                obs.date.formatted(date: .numeric, time: .omitted).contains(query) ||
                obs.date.formatted(date: .abbreviated, time: .omitted).lowercased().contains(query) ||
                String(format: "%.2f", obs.value).contains(query)
            }
        }

        if isAscending {
            return list.sorted { $0.date < $1.date }
        } else {
            return list.sorted { $0.date > $1.date }
        }
    }

    private var stats: (high: Observation?, low: Observation?, avg: Double)? {
        guard !filteredObservations.isEmpty else { return nil }
        let high = filteredObservations.max { $0.value < $1.value }
        let low = filteredObservations.min { $0.value < $1.value }
        let sum = filteredObservations.reduce(0.0) { $0 + $1.value }
        let avg = sum / Double(filteredObservations.count)
        return (high, low, avg)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Stats summary bar
            if let stats {
                HStack(spacing: 8) {
                    TableStatBadge(
                        title: "LATEST",
                        value: filteredObservations.first?.formattedValue(series.units) ?? "--",
                        tint: BetterTheme.cyan
                    )
                    TableStatBadge(
                        title: "HIGH",
                        value: stats.high?.formattedValue(series.units) ?? "--",
                        subtitle: stats.high?.date.formatted(date: .abbreviated, time: .omitted),
                        tint: BetterTheme.lime
                    )
                    TableStatBadge(
                        title: "LOW",
                        value: stats.low?.formattedValue(series.units) ?? "--",
                        subtitle: stats.low?.date.formatted(date: .abbreviated, time: .omitted),
                        tint: BetterTheme.coral
                    )
                    TableStatBadge(
                        title: "AVERAGE",
                        value: series.units == "Percent" ? String(format: "%.2f%%", stats.avg) : String(format: "%.2f", stats.avg),
                        tint: .white
                    )
                }
            }

            // Search and Sort Row
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(BetterTheme.mutedOnNavy)
                    TextField("Search date (e.g. 2024)...", text: $searchText)
                        .font(.caption)
                        .foregroundStyle(.white)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(BetterTheme.navy.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))

                Button {
                    withAnimation { isAscending.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                        Text(isAscending ? "Oldest" : "Newest")
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(BetterTheme.navy.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(BetterTheme.cyan)
                }

                Button {
                    copyTableData()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedFeedback ? "checkmark" : "doc.on.clipboard")
                        Text(copiedFeedback ? "Copied" : "Copy")
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(copiedFeedback ? BetterTheme.lime.opacity(0.2) : BetterTheme.navy.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(copiedFeedback ? BetterTheme.lime : .white)
                }

                Text("\(filteredObservations.count) rows")
                    .font(.caption2)
                    .foregroundStyle(BetterTheme.mutedOnNavy)
            }

            // Table Header
            HStack {
                Text("OBSERVATION DATE")
                    .frame(width: 140, alignment: .leading)
                Spacer()
                Text("RATE / VALUE")
                    .frame(width: 100, alignment: .trailing)
                Text("PERIOD CHANGE")
                    .frame(width: 110, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .heavy))
            .tracking(0.8)
            .foregroundStyle(BetterTheme.mutedOnNavy)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BetterTheme.navy.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))

            // Virtualized Table Body
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredObservations.enumerated()), id: \.element.id) { index, observation in
                        let delta = computeDelta(for: index)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(observation.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(observation.date.formatted(date: .numeric, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(BetterTheme.mutedOnNavy)
                            }
                            .frame(width: 140, alignment: .leading)

                            Spacer()

                            Text(observation.formattedValue(series.units))
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(BetterTheme.cyan)
                                .frame(width: 100, alignment: .trailing)

                            if let delta {
                                HStack(spacing: 3) {
                                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 9))
                                    Text(String(format: "%+.2f%@", delta, series.units == "Percent" ? "%" : ""))
                                }
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(delta >= 0 ? BetterTheme.lime : BetterTheme.coral)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    (delta >= 0 ? BetterTheme.lime : BetterTheme.coral).opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .frame(width: 110, alignment: .trailing)
                            } else {
                                Text("--")
                                    .font(.caption2)
                                    .foregroundStyle(BetterTheme.mutedOnNavy)
                                    .frame(width: 110, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(index % 2 == 0 ? BetterTheme.navy.opacity(0.25) : Color.clear)
                        )
                    }
                }
            }
            .frame(minHeight: 280, maxHeight: .infinity)
        }
    }

    private func computeDelta(for index: Int) -> Double? {
        if isAscending {
            guard index > 0 else { return nil }
            return filteredObservations[index].value - filteredObservations[index - 1].value
        } else {
            guard index < filteredObservations.count - 1 else { return nil }
            return filteredObservations[index].value - filteredObservations[index + 1].value
        }
    }

    private func copyTableData() {
        var lines = ["Date\tValue\tChange"]
        for (index, obs) in filteredObservations.enumerated() {
            let dateStr = obs.date.formatted(date: .numeric, time: .omitted)
            let valStr = obs.formattedValue(series.units)
            let delta = computeDelta(for: index)
            let deltaStr = delta != nil ? String(format: "%+.2f", delta!) : ""
            lines.append("\(dateStr)\t\(valStr)\t\(deltaStr)")
        }
        UIPasteboard.general.string = lines.joined(separator: "\n")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation {
            copiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedFeedback = false
            }
        }
    }
}

// MARK: - Table Stat Badge
struct TableStatBadge: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .heavy))
                .tracking(0.6)
                .foregroundStyle(BetterTheme.mutedOnNavy)
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundStyle(BetterTheme.mutedOnNavy)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(BetterTheme.navy.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private extension Observation {
    func formattedValue(_ units: String) -> String {
        if units == "Percent" {
            return String(format: "%.2f%%", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}
