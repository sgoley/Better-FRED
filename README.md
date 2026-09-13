# Better-FRED

An open-source SwiftUI client for exploring, comparing, and monitoring FRED economic data.

## Current slice

- Dashboard with watchlist cards
- Series search
- Series detail with interactive Swift Charts graph
- Time-range switching
- Local watchlist persistence
- Protocol-based FRED API client with preview data
- WidgetKit-ready shared model boundary

## Getting started

Open `Better-FRED.xcodeproj` in Xcode, choose the `Better-FRED` scheme, select an iOS Simulator, and run. The app currently uses preview data so the first screen is useful without credentials.

To use live FRED data, add an Xcode scheme environment variable named `FRED_API_KEY`. The app selects `FREDAPIClient` automatically when the variable is present and falls back to local preview data otherwise. Never commit the key.

The `project.yml` file is also included for regenerating the project with XcodeGen:

```sh
xcodegen generate --spec project.yml
```

The app target supports series search, watchlist cards, responsive Swift Charts, range switching, and CSV downloads through the native iOS share sheet. The widget target provides a WidgetKit starting point.

FRED attribution and API terms should be reviewed before distribution.
