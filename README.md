# Better US Econ Data (BetterEcon)

An open-source SwiftUI client for exploring, comparing, and monitoring US macroeconomic data and FRED® economic time series.

## Current slice

- Dashboard with watchlist cards
- Series search
- Series detail with interactive Swift Charts graph
- Time-range switching
- Local watchlist persistence
- Protocol-based FRED API client with preview data
- WidgetKit-ready shared model boundary

## Getting started

Open `Better-FRED.xcodeproj` in Xcode, choose the `Better-FRED` scheme, select an iOS Simulator, and run.

### API Key (BYOK) & Live FRED® Data
Better US Econ Data uses a Bring-Your-Own-Key (BYOK) model:
- **In-App Settings**: Tap the **Live API / Preview** pill in the Dashboard header or visit the **Settings** tab.
- **Secure Storage**: Your 32-character FRED API key is saved directly to your device's **iOS Secure Keychain** (`kSecClassGenericPassword`). It is never transmitted to any third-party servers.
- **Test Connection**: Validate your key directly in Settings before saving.
- **Local Dev Auto-Seed**: If a gitignored `.env` file containing `FRED_API_KEY=...` is present locally, the app will automatically seed Keychain on first run. You can also supply `FRED_API_KEY` as a scheme environment variable.
- **Fallback**: Without a key, the app gracefully runs in Offline Preview mode with realistic macroeconomic baselines.

The `project.yml` file is also included for regenerating the project with XcodeGen:

```sh
xcodegen generate --spec project.yml
```

The app target supports series search, watchlist cards, responsive Swift Charts, range switching, and CSV downloads through the native iOS share sheet. The widget target provides a WidgetKit starting point.

FRED attribution and API terms should be reviewed before distribution.
