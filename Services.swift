import Foundation

protocol FREDDataProviding {
    func search(_ query: String) async throws -> [FREDSeries]
    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot
}

struct PreviewFREDClient: FREDDataProviding {
    func search(_ query: String) async throws -> [FREDSeries] {
        guard !query.isEmpty else { return SampleData.series }
        return SampleData.series.filter { series in
            series.id.localizedCaseInsensitiveContains(query) || series.title.localizedCaseInsensitiveContains(query)
        }
    }

    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot {
        SeriesSnapshot(series: series, observations: SampleData.observations(for: series))
    }
}

struct FREDAPIClient: FREDDataProviding {
    let apiKey: String
    let session: URLSession = .shared
    private let decoder = JSONDecoder()

    func search(_ query: String) async throws -> [FREDSeries] {
        var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/search")!
        components.queryItems = [URLQueryItem(name: "search_text", value: query), URLQueryItem(name: "api_key", value: apiKey), URLQueryItem(name: "file_type", value: "json")]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response)
        return try decoder.decode(FREDSearchResponse.self, from: data).seriess.map { FREDSeries(id: $0.id, title: $0.title, units: $0.units, frequency: $0.frequency, source: $0.source, description: $0.notes) }
    }

    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot {
        var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/observations")!
        components.queryItems = [URLQueryItem(name: "series_id", value: series.id), URLQueryItem(name: "api_key", value: apiKey), URLQueryItem(name: "file_type", value: "json")]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response)
        let decoded = try decoder.decode(FREDObservationsResponse.self, from: data)
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let points = decoded.observations.compactMap { item -> Observation? in
            guard let date = formatter.date(from: item.date), let value = Double(item.value) else { return nil }
            return Observation(date: date, value: value)
        }
        return SeriesSnapshot(series: series, observations: points)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }
}

private struct FREDSearchResponse: Decodable { let seriess: [FREDSearchSeries] }
private struct FREDSearchSeries: Decodable { let id: String; let title: String; let units: String; let frequency: String; let notes: String; let source: String }
private struct FREDObservationsResponse: Decodable { let observations: [FREDObservation] }
private struct FREDObservation: Decodable { let date: String; let value: String }

@MainActor
final class AppModel: ObservableObject {
    @Published var watchlist: [String] = []
    @Published private(set) var catalog: [FREDSeries] = SampleData.series
    let client: FREDDataProviding
    private let watchlistKey = "betterfred.watchlist"

    @Published var loadingSeriesIDs: Set<String> = []
    private var snapshotCache: [String: SeriesSnapshot] = [:]

    init() {
        if let key = ProcessInfo.processInfo.environment["FRED_API_KEY"], !key.isEmpty {
            client = FREDAPIClient(apiKey: key)
        } else {
            client = PreviewFREDClient()
        }
        var list = UserDefaults.standard.stringArray(forKey: watchlistKey) ?? ["MORTGAGE30US", "CPIAUCSL", "UNRATE", "FEDFUNDS", "DGS10", "GDPC1"]
        if !list.contains("MORTGAGE30US") {
            list.insert("MORTGAGE30US", at: 0)
        }
        watchlist = list
        preloadWatchlist()
    }

    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot {
        if let cached = snapshotCache[series.id] {
            return cached
        }
        loadingSeriesIDs.insert(series.id)
        defer { loadingSeriesIDs.remove(series.id) }

        let snap = try await client.snapshot(for: series)
        snapshotCache[series.id] = snap
        return snap
    }

    func isPrecached(_ series: FREDSeries) -> Bool {
        snapshotCache[series.id] != nil
    }

    func preloadWatchlist() {
        Task {
            for id in watchlist {
                if let s = series(with: id), snapshotCache[id] == nil {
                    if let snap = try? await client.snapshot(for: s) {
                        snapshotCache[id] = snap
                    }
                }
            }
        }
    }

    func isSaved(_ series: FREDSeries) -> Bool { watchlist.contains(series.id) }

    func toggleSaved(_ series: FREDSeries) {
        if let index = watchlist.firstIndex(of: series.id) { watchlist.remove(at: index) }
        else { watchlist.append(series.id) }
        UserDefaults.standard.set(watchlist, forKey: watchlistKey)
    }

    func series(with id: String) -> FREDSeries? { catalog.first { $0.id == id } }

    func search(_ query: String) async -> [FREDSeries] {
        do {
            let results = try await client.search(query)
            catalog = Array(Set(catalog + results)).sorted { $0.title < $1.title }
            return results
        } catch { return [] }
    }
}
