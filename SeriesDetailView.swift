import SwiftUI
import Charts
import UIKit

struct SeriesDetailView: View {
    @EnvironmentObject private var model: AppModel
    let series: FREDSeries
    @State private var snapshot: SeriesSnapshot?
    @State private var range: Int

    init(series: FREDSeries) {
        self.series = series
        _range = State(initialValue: series.frequency == "Daily" ? 1825 : 36)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) { Text(series.id).font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(BetterTheme.coral); Text(series.title).font(.title2.bold()).foregroundStyle(.white); Text(series.units).font(.subheadline).foregroundStyle(BetterTheme.mutedOnNavy) }
                    Spacer(); Button { model.toggleSaved(series) } label: { Image(systemName: model.isSaved(series) ? "bookmark.fill" : "bookmark").font(.title3) }
                }
                if let snapshot {
                    Chart(snapshot.observations.suffix(range)) { point in
                        AreaMark(x: .value("Date", point.date), y: .value(series.units, point.value)).foregroundStyle(BetterTheme.mint.opacity(0.20))
                        LineMark(x: .value("Date", point.date), y: .value(series.units, point.value)).foregroundStyle(BetterTheme.navy).lineStyle(.init(lineWidth: 2.5))
                    }.frame(height: 260).chartYScale(domain: .automatic(includesZero: false)).chartXAxis(.hidden).chartYAxis { AxisMarks { _ in AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3])).foregroundStyle(BetterTheme.hairline); AxisValueLabel().foregroundStyle(BetterTheme.mutedOnNavy) } }
                    Picker("Range", selection: $range) { Text("1Y").tag(series.frequency == "Daily" ? 365 : 12); Text("3Y").tag(series.frequency == "Daily" ? 1095 : 36); Text("5Y").tag(series.frequency == "Daily" ? 1825 : 60); Text("10Y").tag(series.frequency == "Daily" ? 3650 : 120); Text("Max").tag(2400) }.pickerStyle(.segmented)
                    HStack {
                        ShareLink(item: snapshot.csv, preview: SharePreview("\(series.id) data", image: Image(systemName: "tablecells"))) { Label("Download CSV", systemImage: "arrow.down.circle") }
                        Spacer()
                        Text("\(snapshot.observations.count) observations").font(.caption).foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                    MetricCard { VStack(alignment: .leading, spacing: 8) { Text("About this series").font(.headline); Text(series.description).foregroundStyle(.secondary); Text("Source: \(series.source) • \(series.frequency)").font(.caption).foregroundStyle(.secondary) } }
                } else { ProgressView().frame(maxWidth: .infinity, minHeight: 260) }
            }.padding()
        }.background(BetterTheme.background).task { snapshot = try? await model.client.snapshot(for: series) }
    }
}

private extension SeriesSnapshot {
    var csv: String {
        (["date,value"] + observations.map { "\($0.date.ISO8601Format()),\($0.value)" }).joined(separator: "\n")
    }
}
