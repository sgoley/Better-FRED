import SwiftUI
import Charts

struct RootView: View {
    var body: some View {
        if CommandLine.arguments.contains("-dffPreview") {
            NavigationStack { SeriesDetailView(series: SampleData.series.first { $0.id == "DFF" }!) }
        } else if CommandLine.arguments.contains("-fedFundsPreview") {
            NavigationStack { SeriesDetailView(series: SampleData.series.first { $0.id == "FEDFUNDS" }!) }
        } else {
            TabView {
            DashboardView().tabItem { Label("Overview", systemImage: "rectangle.grid.2x2") }
            ExploreView().tabItem { Label("Explore", systemImage: "magnifyingglass") }
            CompareView().tabItem { Label("Compare", systemImage: "chart.xyaxis.line") }
            SavedView().tabItem { Label("Saved", systemImage: "bookmark") }
            }
            .tint(BetterTheme.ink)
            .background(BetterTheme.background)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BETTER-FRED").font(.caption.weight(.bold)).tracking(1.4).foregroundStyle(BetterTheme.mutedOnNavy)
                            Text("Your economy").font(.largeTitle.weight(.bold)).foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "waveform.path.ecg").font(.title3.weight(.semibold)).foregroundStyle(BetterTheme.navy).padding(11).background(BetterTheme.cyan, in: Circle())
                    }
                    Text("A clear view of what is changing.").font(.subheadline).foregroundStyle(BetterTheme.mutedOnNavy)
                    HeroTrendChart()
                    HStack(spacing: 10) {
                        SummaryPill(label: "SAVED", value: "\(model.watchlist.count)", tint: BetterTheme.cyan)
                        SummaryPill(label: "SERIES", value: "850K+", tint: BetterTheme.lime)
                    }
                    ForEach(model.watchlist.compactMap(model.series(with:))) { series in
                        NavigationLink(value: series) { SeriesCard(series: series) }.buttonStyle(.plain)
                    }
                    Text("Long-range signals").font(.title3.weight(.bold)).foregroundStyle(.white).padding(.top, 8)
                    Text("A wider view reveals the trend behind the latest reading.").font(.subheadline).foregroundStyle(BetterTheme.mutedOnNavy)
                    ForEach(["DGS10", "GDPC1"].compactMap(model.series(with:))) { series in
                        NavigationLink(value: series) { SeriesCard(series: series) }.buttonStyle(.plain)
                    }
                }.padding()
            }
            .background(BetterTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FREDSeries.self) { SeriesDetailView(series: $0) }
        }
    }
}

struct SeriesCard: View {
    let series: FREDSeries
    var body: some View {
        MetricCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text(series.id).font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(BetterTheme.navy); Spacer(); Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(BetterTheme.secondary) }
                Text(series.title).font(.title3.weight(.semibold)).foregroundStyle(BetterTheme.ink)
                HStack(spacing: 6) { Text(series.units); Text("•"); Text(series.frequency) }.font(.caption).foregroundStyle(BetterTheme.secondary)
                HStack { Text("Latest reading").font(.caption2.weight(.medium)); Spacer(); Text("View series").font(.caption2.weight(.semibold)).foregroundStyle(BetterTheme.navy) }.foregroundStyle(BetterTheme.secondary)
            }
        }
    }
}

struct HeroTrendChart: View {
    private let points = SampleData.observations(for: SampleData.series[0])
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("CPIAUCSL").font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(BetterTheme.mutedOnNavy); Spacer(); Text("1Y").font(.caption.weight(.bold)).foregroundStyle(BetterTheme.navy).padding(.horizontal, 12).padding(.vertical, 7).background(.white, in: Capsule()) }
            Text("Consumer prices").font(.headline).foregroundStyle(.white)
            Text("+3.2%  •  past year").font(.subheadline.weight(.semibold)).foregroundStyle(BetterTheme.cyan)
            Chart(points) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Value", point.value)).foregroundStyle(LinearGradient(colors: [BetterTheme.cyan.opacity(0.42), .clear], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value)).foregroundStyle(.white).lineStyle(.init(lineWidth: 2.5))
            }.frame(height: 150).chartXAxis(.hidden).chartYAxis(.hidden)
        }.padding(18).background(BetterTheme.navy.opacity(0.62), in: RoundedRectangle(cornerRadius: 20, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.14), lineWidth: 1) }
    }
}

struct SummaryPill: View {
    let label: String
    let value: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { Text(label).font(.caption2.weight(.bold)).tracking(0.8).foregroundStyle(BetterTheme.secondary); Text(value).font(.title3.weight(.bold)).foregroundStyle(tint) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(14).background(BetterTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 14).stroke(BetterTheme.hairline, lineWidth: 1) }
    }
}

struct ExploreView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var results: [FREDSeries] = SampleData.series
    var body: some View {
        NavigationStack {
            List(results) { series in
                NavigationLink(value: series) { VStack(alignment: .leading) { Text(series.title); Text(series.id).font(.caption).foregroundStyle(.secondary) } }
            }
            .searchable(text: $query, prompt: "Search series or symbols")
            .navigationTitle("Explore")
            .navigationDestination(for: FREDSeries.self) { SeriesDetailView(series: $0) }
            .task(id: query) { results = await model.search(query) }
        }
    }
}

struct SavedView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        NavigationStack {
            List(model.watchlist.compactMap(model.series(with:))) { series in
                NavigationLink(value: series) { SeriesCard(series: series) }
            }
            .listStyle(.plain)
            .navigationTitle("Saved")
            .navigationDestination(for: FREDSeries.self) { SeriesDetailView(series: $0) }
        }
    }
}
