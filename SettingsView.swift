import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var inputKey: String = ""
    @State private var isRevealed: Bool = false
    @State private var isTesting: Bool = false
    @State private var testStatusMessage: String?
    @State private var isTestSuccessful: Bool?
    @State private var isSaving: Bool = false
    @State private var saveSuccessToast: String?
    @State private var showRemoveConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Badge Card
                    statusCard

                    // API Key Form Card
                    apiKeyFormCard

                    // How to Get a Key
                    instructionsCard

                    // Cache & Data Management
                    cacheManagementCard

                    // Privacy & Security Guarantee
                    securityCard

                    // Legal / Attribution
                    attributionCard
                }
                .padding()
            }
            .background(BetterTheme.background.ignoresSafeArea())
            .navigationTitle("Settings & API")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.bold))
                    .foregroundStyle(BetterTheme.cyan)
                }
            }
            .onAppear {
                inputKey = model.apiKey
            }
        }
    }

    // MARK: - Status Badge Card
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(model.isLive ? BetterTheme.lime : BetterTheme.coral)
                    .frame(width: 10, height: 10)
                Text(model.isLive ? "LIVE FRED® API ACTIVE" : "OFFLINE PREVIEW MODE")
                    .font(.caption.weight(.heavy))
                    .tracking(1.0)
                    .foregroundStyle(model.isLive ? BetterTheme.lime : BetterTheme.coral)
                Spacer()
                Text(model.isLive ? "Key: Saved in Keychain" : "Synthetic Datasets")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BetterTheme.mutedOnNavy)
            }

            Text(model.isLive
                 ? "Better US Econ Data is pulling live, real-time macroeconomic observations directly from the Federal Reserve Bank of St. Louis."
                 : "You are currently viewing bundled preview datasets. Add your free FRED® API key below to unlock 800,000+ live economic data series.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BetterTheme.navy.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(model.isLive ? BetterTheme.lime.opacity(0.3) : BetterTheme.coral.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - API Key Configuration Card
    private var apiKeyFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(BetterTheme.cyan)
                Text("FRED® API Key (BYOK)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Input Field with Reveal / Paste Controls
            HStack(spacing: 8) {
                Group {
                    if isRevealed {
                        TextField("Paste 32-character API key", text: $inputKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("Paste 32-character API key", text: $inputKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(BetterTheme.ink.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BetterTheme.hairline, lineWidth: 1))

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                        .font(.body)
                        .foregroundStyle(BetterTheme.mutedOnNavy)
                        .padding(10)
                        .background(BetterTheme.navy, in: Circle())
                }

                Button {
                    if let clip = UIPasteboard.general.string {
                        inputKey = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.body)
                        .foregroundStyle(BetterTheme.cyan)
                        .padding(10)
                        .background(BetterTheme.navy, in: Circle())
                }
            }

            // Test Feedback Banner
            if let testStatusMessage, let isTestSuccessful {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isTestSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isTestSuccessful ? BetterTheme.lime : BetterTheme.coral)
                    Text(testStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isTestSuccessful ? BetterTheme.lime : BetterTheme.coral)
                    Spacer()
                }
                .padding(10)
                .background(
                    (isTestSuccessful ? BetterTheme.lime : BetterTheme.coral).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Test Connection Button
                Button {
                    Task {
                        isTesting = true
                        testStatusMessage = nil
                        let res = await model.testCandidateKey(inputKey)
                        isTesting = false
                        isTestSuccessful = res.isValid
                        testStatusMessage = res.message
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isTesting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "network")
                        }
                        Text("Test Connection")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BetterTheme.navy, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .disabled(inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                Spacer()

                // Save Key Button
                Button {
                    Task {
                        isSaving = true
                        let res = await model.updateAPIKey(inputKey)
                        isSaving = false
                        isTestSuccessful = res.success
                        testStatusMessage = res.message
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isSaving {
                            ProgressView().tint(BetterTheme.ink).scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Save Key")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(BetterTheme.cyan, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(BetterTheme.ink)
                }
                .disabled(inputKey == model.apiKey && model.isLive || isSaving)
            }

            // Option to Remove Key / Return to Preview Mode
            if model.isLive {
                Divider().background(BetterTheme.hairline).padding(.top, 4)

                Button(role: .destructive) {
                    showRemoveConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Remove Key & Return to Preview Mode")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(BetterTheme.coral)
                }
                .confirmationDialog("Remove API Key?", isPresented: $showRemoveConfirmation) {
                    Button("Remove & Switch to Preview Mode", role: .destructive) {
                        Task {
                            inputKey = ""
                            _ = await model.updateAPIKey("")
                            testStatusMessage = "Switched to preview mode."
                            isTestSuccessful = true
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Your key will be securely removed from Keychain. The app will fall back to local preview datasets.")
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BetterTheme.navy.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BetterTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - How to Get a Free Key
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(BetterTheme.cyan)
                Text("Need a Free FRED® Key?")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            Text("The Federal Reserve Bank of St. Louis offers free API keys to all developers, analysts, and students:")
                .font(.footnote)
                .foregroundStyle(BetterTheme.mutedOnNavy)

            VStack(alignment: .leading, spacing: 6) {
                NumberedStep(number: "1", text: "Create a free account on the St. Louis Fed website.")
                NumberedStep(number: "2", text: "Visit your FRED My Account page and generate an API key.")
                NumberedStep(number: "3", text: "Paste the 32-character key here. It never expires.")
            }
            .padding(.vertical, 4)

            Link(destination: URL(string: "https://fred.stlouisfed.org/docs/api/api_key.html")!) {
                HStack {
                    Text("Get Free FRED® Key at stlouisfed.org")
                        .font(.footnote.weight(.bold))
                    Image(systemName: "arrow.up.right.square")
                }
                .foregroundStyle(BetterTheme.cyan)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BetterTheme.navy.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BetterTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Cache & Watchlist Management
    private var cacheManagementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(BetterTheme.cyan)
                Text("Data & Cache Management")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(model.snapshots.count) Series In-Memory")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(BetterTheme.mutedOnNavy)
            }

            Text("Cached observation series provide instant time-range switching and offline review. You can refresh cached data at any time.")
                .font(.footnote)
                .foregroundStyle(BetterTheme.mutedOnNavy)

            HStack(spacing: 12) {
                Button {
                    model.clearCache()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh All Watchlist Data")
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(BetterTheme.navy, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BetterTheme.navy.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BetterTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Privacy & Security
    private var securityCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(BetterTheme.lime)

            VStack(alignment: .leading, spacing: 4) {
                Text("Zero-Knowledge Security")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text("Your API key is saved exclusively in the iOS Secure Keychain on your device. It is never logged or sent to any intermediary server; requests travel directly from this device to api.stlouisfed.org over TLS.")
                    .font(.caption2)
                    .foregroundStyle(BetterTheme.mutedOnNavy)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BetterTheme.navy.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BetterTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Legal / Attribution
    private var attributionCard: some View {
        VStack(spacing: 4) {
            Text("FRED® is a registered trademark of the Federal Reserve Bank of St. Louis.")
                .font(.caption2)
                .foregroundStyle(BetterTheme.mutedOnNavy.opacity(0.7))
                .multilineTextAlignment(.center)
            Text("This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis.")
                .font(.caption2)
                .foregroundStyle(BetterTheme.mutedOnNavy.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}

private struct NumberedStep: View {
    let number: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(BetterTheme.ink)
                .frame(width: 18, height: 18)
                .background(BetterTheme.cyan, in: Circle())
            Text(text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}
