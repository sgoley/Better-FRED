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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Compare indicators").font(.largeTitle.bold())
                    Text("Overlay series and normalize them to see relative movement.").foregroundStyle(.secondary)
                    Chart {
                        ForEach(snapshots, id: \.id) { snapshot in
                            ForEach(points(for: snapshot)) { point in
                                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                                    .foregroundStyle(by: .value("Series", snapshot.series.id))
                            }
                        }
                    }
                    .frame(minHeight: 300)
                    .chartLegend(position: .bottom)
                    Toggle("Normalize to 100", isOn: $normalized)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Series").font(.headline)
                        ForEach(model.catalog) { series in
                            Button {
                                if selectedIDs.contains(series.id) { selectedIDs.remove(series.id) }
                                else if selectedIDs.count < 6 { selectedIDs.insert(series.id) }
                            } label: {
                                HStack { Image(systemName: selectedIDs.contains(series.id) ? "checkmark.circle.fill" : "circle"); Text(series.id); Text(series.title).foregroundStyle(.secondary); Spacer() }
                            }.foregroundStyle(BetterTheme.ink)
                        }
                    }
                }.padding()
            }
            .background(BetterTheme.background)
            .navigationTitle("Compare")
            .task(id: selectedIDs) { await loadSnapshots() }
        }
    }

    private func points(for snapshot: SeriesSnapshot) -> [Observation] {
        guard normalized, let first = snapshot.observations.first, first.value != 0 else { return snapshot.observations }
        return snapshot.observations.map { Observation(date: $0.date, value: $0.value / first.value * 100) }
    }

    private func loadSnapshots() async {
        snapshots = await withTaskGroup(of: SeriesSnapshot?.self, returning: [SeriesSnapshot].self) { group in
            for series in selectedSeries { group.addTask { try? await model.client.snapshot(for: series) } }
            var loaded: [SeriesSnapshot] = []
            for await snapshot in group {
                if let snapshot { loaded.append(snapshot) }
            }
            return loaded
        }
    }
}
