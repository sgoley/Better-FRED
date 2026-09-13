import SwiftUI
import Charts
import UIKit

struct FullscreenChartView: View {
    @Environment(\.dismiss) private var dismiss
    let series: FREDSeries
    let observations: [Observation]

    @State private var displayMode: SeriesDisplayMode = .chart
    @State private var isSmoothed = false
    @State private var showRecessions = true
    @State private var dateRange: ChartDateRange = .max
    @State private var selectedObservation: Observation?
    @State private var zoomDomain: ClosedRange<Date>?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var exportImage: UIImage?
    @State private var showShareSheet = false

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
                    landscapeView(size: proxy.size)
                } else {
                    portraitView
                }

                // Toast overlay
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
                        .padding(.top, 14)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportImage {
                ActivityView(activityItems: [exportImage])
            }
        }
    }

    // MARK: - Landscape Fullscreen View
    @ViewBuilder
    private func landscapeView(size: CGSize) -> some View {
        VStack(spacing: 6) {
            // Unified Floating Top Control Bar
            HStack(alignment: .center, spacing: 10) {
                // Series ID & Title
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
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                // Chart / Table switcher
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

                // Quick toggles & actions
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

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            // Content: Chart or Table
            if displayMode == .chart {
                InteractiveFREDChart(
                    series: series,
                    observations: observations,
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
                    observations: observations,
                    dateRange: dateRange
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - Portrait Fullscreen View
    @ViewBuilder
    private var portraitView: some View {
        VStack(spacing: 14) {
            // Top control bar
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(series.id)
                            .font(.caption.weight(.bold))
                            .tracking(1.0)
                            .foregroundStyle(BetterTheme.coral)

                        Text("FULLSCREEN")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BetterTheme.navy)
                            .foregroundStyle(BetterTheme.cyan)
                            .cornerRadius(4)
                    }
                    Text(series.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    if displayMode == .chart {
                        Button { copyChartImage() } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption.weight(.semibold))
                                .padding(8)
                                .background(BetterTheme.navy, in: Circle())
                                .foregroundStyle(.white)
                        }
                    }

                    Button { exportPNG() } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                            .padding(8)
                            .background(BetterTheme.cyan, in: Circle())
                            .foregroundStyle(BetterTheme.ink)
                    }

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(BetterTheme.mutedOnNavy)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // View Mode Switcher
            HStack {
                Picker("Mode", selection: $displayMode) {
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
            .padding(.horizontal)

            if displayMode == .chart {
                // Scrubber HUD
                ScrubberHUDView(
                    series: series,
                    activeObservation: activeObservation,
                    previousObservation: previousObservation,
                    isInspecting: selectedObservation != nil
                )
                .padding(.horizontal)

                // Interactive Chart
                InteractiveFREDChart(
                    series: series,
                    observations: observations,
                    isSmoothed: isSmoothed,
                    showRecessions: showRecessions,
                    dateRange: dateRange,
                    zoomDomain: zoomDomain,
                    selectedObservation: $selectedObservation
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal)

                // Bottom Controls
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSmoothed.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isSmoothed ? "waveform.path" : "chart.xyaxis.line")
                            Text(isSmoothed ? "Smooth" : "Raw Detail")
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSmoothed ? BetterTheme.lime.opacity(0.25) : BetterTheme.surface.opacity(0.12), in: Capsule())
                        .foregroundStyle(isSmoothed ? BetterTheme.lime : .white)
                    }

                    Button {
                        withAnimation { showRecessions.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showRecessions ? "checkmark.circle.fill" : "circle")
                            Text("Recessions")
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(showRecessions ? BetterTheme.navy : BetterTheme.surface.opacity(0.12), in: Capsule())
                        .foregroundStyle(showRecessions ? BetterTheme.cyan : BetterTheme.mutedOnNavy)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Button { zoomIn() } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.caption.weight(.bold))
                                .padding(8)
                                .background(BetterTheme.surface.opacity(0.15), in: Circle())
                                .foregroundStyle(.white)
                        }

                        Button { zoomOut() } label: {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.caption.weight(.bold))
                                .padding(8)
                                .background(BetterTheme.surface.opacity(0.15), in: Circle())
                                .foregroundStyle(.white)
                        }

                        if zoomDomain != nil {
                            Button("Reset") {
                                withAnimation { zoomDomain = nil }
                            }
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(BetterTheme.coral.opacity(0.25), in: Capsule())
                            .foregroundStyle(BetterTheme.coral)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            } else {
                // Table View in Fullscreen
                SeriesTableView(
                    series: series,
                    observations: observations,
                    dateRange: dateRange
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
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
            observations: observations,
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

// MARK: - Activity View for PNG sharing
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
