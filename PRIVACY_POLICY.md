# Privacy Policy for Better US Econ Data (BetterEcon)

**Last updated:** September 13, 2026

Better US Econ Data ("BetterEcon") is built with a zero-knowledge, privacy-first architecture. We believe your economic research and data monitoring are your own business.

### 1. Information Collection and Use
* **No Account Required**: You do not need to create an account, register, or provide an email address to use BetterEcon.
* **No Telemetry or Tracking**: The app does not include analytics SDKs, advertising frameworks, device fingerprinting, or crash-reporting services.
* **No Server Intermediary**: BetterEcon does not operate an intermediary server. All requests for economic observations travel directly from your device to official APIs over encrypted TLS connections.

### 2. API Keys and Credentials
* If you supply your personal Federal Reserve Economic Data (FRED®) API key, it is stored exclusively in your device's **iOS Secure Keychain** (`kSecClassGenericPassword`).
* The key is never logged, never transmitted to any third party, and only sent directly to `api.stlouisfed.org` as required to authorize your observation requests.
* You can remove or replace your API key at any time from the in-app Settings screen.

### 3. Data Storage
* Watchlist series identifiers and view preferences are stored locally on your device via standard iOS `UserDefaults`.
* This data never leaves your device.

### 4. Third-Party Services
* When using live data mode, the app connects directly to the Federal Reserve Bank of St. Louis FRED® API. Their privacy practices are governed by the [St. Louis Fed Privacy Policy](https://www.stlouisfed.org/privacy-policy).

### 5. Contact
If you have any questions regarding this Privacy Policy, please open an issue on the project repository.
