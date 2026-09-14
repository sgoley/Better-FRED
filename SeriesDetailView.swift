import SwiftUI
import Charts
import UIKit

struct SeriesDetailView: View {
    @EnvironmentObject private var model: AppModel
    let series: FREDSeries
    @State private var snapshot: SeriesSnapshot?
    @State private var displayMode: SeriesDisplayMode = .chart
    @State private var dateRange: ChartDateRange = .oneYear
    @State private var isSmoothed = false
    @State private var showRecessions = true
    @State private var selectedObservation: Observation?
    @State private var zoomDomain: ClosedRange<Date>?
    @State private var showFullscreen = false
    @State private var showToast = false
    @State private var toastMessage: String?
    @State private var exportImage: UIImage?
    @State private var showShareSheet = false
    @State private var showAlerts = false

    private var observations: [Observation] {
        snapshot?.observations ?? []
    }

    private var activeObservation: Observation? {
        selectedObservation ?? observations.last
    }

    private var previousObservation: Observation? {
        if let selected = selectedObservation {
            guard let idx = observations.firstIndex(where: { $0.id == selected.id }), idx > 0 else { return nil }
            return observations[idx - 1]
        }
        return observations.dropLast().last
    }

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                BetterTheme.background.ignoresSafeArea()

                if isLandscape {
                    landscapeLayout(size: proxy.size)
                } else {
                    portraitLayout
                }

                // Toast feedback banner
                if showToast, let message = toastMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(BetterTheme.lime)
                            Text(message)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(BetterTheme.ink.opacity(0.95), in: Capsule())
                        .overlay(Capsule().stroke(BetterTheme.lime.opacity(0.4), lineWidth: 1))
                        .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                        .padding(.top, 16)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenChartView(series: series, observations: snapshot?.observations ?? [])
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportImage {
                ActivityView(activityItems: [exportImage])
            }
        }
        .sheet(isPresented: $showAlerts) {
            SeriesAlertsSheet(series: series, alertService: model.alerts)
        }
        .task {
            snapshot = try? await model.snapshot(for: series)
        }
    }

    // MARK: - Landscape Layout (Edge-to-edge pro visual workstation)
    @ViewBuilder
    private func landscapeLayout(size: CGSize) -> some View {
        VStack(spacing: 8) {
            // Compact Pro Toolbar
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(series.id)
                            .font(.caption.weight(.heavy))
                            .tracking(0.8)
                            .foregroundStyle(BetterTheme.coral)
                        Text("•")
                            .foregroundStyle(Color.white.opacity(0.4))
                        Text(series.frequency)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                    Text(series.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                // Chart / Table view switcher
                Picker("Mode", selection: $displayMode) {
                    Label("Chart", systemImage: "chart.xyaxis.line").tag(SeriesDisplayMode.chart)
                    Label("Table", systemImage: "tablecells").tag(SeriesDisplayMode.table)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)

                // Range presets
                Picker("Range", selection: $dateRange) {
                    ForEach(ChartDateRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: dateRange) { _, _ in zoomDomain = nil }

                // Action buttons
                HStack(spacing: 6) {
                    if displayMode == .chart {
                        Button {
                            withAnimation { isSmoothed.toggle() }
                        } label: {
                            Image(systemName: isSmoothed ? "waveform.path" : "chart.xyaxis.line")
                                .font(.caption2.bold())
                                .padding(6)
                                .background(isSmoothed ? BetterTheme.lime.opacity(0.25) : BetterTheme.surface.opacity(0.12), in: Circle())
                                .foregroundStyle(isSmoothed ? BetterTheme.lime : .white)
                        }

                        Button {
                            withAnimation { showRecessions.toggle() }
                        } label: {
                            Image(systemName: showRecessions ? "checkmark.circle.fill" : "circle")
                                .font(.caption2.bold())
                                .padding(6)
                                .background(showRecessions ? BetterTheme.navy : BetterTheme.surface.opacity(0.12), in: Circle())
                                .foregroundStyle(showRecessions ? BetterTheme.cyan : BetterTheme.mutedOnNavy)
                        }

                        Button { copyChartImage() } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2.bold())
                                .padding(6)
                                .background(BetterTheme.navy, in: Circle())
                                .foregroundStyle(.white)
                        }
                    }

                    Button { exportPNG() } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption2.bold())
                            .padding(6)
                            .background(BetterTheme.cyan, in: Circle())
                            .foregroundStyle(BetterTheme.ink)
                    }

                    Button { showAlerts = true } label: {
                        Image(systemName: "bell.badge")
                            .font(.caption2.bold())
                            .padding(6)
                            .background(BetterTheme.navy, in: Circle())
                            .foregroundStyle(BetterTheme.cyan)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // Content Area: Chart or Table
            if let snapshot {
                if displayMode == .chart {
                    InteractiveFREDChart(
                        series: series,
                        observations: snapshot.observations,
                        isSmoothed: isSmoothed,
                        showRecessions: showRecessions,
                        dateRange: dateRange,
                        zoomDomain: zoomDomain,
                        selectedObservation: $selectedObservation
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                } else {
                    SeriesTableView(
                        series: series,
                        observations: snapshot.observations,
                        dateRange: dateRange
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
    }

    // MARK: - Portrait Layout (Comprehensive indicator overview)
    @ViewBuilder
    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(series.id)
                                .font(.caption.weight(.heavy))
                                .tracking(1.0)
                                .foregroundStyle(BetterTheme.coral)

                            Text("•")
                                .foregroundStyle(Color.white.opacity(0.4))

                            Text(series.frequency)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }

                        Text(series.title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text(series.units)
                            .font(.subheadline)
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }

                    Spacer()

                    Button {
                        model.toggleSaved(series)
                    } label: {
                        Image(systemName: model.isSaved(series) ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .foregroundStyle(BetterTheme.cyan)
                            .padding(8)
                            .background(BetterTheme.navy, in: Circle())
                    }

                    Button {
                        showAlerts = true
                    } label: {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(BetterTheme.cyan)
                            .padding(8)
                            .background(BetterTheme.navy, in: Circle())
                    }
                }

                if let snapshot {
                    // View Mode Switcher: Chart vs Table
                    HStack {
                        Picker("View Mode", selection: $displayMode) {
                            Label("Chart", systemImage: "chart.xyaxis.line").tag(SeriesDisplayMode.chart)
                            Label("Table", systemImage: "tablecells").tag(SeriesDisplayMode.table)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)

                        Spacer()

                        Picker("Range", selection: $dateRange) {
                            ForEach(ChartDateRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                        .onChange(of: dateRange) { _, _ in zoomDomain = nil }
                    }

                    if displayMode == .chart {
                        // Scrubber HUD / Tooltip readout
                        ScrubberHUDView(
                            series: series,
                            activeObservation: activeObservation,
                            previousObservation: previousObservation,
                            isInspecting: selectedObservation != nil
                        )

                        // Main Interactive Chart
                        VStack(spacing: 12) {
                            InteractiveFREDChart(
                                series: series,
                                observations: snapshot.observations,
                                isSmoothed: isSmoothed,
                                showRecessions: showRecessions,
                                dateRange: dateRange,
                                zoomDomain: zoomDomain,
                                selectedObservation: $selectedObservation
                            )
                            .frame(height: 270)

                            // Quick actions row beneath chart (Smoothing, Recessions, Fullscreen)
                            HStack {
                                // Smoothing toggle
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isSmoothed.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: isSmoothed ? "waveform.path" : "chart.xyaxis.line")
                                        Text(isSmoothed ? "Smooth" : "Raw Detail")
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSmoothed ? BetterTheme.lime.opacity(0.2) : BetterTheme.surface.opacity(0.12), in: Capsule())
                                    .foregroundStyle(isSmoothed ? BetterTheme.lime : .white)
                                }

                                // Recessions toggle
                                Button {
                                    withAnimation { showRecessions.toggle() }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: showRecessions ? "checkmark.circle.fill" : "circle")
                                        Text("Recessions")
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(showRecessions ? BetterTheme.navy : BetterTheme.surface.opacity(0.12), in: Capsule())
                                    .foregroundStyle(showRecessions ? BetterTheme.cyan : BetterTheme.mutedOnNavy)
                                }

                                Spacer()

                                // Fullscreen button
                                Button {
                                    showFullscreen = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        Text("Fullscreen")
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(BetterTheme.cyan, in: Capsule())
                                    .foregroundStyle(BetterTheme.ink)
                                }
                            }
                        }

                        // Zoom Step Controls
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Button { zoomIn() } label: {
                                    Image(systemName: "plus.magnifyingglass")
                                        .font(.caption.bold())
                                        .padding(7)
                                        .background(BetterTheme.surface.opacity(0.15), in: Circle())
                                        .foregroundStyle(.white)
                                }
                                Button { zoomOut() } label: {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.caption.bold())
                                        .padding(7)
                                        .background(BetterTheme.surface.opacity(0.15), in: Circle())
                                        .foregroundStyle(.white)
                                }
                                if zoomDomain != nil {
                                    Button("Reset") {
                                        withAnimation { zoomDomain = nil }
                                    }
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(BetterTheme.coral.opacity(0.25), in: Capsule())
                                    .foregroundStyle(BetterTheme.coral)
                                }
                            }
                        }
                    } else {
                        // Table View
                        SeriesTableView(
                            series: series,
                            observations: snapshot.observations,
                            dateRange: dateRange
                        )
                        .frame(height: 520)
                    }

                    // Action Bar: Copy Image, Export PNG, Download CSV
                    HStack(spacing: 12) {
                        Button {
                            copyChartImage()
                        } label: {
                            Label("Copy Image", systemImage: "doc.on.doc")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(BetterTheme.navy, in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }

                        Button {
                            exportPNG()
                        } label: {
                            Label("Export PNG", systemImage: "square.and.arrow.up")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(BetterTheme.cyan, in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(BetterTheme.ink)
                        }

                        ShareLink(item: snapshot.csv, preview: SharePreview("\(series.id) data", image: Image(systemName: "tablecells"))) {
                            Label("CSV", systemImage: "arrow.down.circle")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(BetterTheme.surface.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }
                    }

                    HStack {
                        Text("\(snapshot.observations.count) total observations")
                            .font(.caption)
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                        Spacer()
                        if let first = snapshot.observations.first?.date,
                           let last = snapshot.observations.last?.date {
                            Text("\(first.formatted(date: .numeric, time: .omitted)) to \(last.formatted(date: .numeric, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }
                    }

                    // About Card
                    MetricCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this series").font(.headline)
                            Text(series.description).foregroundStyle(.secondary)
                            Text("Source: \(series.source) • \(series.frequency)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: BetterTheme.cyan))
                            .scaleEffect(1.3)
                        VStack(spacing: 6) {
                            Text("Retrieving \(series.id)...")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Caching all historical dates for instant switching")
                                .font(.caption)
                                .foregroundStyle(BetterTheme.mutedOnNavy)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .background(BetterTheme.navy.opacity(0.4), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(BetterTheme.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
    }

    private func zoomIn() {
        guard let first = observations.first?.date, let last = observations.last?.date else { return }
        let currentDomain = zoomDomain ?? (dateRange.startDate(from: last) ?? first)...last
        let span = currentDomain.upperBound.timeIntervalSince(currentDomain.lowerBound)
        guard span > 86400 * 30 else { return }
        let newSpan = span * 0.65
        let center = currentDomain.lowerBound.addingTimeInterval(span / 2)
        let newStart = center.addingTimeInterval(-newSpan / 2)
        let newEnd = center.addingTimeInterval(newSpan / 2)
        withAnimation { zoomDomain = newStart...newEnd }
    }

    private func zoomOut() {
        guard let first = observations.first?.date, let last = observations.last?.date else { return }
        let currentDomain = zoomDomain ?? (dateRange.startDate(from: last) ?? first)...last
        let span = currentDomain.upperBound.timeIntervalSince(currentDomain.lowerBound)
        let newSpan = span * 1.5
        let center = currentDomain.lowerBound.addingTimeInterval(span / 2)
        let newStart = Swift.max(first, center.addingTimeInterval(-newSpan / 2))
        let newEnd = Swift.min(last, center.addingTimeInterval(newSpan / 2))
        withAnimation { zoomDomain = newStart...newEnd }
    }

    @MainActor
    private func generateExportCard() -> UIImage? {
        let card = ExportableChartCard(
            series: series,
            observations: snapshot?.observations ?? [],
            isSmoothed: isSmoothed,
            showRecessions: showRecessions,
            dateRange: dateRange,
            zoomDomain: zoomDomain
        )
        .frame(width: 820, height: 480)
        .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func copyChartImage() {
        if let image = generateExportCard() {
            UIPasteboard.general.image = image
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showToastBanner("Chart Image Copied to Clipboard!")
        }
    }

    private func exportPNG() {
        if let image = generateExportCard() {
            self.exportImage = image
            self.showShareSheet = true
        }
    }

    private func showToastBanner(_ msg: String) {
        toastMessage = msg
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { showToast = false }
        }
    }
}

private enum AlertDraftKind: String, CaseIterable, Identifiable {
    case newObservation
    case crossesAbove
    case crossesBelow
    case risesBy

    var id: Self { self }

    var label: String {
        switch self {
        case .newObservation: return "Any new observation"
        case .crossesAbove: return "Crosses above X"
        case .crossesBelow: return "Crosses below X"
        case .risesBy: return "Rises by X"
        }
    }

    var needsValue: Bool { self != .newObservation }
}

struct SeriesAlertsSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let series: FREDSeries
    @ObservedObject var alertService: AlertService

    @State private var draftKind: AlertDraftKind = .newObservation
    @State private var thresholdText = ""
    @State private var keepMonitoring = true
    @State private var isSaving = false
    @State private var statusMessage: String?

    private var rules: [AlertRule] {
        alertService.rules(for: series.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: alertService.authorizationStatus.canDeliver ? "bell.badge.fill" : "bell.slash.fill")
                            .foregroundStyle(alertService.authorizationStatus.canDeliver ? BetterTheme.cyan : BetterTheme.coral)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(alertService.authorizationStatus.canDeliver ? "Local alerts enabled" : "Notification permission needed")
                                .font(.subheadline.weight(.semibold))
                            Text(alertService.authorizationStatus.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !alertService.authorizationStatus.canDeliver {
                        Button("Enable Notifications") {
                            Task {
                                let granted = await model.requestAlertAuthorization()
                                statusMessage = granted ? "Notifications enabled." : alertService.authorizationStatus.description
                            }
                        }
                    }
                } header: {
                    Text("Delivery")
                } footer: {
                    Text("Alerts are evaluated on app launch and when iOS grants BetterEcon a background refresh. They are not real-time push notifications.")
                }

                Section("Your alerts") {
                    if rules.isEmpty {
                        Text("No alerts for \(series.id) yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rules) { rule in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(rule.trigger.alertDisplayDescription)
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                    if rule.isOneShot {
                                        Text("ONE TIME")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(BetterTheme.coral)
                                    }
                                }
                                Toggle("Enabled", isOn: Binding(
                                    get: { rule.isEnabled },
                                    set: { enabled in
                                        Task {
                                            await model.setAlert(id: rule.id, enabled: enabled, for: series)
                                        }
                                    }
                                ))
                                .font(.caption)

                                if let lastTriggeredDate = rule.lastTriggeredDate {
                                    Text("Last triggered for \(lastTriggeredDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                        .onDelete { offsets in
                            let ruleIDs = offsets.map { rules[$0].id }
                            for ruleID in ruleIDs {
                                model.removeAlert(id: ruleID)
                            }
                        }
                    }
                }

                Section("Add an alert") {
                    Picker("When", selection: $draftKind) {
                        ForEach(AlertDraftKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }

                    if draftKind.needsValue {
                        TextField(draftKind == .risesBy ? "Change amount" : "Threshold", text: $thresholdText)
                            .keyboardType(.decimalPad)
                        Text("Values use the raw FRED reading in \(series.units).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Keep monitoring after it triggers", isOn: $keepMonitoring)
                    Text(keepMonitoring
                         ? "This alert remains enabled after each qualifying release."
                         : "This alert disables itself after its first notification.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        saveRule()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().padding(.trailing, 4)
                            }
                            Label("Add Alert", systemImage: "bell.badge.fill")
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(statusMessage == "Alert added." ? BetterTheme.sage : BetterTheme.coral)
                    }
                }
            }
            .navigationTitle("\(series.id) Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await alertService.refreshAuthorizationStatus()
            }
            .onChange(of: draftKind) { _, newValue in
                keepMonitoring = newValue == .newObservation
                statusMessage = nil
            }
        }
    }

    private func saveRule() {
        guard let trigger = makeTrigger() else {
            statusMessage = "Enter a valid decimal value for this alert."
            return
        }

        Task {
            isSaving = true
            defer { isSaving = false }

            if !alertService.authorizationStatus.canDeliver {
                let granted = await model.requestAlertAuthorization()
                guard granted else {
                    statusMessage = alertService.authorizationStatus.description
                    return
                }
            }

            _ = await model.createAlert(
                for: series,
                trigger: trigger,
                isOneShot: !keepMonitoring
            )
            thresholdText = ""
            statusMessage = "Alert added."
        }
    }

    private func makeTrigger() -> AlertTrigger? {
        switch draftKind {
        case .newObservation:
            return .newObservation
        case .crossesAbove:
            guard let value = decimalThreshold else { return nil }
            return .comparison(.greaterThanOrEqual, threshold: value)
        case .crossesBelow:
            guard let value = decimalThreshold else { return nil }
            return .comparison(.lessThanOrEqual, threshold: value)
        case .risesBy:
            guard let value = decimalThreshold else { return nil }
            return .change(.greaterThanOrEqual, delta: value)
        }
    }

    private var decimalThreshold: Decimal? {
        let input = thresholdText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }
        return Decimal(string: input, locale: Locale(identifier: "en_US_POSIX"))
    }
}

private extension SeriesSnapshot {
    var csv: String {
        (["date,value"] + observations.map { "\($0.date.ISO8601Format()),\($0.value)" }).joined(separator: "\n")
    }
}
