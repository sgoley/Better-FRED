import SwiftUI
import Charts

struct RootView: View {
    var body: some View {
        if CommandLine.arguments.contains("-mortgagePreview") {
            NavigationStack { SeriesDetailView(series: SampleData.series.first { $0.id == "MORTGAGE30US" }!) }
        } else if CommandLine.arguments.contains("-dffPreview") {
            NavigationStack { SeriesDetailView(series: SampleData.series.first { $0.id == "DFF" }!) }
        } else if CommandLine.arguments.contains("-fedFundsPreview") {
            NavigationStack { SeriesDetailView(series: SampleData.series.first { $0.id == "FEDFUNDS" }!) }
        } else {
            TabView {
                DashboardView().tabItem { Label("Overview", systemImage: "rectangle.grid.2x2") }
                ExploreView().tabItem { Label("Explore", systemImage: "magnifyingglass") }
                CompareView().tabItem { Label("Compare", systemImage: "chart.xyaxis.line") }
                SavedView().tabItem { Label("Saved", systemImage: "bookmark") }
                SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
            }
            .tint(BetterTheme.cyan)
            .background(BetterTheme.background)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showSettings: Bool = false

    var mortgageSeries: FREDSeries? {
        model.series(with: "MORTGAGE30US") ?? SampleData.series.first { $0.id == "MORTGAGE30US" }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height
                let columns = isLandscape ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)] : [GridItem(.flexible())]

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BETTER US ECON").font(.caption.weight(.bold)).tracking(1.4).foregroundStyle(BetterTheme.mutedOnNavy)
                                Text("Your economy").font(.largeTitle.weight(.bold)).foregroundStyle(.white)
                            }
                            Spacer()
                            Button {
                                showSettings = true
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(model.isLive ? BetterTheme.lime : BetterTheme.coral)
                                        .frame(width: 8, height: 8)
                                    Text(model.isLive ? "Live API" : "Preview")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                    Image(systemName: "gearshape.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(BetterTheme.cyan)
                                }
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(BetterTheme.navy.opacity(0.85), in: Capsule())
                                .overlay(Capsule().stroke(BetterTheme.hairline, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Real-time signals with original high-resolution series detail.")
                            .font(.subheadline)
                            .foregroundStyle(BetterTheme.mutedOnNavy)

                        // Hero Spotlight: 30-Year Mortgage Average (MORTGAGE30US)
                        if let mortgageSeries {
                            MortgageSpotlightCard(series: mortgageSeries)
                        }

                        HStack(spacing: 10) {
                            SummaryPill(label: "WATCHLIST", value: "\(model.watchlist.count)", tint: BetterTheme.cyan)
                            SummaryPill(label: "BENCHMARK", value: "6.76%", tint: BetterTheme.lime)
                        }

                        Text("Watchlist").font(.title3.weight(.bold)).foregroundStyle(.white).padding(.top, 6)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(model.watchlist.compactMap(model.series(with:))) { series in
                                NavigationLink(value: series) {
                                    SeriesCard(series: series)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("Long-range signals").font(.title3.weight(.bold)).foregroundStyle(.white).padding(.top, 8)
                        Text("A wider view reveals the trend behind the latest reading.").font(.subheadline).foregroundStyle(BetterTheme.mutedOnNavy)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(["DGS10", "GDPC1"].compactMap(model.series(with:))) { series in
                                NavigationLink(value: series) {
                                    SeriesCard(series: series)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(BetterTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FREDSeries.self) { SeriesDetailView(series: $0) }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }
}

// MARK: - Dedicated Home Screen Mortgage Rate Spotlight
struct MortgageSpotlightCard: View {
    @EnvironmentObject private var model: AppModel
    let series: FREDSeries
    private var observations: [Observation] {
        model.cachedSnapshot(for: series.id)?.observations ?? SampleData.observations(for: series)
    }
    private var latest: Observation? { observations.last }
    private var prev: Observation? { observations.dropLast().last }

    var body: some View {
        NavigationLink(value: series) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.caption.bold())
                        Text("KEY BENCHMARK • MORTGAGE30US")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.0)
                    }
                    .foregroundStyle(BetterTheme.lime)

                    Spacer()

                    Text("Weekly")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15), in: Capsule())
                        .foregroundStyle(.white)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("30-Year Fixed Mortgage")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        if let latest {
                            Text("As of \(latest.date.formatted(date: .abbreviated, time: .omitted)) • Weekly")
                                .font(.caption)
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }
                    }

                    Spacer()

                    if let latest {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f%%", latest.value))
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(BetterTheme.cyan)

                            if let prev {
                                let delta = latest.value - prev.value
                                HStack(spacing: 3) {
                                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%+.2f%% vs prior wk", delta))
                                }
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(delta >= 0 ? BetterTheme.lime : BetterTheme.coral)
                            }
                        }
                    }
                }

                // High-detail sparkline (52 weeks of raw unsmoothed fidelity)
                let recent = Array(observations.suffix(52))
                Chart(recent) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Rate", point.value)
                    )
                    .interpolationMethod(.linear) // Raw unsmoothed detail!
                    .foregroundStyle(BetterTheme.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Rate", point.value)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BetterTheme.cyan.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 110)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)

                HStack {
                    Text("Tap for zoom, drag scrubber & PNG export")
                        .font(.caption2)
                        .foregroundStyle(BetterTheme.mutedOnNavy)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("View detail")
                            .font(.caption2.weight(.bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(BetterTheme.cyan)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(BetterTheme.navy.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(BetterTheme.cyan.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SeriesCard: View {
    @EnvironmentObject private var model: AppModel
    let series: FREDSeries
    private var snapshot: SeriesSnapshot {
        model.cachedSnapshot(for: series.id) ?? SeriesSnapshot(series: series, observations: SampleData.observations(for: series))
    }

    var body: some View {
        MetricCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(series.id)
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(BetterTheme.navy)
                    Spacer()
                    if let latest = snapshot.latest {
                        Text(latest.formattedValue(series.units))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(BetterTheme.navy)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BetterTheme.secondary)
                }

                Text(series.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BetterTheme.ink)

                HStack(spacing: 6) {
                    Text(series.units)
                    Text("•")
                    Text(series.frequency)
                    if let latest = snapshot.latest {
                        Text("•")
                        Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption)
                .foregroundStyle(BetterTheme.secondary)

                HStack {
                    if let change = snapshot.change {
                        HStack(spacing: 3) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(String(format: "%+.2f %@", change, series.units == "Percent" ? "%" : ""))
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(change >= 0 ? Color(red: 0.1, green: 0.6, blue: 0.2) : Color.red)
                    } else {
                        Text("Latest reading").font(.caption2.weight(.medium)).foregroundStyle(BetterTheme.secondary)
                    }

                    Spacer()

                    Text("View series").font(.caption2.weight(.semibold)).foregroundStyle(BetterTheme.navy)
                }
            }
        }
        .task {
            if model.cachedSnapshot(for: series.id) == nil {
                _ = try? await model.snapshot(for: series)
            }
        }
    }
}

private extension Observation {
    func formattedValue(_ units: String) -> String {
        if units == "Percent" {
            return String(format: "%.2f%%", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

struct SummaryPill: View {
    let label: String
    let value: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2.weight(.bold)).tracking(0.8).foregroundStyle(BetterTheme.secondary)
            Text(value).font(.title3.weight(.bold)).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BetterTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(BetterTheme.hairline, lineWidth: 1) }
    }
}

struct ExploreView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var results: [FREDSeries] = SampleData.series
    var body: some View {
        NavigationStack {
            List(results) { series in
                NavigationLink(value: series) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(series.title).font(.body.weight(.semibold))
                        HStack(spacing: 6) {
                            Text(series.id).font(.caption.bold()).foregroundStyle(BetterTheme.coral)
                            Text("•").font(.caption).foregroundStyle(.secondary)
                            Text(series.frequency).font(.caption).foregroundStyle(.secondary)
                            Text("•").font(.caption).foregroundStyle(.secondary)
                            Text(series.units).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
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
