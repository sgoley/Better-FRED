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
        components.queryItems = [
            URLQueryItem(name: "search_text", value: query),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_type", value: "json")
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response, data: data)
        let decoded = try decoder.decode(FREDSearchResponse.self, from: data)
        return decoded.seriess.map {
            FREDSeries(
                id: $0.id,
                title: $0.title,
                units: $0.units ?? "Value",
                frequency: $0.frequency ?? "Period",
                source: "St. Louis Fed (FRED®)",
                description: $0.notes ?? ""
            )
        }
    }

    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot {
        var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/observations")!
        components.queryItems = [
            URLQueryItem(name: "series_id", value: series.id),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_type", value: "json")
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response, data: data)
        let decoded = try decoder.decode(FREDObservationsResponse.self, from: data)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let points = decoded.observations.compactMap { item -> Observation? in
            guard let date = formatter.date(from: item.date),
                  let value = Double(item.value) else { return nil }
            return Observation(date: date, value: value)
        }
        return SeriesSnapshot(series: series, observations: points)
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard 200..<300 ~= http.statusCode else {
            if let errResp = try? decoder.decode(FREDErrorResponse.self, from: data) {
                throw NSError(domain: "FREDAPIError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errResp.errorMessage])
            }
            throw URLError(.badServerResponse)
        }
    }
}

private struct FREDErrorResponse: Decodable {
    let errorCode: Int?
    let errorMessage: String

    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case errorMessage = "error_message"
    }
}

private struct FREDSearchResponse: Decodable {
    let seriess: [FREDSearchSeries]
}

private struct FREDSearchSeries: Decodable {
    let id: String
    let title: String
    let units: String?
    let frequency: String?
    let notes: String?
}

private struct FREDObservationsResponse: Decodable {
    let observations: [FREDObservation]
}

private struct FREDObservation: Decodable {
    let date: String
    let value: String
}

@MainActor
final class AppModel: ObservableObject {
    @Published var watchlist: [String] = []
    @Published private(set) var catalog: [FREDSeries] = SampleData.series
    @Published private(set) var client: FREDDataProviding
    @Published var apiKey: String = ""
    @Published var isLive: Bool = false
    @Published var loadingSeriesIDs: Set<String> = []
    @Published private(set) var snapshots: [String: SeriesSnapshot] = [:]

    private let watchlistKey = "betterecon.watchlist"

    init() {
        let initialKey = Self.resolveInitialKey()
        self.apiKey = initialKey ?? ""
        if let initialKey, !initialKey.isEmpty {
            self.client = FREDAPIClient(apiKey: initialKey)
            self.isLive = true
        } else {
            self.client = PreviewFREDClient()
            self.isLive = false
        }

        var list = UserDefaults.standard.stringArray(forKey: watchlistKey)
            ?? UserDefaults.standard.stringArray(forKey: "betterfred.watchlist")
            ?? ["MORTGAGE30US", "CPIAUCSL", "UNRATE", "FEDFUNDS", "DGS10", "GDPC1"]
        if !list.contains("MORTGAGE30US") {
            list.insert("MORTGAGE30US", at: 0)
        }
        watchlist = list
        preloadWatchlist()
    }

    private static func resolveInitialKey() -> String? {
        if let stored = KeychainHelper.loadKey(), !stored.isEmpty {
            return stored
        }
        if let envKey = ProcessInfo.processInfo.environment["FRED_API_KEY"], !envKey.isEmpty {
            _ = KeychainHelper.saveKey(envKey)
            return envKey
        }
        // If developing locally and a .env file exists in the current directory, seed Keychain
        let localEnvURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".env")
        if let content = try? String(contentsOf: localEnvURL, encoding: .utf8) {
            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("FRED_API_KEY=") {
                    let key = String(trimmed.dropFirst("FRED_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !key.isEmpty {
                        _ = KeychainHelper.saveKey(key)
                        return key
                    }
                }
            }
        }
        return nil
    }

    func updateAPIKey(_ newKey: String) async -> (success: Bool, message: String) {
        let clean = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            _ = KeychainHelper.deleteKey()
            self.apiKey = ""
            self.client = PreviewFREDClient()
            self.isLive = false
            self.snapshots.removeAll()
            preloadWatchlist()
            return (true, "Switched to local preview mode.")
        }

        // Test the key against FRED API before committing
        let testResult = await testCandidateKey(clean)
        guard testResult.isValid else {
            return (false, testResult.message)
        }

        _ = KeychainHelper.saveKey(clean)
        self.apiKey = clean
        self.client = FREDAPIClient(apiKey: clean)
        self.isLive = true
        self.snapshots.removeAll()
        preloadWatchlist()
        return (true, "Key verified and securely saved to Keychain.")
    }

    func testCandidateKey(_ candidateKey: String) async -> (isValid: Bool, message: String) {
        let clean = candidateKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return (false, "API key cannot be empty.")
        }

        guard var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/observations") else {
            return (false, "Invalid URL structure.")
        }
        components.queryItems = [
            URLQueryItem(name: "series_id", value: "FEDFUNDS"),
            URLQueryItem(name: "api_key", value: clean),
            URLQueryItem(name: "file_type", value: "json"),
            URLQueryItem(name: "limit", value: "1")
        ]

        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            guard let http = response as? HTTPURLResponse else {
                return (false, "No response from FRED server.")
            }
            if http.statusCode == 200 {
                return (true, "Connected to FRED API successfully!")
            } else {
                if let errResp = try? JSONDecoder().decode(FREDErrorResponse.self, from: data) {
                    return (false, errResp.errorMessage)
                }
                return (false, "HTTP \(http.statusCode): Server rejected API key.")
            }
        } catch {
            return (false, "Connection error: \(error.localizedDescription)")
        }
    }

    func clearCache() {
        snapshots.removeAll()
        preloadWatchlist()
    }

    func cachedSnapshot(for id: String) -> SeriesSnapshot? {
        snapshots[id]
    }

    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot {
        if let cached = snapshots[series.id] {
            return cached
        }
        loadingSeriesIDs.insert(series.id)
        defer { loadingSeriesIDs.remove(series.id) }

        let snap = try await client.snapshot(for: series)
        snapshots[series.id] = snap
        return snap
    }

    func isPrecached(_ series: FREDSeries) -> Bool {
        snapshots[series.id] != nil
    }

    func preloadWatchlist() {
        Task {
            for id in watchlist {
                if let s = series(with: id), snapshots[id] == nil {
                    if let snap = try? await client.snapshot(for: s) {
                        snapshots[id] = snap
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
