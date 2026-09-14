import Foundation
import UserNotifications

protocol FREDDataProviding {
    func search(_ query: String) async throws -> [FREDSeries]
    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot
    /// Returns a small, chronological window of valid reported observations.
    /// This must be used by alert monitoring instead of downloading chart history.
    func latestObservations(for seriesID: String, limit: Int) async throws -> [Observation]
}

struct PreviewFREDClient: FREDDataProviding {
    func search(_ query: String) async throws -> [FREDSeries] {
        PopularSeries.search(query: query)
    }

    func snapshot(for series: FREDSeries) async throws -> SeriesSnapshot {
        SeriesSnapshot(series: series, observations: SampleData.observations(for: series))
    }

    func latestObservations(for seriesID: String, limit: Int) async throws -> [Observation] {
        guard let series = SampleData.series.first(where: { $0.id == seriesID }) else { return [] }
        return Array(SampleData.observations(for: series).suffix(Swift.max(1, limit)))
    }
}

struct FREDAPIClient: FREDDataProviding {
    let apiKey: String
    let session: URLSession = .shared
    private let decoder = JSONDecoder()

    func search(_ query: String) async throws -> [FREDSeries] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return [] }
        var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/search")!
        components.queryItems = [
            URLQueryItem(name: "search_text", value: clean),
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
        let points = try await observations(for: series.id)
        return SeriesSnapshot(series: series, observations: points)
    }

    func latestObservations(for seriesID: String, limit: Int) async throws -> [Observation] {
        // FRED sends missing values as ".". Fetch a small window rather than a
        // single point so daily/holiday series still yield the newest numeric value.
        try await observations(
            for: seriesID,
            limit: Swift.max(1, limit),
            sortOrder: "desc"
        )
    }

    private func observations(
        for seriesID: String,
        limit: Int? = nil,
        sortOrder: String? = nil
    ) async throws -> [Observation] {
        var components = URLComponents(string: "https://api.stlouisfed.org/fred/series/observations")!
        var queryItems = [
            URLQueryItem(name: "series_id", value: seriesID),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_type", value: "json")
        ]
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let sortOrder {
            queryItems.append(URLQueryItem(name: "sort_order", value: sortOrder))
        }
        components.queryItems = queryItems
        let (data, response) = try await session.data(from: components.url!)
        try validate(response, data: data)
        let decoded = try decoder.decode(FREDObservationsResponse.self, from: data)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let points = decoded.observations.compactMap { item -> Observation? in
            guard let date = formatter.date(from: item.date),
                  let exactValue = Decimal(string: item.value, locale: Locale(identifier: "en_US_POSIX")),
                  let value = Double(item.value) else { return nil }
            return Observation(date: date, value: value, decimalValue: exactValue)
        }
        return points.sorted { $0.date < $1.date }
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

// MARK: - Local alert delivery

protocol NotificationDelivering {
    func requestAuthorization() async throws -> Bool
    func authorizationStatus() async -> AlertAuthorizationStatus
    func deliver(title: String, body: String, userInfo: [AnyHashable: Any]) async throws
}

enum AlertAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied

    var canDeliver: Bool { self == .authorized }

    var description: String {
        switch self {
        case .notDetermined: return "Notifications have not been enabled yet."
        case .authorized: return "Notifications are enabled."
        case .denied: return "Notifications are off. Enable them in Settings to receive alerts."
        }
    }
}

struct LocalNotificationDelivery: NotificationDelivering {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func authorizationStatus() async -> AlertAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func deliver(title: String, body: String, userInfo: [AnyHashable: Any]) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: "betterecon.alert.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }
}

@MainActor
final class AlertService: ObservableObject {
    @Published private(set) var rules: [AlertRule]
    @Published private(set) var authorizationStatus: AlertAuthorizationStatus = .notDetermined
    @Published private(set) var lastEvaluationError: String?

    private var cursors: [String: AlertCursor]
    private let defaults: UserDefaults
    private let notificationDelivery: NotificationDelivering
    private let rulesKey = "betterecon.alertRules"
    private let cursorsKey = "betterecon.alertCursors"

    init(
        defaults: UserDefaults = .standard,
        notificationDelivery: NotificationDelivering = LocalNotificationDelivery()
    ) {
        self.defaults = defaults
        self.notificationDelivery = notificationDelivery
        self.rules = Self.load([AlertRule].self, key: "betterecon.alertRules", from: defaults) ?? []
        self.cursors = Self.load([String: AlertCursor].self, key: "betterecon.alertCursors", from: defaults) ?? [:]
    }

    var activeSeriesIDs: Set<String> {
        Set(rules.lazy.filter(\.isEnabled).map(\.seriesID))
    }

    var hasActiveRules: Bool { !activeSeriesIDs.isEmpty }

    func rules(for seriesID: String) -> [AlertRule] {
        rules.filter { $0.seriesID == seriesID }
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await notificationDelivery.authorizationStatus()
    }

    func requestNotificationAuthorization() async -> Bool {
        do {
            let granted = try await notificationDelivery.requestAuthorization()
            await refreshAuthorizationStatus()
            return granted && authorizationStatus.canDeliver
        } catch {
            lastEvaluationError = "Unable to request notification permission: \(error.localizedDescription)"
            await refreshAuthorizationStatus()
            return false
        }
    }

    @discardableResult
    func addRule(
        seriesID: String,
        trigger: AlertTrigger,
        isOneShot: Bool,
        baseline: Observation?
    ) -> AlertRule {
        let rule = AlertRule(seriesID: seriesID, trigger: trigger, isOneShot: isOneShot)
        rules.append(rule)
        // A cursor is a series-wide checkpoint. If another rule already has one,
        // AppModel evaluates it before adding a rule so no observation is skipped.
        if cursors[seriesID] == nil, let baseline {
            cursors[seriesID] = AlertCursor(
                seriesID: seriesID,
                lastSeenObservationDate: baseline.date,
                lastSeenValue: baseline.decimalValue
            )
        }
        persist()
        return rule
    }

    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        persistRules()
    }

    func setRuleEnabled(id: UUID, isEnabled: Bool, baseline: Observation?) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].isEnabled = isEnabled
        if isEnabled, cursors[rules[index].seriesID] == nil, let baseline {
            cursors[rules[index].seriesID] = AlertCursor(
                seriesID: rules[index].seriesID,
                lastSeenObservationDate: baseline.date,
                lastSeenValue: baseline.decimalValue
            )
        }
        persist()
    }

    /// Fetches only a recent raw-observation window for each active series. A missing
    /// cursor means the first fetch establishes a baseline and intentionally alerts
    /// on nothing historical.
    @discardableResult
    func evaluate(
        using client: FREDDataProviding,
        seriesByID: [String: FREDSeries]
    ) async -> Bool {
        await refreshAuthorizationStatus()
        guard authorizationStatus.canDeliver else {
            lastEvaluationError = authorizationStatus.description
            return false
        }

        let seriesIDs = activeSeriesIDs.sorted()
        guard !seriesIDs.isEmpty else {
            lastEvaluationError = nil
            return true
        }

        var errors = [String]()
        var didFetchAtLeastOneSeries = false

        for seriesID in seriesIDs {
            guard !Task.isCancelled else { return false }
            do {
                let observations = try await client.latestObservations(for: seriesID, limit: 5)
                didFetchAtLeastOneSeries = true
                await evaluate(
                    seriesID: seriesID,
                    observations: observations,
                    series: seriesByID[seriesID]
                )
            } catch {
                errors.append("\(seriesID): \(error.localizedDescription)")
            }
        }

        lastEvaluationError = errors.isEmpty ? nil : errors.joined(separator: "\n")
        return didFetchAtLeastOneSeries
    }

    private func evaluate(
        seriesID: String,
        observations: [Observation],
        series: FREDSeries?
    ) async {
        let observations = observations.sorted { $0.date < $1.date }
        guard let newest = observations.last else { return }

        guard let cursor = cursors[seriesID] else {
            cursors[seriesID] = AlertCursor(
                seriesID: seriesID,
                lastSeenObservationDate: newest.date,
                lastSeenValue: newest.decimalValue
            )
            persistCursors()
            return
        }

        let unseen = observations.filter { observation in
            observation.date > cursor.lastSeenObservationDate
                || (observation.date == cursor.lastSeenObservationDate
                    && observation.decimalValue != cursor.lastSeenValue)
        }
        guard !unseen.isEmpty else { return }

        var pendingAlerts = [PendingAlert]()
        var oneShotRuleIDs = Set<UUID>()

        for observation in unseen {
            let priorValue = precedingValue(
                for: observation,
                in: observations,
                cursor: cursor
            )
            for rule in rules where rule.seriesID == seriesID && rule.isEnabled {
                guard !oneShotRuleIDs.contains(rule.id),
                      shouldTrigger(rule.trigger, observation: observation, priorValue: priorValue) else { continue }
                pendingAlerts.append(PendingAlert(rule: rule, observation: observation, series: series))
                if rule.isOneShot {
                    oneShotRuleIDs.insert(rule.id)
                }
            }
        }

        // Advance the durable cursor before scheduling notification delivery. That
        // prevents duplicate alerts when the app is interrupted after a notification
        // is accepted by the system but before the next refresh begins.
        cursors[seriesID] = AlertCursor(
            seriesID: seriesID,
            lastSeenObservationDate: newest.date,
            lastSeenValue: newest.decimalValue
        )
        for pending in pendingAlerts {
            guard let index = rules.firstIndex(where: { $0.id == pending.rule.id }) else { continue }
            rules[index].lastTriggeredDate = pending.observation.date
            if rules[index].isOneShot {
                rules[index].isEnabled = false
            }
        }
        persist()

        guard authorizationStatus.canDeliver else { return }
        for pending in pendingAlerts {
            guard !Task.isCancelled else { return }
            do {
                try await notificationDelivery.deliver(
                    title: "\(pending.series?.title ?? pending.rule.seriesID) alert",
                    body: notificationBody(for: pending),
                    userInfo: ["seriesID": pending.rule.seriesID]
                )
            } catch {
                lastEvaluationError = "Unable to schedule an alert: \(error.localizedDescription)"
            }
        }
    }

    private func precedingValue(
        for observation: Observation,
        in observations: [Observation],
        cursor: AlertCursor
    ) -> Decimal? {
        if observation.date == cursor.lastSeenObservationDate {
            return cursor.lastSeenValue
        }
        if let index = observations.firstIndex(where: {
            $0.date == observation.date && $0.decimalValue == observation.decimalValue
        }), index > 0 {
            return observations[index - 1].decimalValue
        }
        return cursor.lastSeenValue
    }

    private func shouldTrigger(
        _ trigger: AlertTrigger,
        observation: Observation,
        priorValue: Decimal?
    ) -> Bool {
        switch trigger {
        case .newObservation:
            return true
        case let .comparison(op, threshold):
            // Threshold alerts are crossing-based: a reading has to newly satisfy
            // the condition relative to the prior raw reading (or same-date revision).
            guard op.matches(observation.decimalValue, threshold) else { return false }
            return priorValue.map { !op.matches($0, threshold) } ?? true
        case let .change(op, delta):
            guard let priorValue else { return false }
            return op.matches(observation.decimalValue - priorValue, delta)
        }
    }

    private func notificationBody(for pending: PendingAlert) -> String {
        let value = NSDecimalNumber(decimal: pending.observation.decimalValue).stringValue
        let date = pending.observation.date.formatted(date: .abbreviated, time: .omitted)
        return "\(pending.rule.seriesID) reported \(value)\(pending.series?.units == "Percent" ? "%" : "") on \(date). \(pending.rule.trigger.notificationDescription)"
    }

    private func persist() {
        persistRules()
        persistCursors()
    }

    private func persistRules() {
        Self.save(rules, key: rulesKey, to: defaults)
    }

    private func persistCursors() {
        Self.save(cursors, key: cursorsKey, to: defaults)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T, key: String, to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}

private struct PendingAlert {
    let rule: AlertRule
    let observation: Observation
    let series: FREDSeries?
}

extension AlertTrigger {
    var notificationDescription: String {
        switch self {
        case .newObservation:
            return "New observation received."
        case let .comparison(op, threshold):
            return "Crossed \(op.rawValue) \(threshold.alertDisplayValue)."
        case let .change(op, delta):
            return "Changed \(op.rawValue) \(delta.alertDisplayValue) from the prior observation."
        }
    }

    var alertDisplayDescription: String {
        switch self {
        case .newObservation:
            return "Any new observation"
        case let .comparison(op, threshold):
            return "Crosses \(op.rawValue) \(threshold.alertDisplayValue)"
        case let .change(op, delta):
            return "Change \(op.rawValue) \(delta.alertDisplayValue)"
        }
    }
}

private extension Decimal {
    var alertDisplayValue: String {
        NSDecimalNumber(decimal: self).stringValue
    }
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
    @Published var isSearchingRemote: Bool = false

    /// Alert state lives independently from chart/cache state so notification
    /// evaluation can remain lightweight and persist across app launches.
    let alerts = AlertService()

    private var searchCache: [String: [FREDSeries]] = [:]
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

    func prepareAlertMonitoring() async {
        await alerts.refreshAuthorizationStatus()
        AlertBackgroundScheduler.shared.scheduleIfNeeded(hasActiveRules: alerts.hasActiveRules)
        guard alerts.hasActiveRules else { return }
        _ = await refreshAlertRules()
    }

    @discardableResult
    func refreshAlertRules() async -> Bool {
        let seriesByID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        let didFetch = await alerts.evaluate(using: client, seriesByID: seriesByID)
        AlertBackgroundScheduler.shared.scheduleIfNeeded(hasActiveRules: alerts.hasActiveRules)
        return didFetch
    }

    func requestAlertAuthorization() async -> Bool {
        await alerts.requestNotificationAuthorization()
    }

    @discardableResult
    func createAlert(
        for series: FREDSeries,
        trigger: AlertTrigger,
        isOneShot: Bool
    ) async -> AlertRule {
        // Preserve existing rules' observations before establishing the new rule's
        // baseline. This makes adding an alert unable to hide a pending alert.
        if alerts.hasActiveRules {
            _ = await refreshAlertRules()
        }
        let baseline = try? await client.latestObservations(for: series.id, limit: 5).last
        let rule = alerts.addRule(
            seriesID: series.id,
            trigger: trigger,
            isOneShot: isOneShot,
            baseline: baseline
        )
        AlertBackgroundScheduler.shared.scheduleIfNeeded(hasActiveRules: alerts.hasActiveRules)
        return rule
    }

    func removeAlert(id: UUID) {
        alerts.removeRule(id: id)
        AlertBackgroundScheduler.shared.scheduleIfNeeded(hasActiveRules: alerts.hasActiveRules)
    }

    func setAlert(id: UUID, enabled: Bool, for series: FREDSeries) async {
        if enabled, alerts.hasActiveRules {
            _ = await refreshAlertRules()
        }
        let baseline = enabled ? try? await client.latestObservations(for: series.id, limit: 5).last : nil
        alerts.setRuleEnabled(id: id, isEnabled: enabled, baseline: baseline)
        AlertBackgroundScheduler.shared.scheduleIfNeeded(hasActiveRules: alerts.hasActiveRules)
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
            self.searchCache.removeAll()
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
        self.searchCache.removeAll()
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
        searchCache.removeAll()
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

    /// Notification taps can refer to a series discovered through remote search in
    /// an earlier launch. Resolve it again on demand before routing to its detail.
    func resolveSeries(with id: String) async -> FREDSeries? {
        if let cached = series(with: id) { return cached }
        guard let found = try? await client.search(id).first(where: { $0.id == id }) else { return nil }
        catalog.append(found)
        return found
    }

    /// Instant, zero-latency synchronous local search across the pre-cached catalog.
    func localMatches(for query: String, category: SeriesCategory = .all) -> [FREDSeries] {
        let baseList: [FREDSeries]
        if category == .all {
            baseList = catalog
        } else {
            let categorySeriesIds = Set(PopularSeries.series(in: category).map(\.id))
            baseList = catalog.filter { categorySeriesIds.contains($0.id) }
        }
        return PopularSeries.search(query: query, in: baseList)
    }

    /// Hybrid search:
    /// 1. Immediately returns cached query results if available.
    /// 2. If live and not cached, fetches remote FRED results, merges new series into catalog,
    ///    caches the combined result, and returns.
    /// 3. Falls back gracefully to local matches on failure or offline.
    func search(_ query: String, category: SeriesCategory = .all) async -> [FREDSeries] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return localMatches(for: "", category: category)
        }

        let cacheKey = "\(category.rawValue):\(trimmed.lowercased())"
        if let cached = searchCache[cacheKey] {
            return cached
        }

        guard isLive else {
            let local = localMatches(for: trimmed, category: category)
            searchCache[cacheKey] = local
            return local
        }

        isSearchingRemote = true
        defer { isSearchingRemote = false }

        do {
            let remote = try await client.search(trimmed)
            let existingIDs = Set(catalog.map(\.id))
            let newSeries = remote.filter { !existingIDs.contains($0.id) }
            if !newSeries.isEmpty {
                catalog.append(contentsOf: newSeries)
            }

            let local = localMatches(for: trimmed, category: category)
            let localIDs = Set(local.map(\.id))
            let uniqueRemote = remote.filter { !localIDs.contains($0.id) }
            let combined = local + uniqueRemote

            searchCache[cacheKey] = combined
            return combined
        } catch {
            return localMatches(for: trimmed, category: category)
        }
    }
}
