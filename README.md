# Better US Econ Data (BetterEcon)

An open-source SwiftUI client for exploring, comparing, and monitoring US macroeconomic data and FRED® economic time series.

## Current slice

- Dashboard with watchlist cards
- Instant series search with pre-cached catalog of 50+ top FRED benchmark series across 9 economic categories
- Debounced deep search against FRED's 800,000+ series database with in-memory query result caching
- Series detail with interactive Swift Charts graph
- Time-range switching
- Local watchlist persistence
- Protocol-based FRED API client with preview data
- WidgetKit-ready shared model boundary

## Getting started

Open `BetterEcon.xcodeproj` in Xcode, choose the `BetterEcon` scheme, select an iOS Simulator, and run.

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

## Data Attribution & Legal Disclosures

### Official FRED® API Attribution

> **"This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis."**

### Trademark Notice

**FRED®** is a registered trademark of the **Federal Reserve Bank of St. Louis**.

### Data Sources & Link Back

All economic time series displayed in Better US Econ Data are compiled and published by original statistical agencies and distributed via the Federal Reserve Bank of St. Louis Economic Data service ([FRED®](https://fred.stlouisfed.org)):

- **St. Louis Fed FRED® Homepage**: https://fred.stlouisfed.org
- **FRED® API Documentation & Terms**: https://fred.stlouisfed.org/docs/api/terms_of_use.html
- **Direct Series Links**: In-app series detail views and data cards link directly to their canonical source page on FRED (e.g., [`https://fred.stlouisfed.org/series/MORTGAGE30US`](https://fred.stlouisfed.org/series/MORTGAGE30US), [`https://fred.stlouisfed.org/series/UNRATE`](https://fred.stlouisfed.org/series/UNRATE), [`https://fred.stlouisfed.org/series/CPIAUCSL`](https://fred.stlouisfed.org/series/CPIAUCSL)).
- **Primary Source Agencies**: Datasets originate from source institutions including Freddie Mac, the U.S. Bureau of Labor Statistics (BLS), the U.S. Bureau of Economic Analysis (BEA), and the Board of Governors of the Federal Reserve System.

### Accuracy & Non-Investment Advice Disclaimer

Data is retrieved directly from original public sources and provided "as is" for research, educational, and informational purposes only. Better US Econ Data is an analytical visualization utility and does not constitute financial, investment, legal, or tax advice.

## Documentation & Privacy Policy

- **Interactive Web Portal**: https://sgoley.github.io/BetterEcon/
- **Privacy Policy**: https://sgoley.github.io/BetterEcon/privacy.html
- **License**: MIT License (see [LICENSE](LICENSE))
