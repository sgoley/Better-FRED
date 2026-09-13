import SwiftUI
import Charts

struct CompareView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedIDs: Set<String> = ["CPIAUCSL", "UNRATE"]
    @State private var snapshots: [SeriesSnapshot] = []
    @State private var normalized = true

    var selectedSeries: [FREDSeries] { selectedIDs.compactMap(model.series(with:)) }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height

                ZStack {
                    BetterTheme.background.ignoresSafeArea()

                    if isLandscape {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedIDs) { await loadSnapshots() }
        }
    }

    // MARK: - Landscape 2-Column Terminal Layout
    @ViewBuilder
    private var landscapeLayout: some View {
        HStack(spacing: 16) {
            // Left column: Wide comparison chart taking full height
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Indicator Comparison")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("Normalize (100)", isOn: $normalized)
                        .toggleStyle(.switch)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BetterTheme.cyan)
                        .labelsHidden()
                    Text("Norm 100")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(normalized ? BetterTheme.lime : BetterTheme.mutedOnNavy)
                }

                Chart {
                    ForEach(snapshots, id: \.id) { snapshot in
                        ForEach(points(for: snapshot)) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                                .foregroundStyle(by: .value("Series", snapshot.series.id))
                                .interpolationMethod(.linear)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                }
                .transaction { $0.animation = nil }
                .chartLegend(position: .bottom, spacing: 10)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel(format: .dateTime.year())
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(String(format: "%.0f", val))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(BetterTheme.mutedOnNavy)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(12)
            .frame(maxWidth: .infinity)

            // Right column: Series toggle panel
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Indicators (\(selectedIDs.count)/6)")
                    .font(.caption.weight(.heavy))
                    .tracking(0.8)
                    .foregroundStyle(BetterTheme.lime)

                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(model.catalog) { series in
                            Button {
                                if selectedIDs.contains(series.id) { selectedIDs.remove(series.id) }
                                else if selectedIDs.count < 6 { selectedIDs.insert(series.id) }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedIDs.contains(series.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIDs.contains(series.id) ? BetterTheme.cyan : BetterTheme.mutedOnNavy)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(series.id)
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                        Text(series.title)
                                            .font(.caption2)
                                            .foregroundStyle(BetterTheme.mutedOnNavy)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(selectedIDs.contains(series.id) ? BetterTheme.navy : BetterTheme.surface.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(width: 220)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Portrait Layout
    @ViewBuilder
    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Compare indicators").font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Overlay series and normalize them to see relative movement.").foregroundStyle(BetterTheme.mutedOnNavy)

                Chart {
                    ForEach(snapshots, id: \.id) { snapshot in
                        ForEach(points(for: snapshot)) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                                .foregroundStyle(by: .value("Series", snapshot.series.id))
                                .interpolationMethod(.linear)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                }
                .transaction { $0.animation = nil }
                .frame(minHeight: 280)
                .chartLegend(position: .bottom)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel(format: .dateTime.year())
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                }

                Toggle("Normalize to 100", isOn: $normalized)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Series").font(.headline).foregroundStyle(.white)
                    ForEach(model.catalog) { series in
                        Button {
                            if selectedIDs.contains(series.id) { selectedIDs.remove(series.id) }
                            else if selectedIDs.count < 6 { selectedIDs.insert(series.id) }
                        } label: {
                            HStack {
                                Image(systemName: selectedIDs.contains(series.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIDs.contains(series.id) ? BetterTheme.cyan : BetterTheme.mutedOnNavy)
                                Text(series.id).font(.subheadline.bold()).foregroundStyle(.white)
                                Text(series.title).font(.caption).foregroundStyle(BetterTheme.mutedOnNavy).lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func points(for snapshot: SeriesSnapshot) -> [Observation] {
        guard normalized, let first = snapshot.observations.first, first.value != 0 else { return snapshot.observations }
        return snapshot.observations.map { Observation(date: $0.date, value: $0.value / first.value * 100) }
    }

    private func loadSnapshots() async {
        snapshots = await withTaskGroup(of: SeriesSnapshot?.self, returning: [SeriesSnapshot].self) { group in
            for series in selectedSeries { group.addTask { try? await model.snapshot(for: series) } }
            var loaded: [SeriesSnapshot] = []
            for await snapshot in group {
                if let snapshot { loaded.append(snapshot) }
            }
            return loaded
        }
    }
}
