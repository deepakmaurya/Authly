# Authly

> A fast, private, native **macOS 2FA authenticator** — a Google Authenticator–compatible TOTP app for your Mac.

Authly generates time-based one-time passwords (TOTP) right on your desktop. Secrets never leave your machine — they live in the macOS **Keychain** — and Authly speaks the same `otpauth://` and `otpauth-migration://` formats as Google Authenticator, so importing and exporting just works.

Built entirely with **SwiftUI** for macOS 14+.

---

## ✨ Features

- 🔐 **Standard TOTP codes** — RFC 6238 compliant, with HMAC-SHA1 / SHA256 / SHA512, 6 or 8 digits, and configurable refresh periods (15–120s).
- 📷 **Add accounts your way**
  - Scan a QR code with your Mac's **camera**
  - Import a QR code from an **image file**
  - **Enter a secret manually** (Base32) with full control over algorithm, digits, and period
- 🔄 **Google Authenticator import** — paste or scan an `otpauth-migration://` export to bring over all your accounts at once.
- 📤 **Export as QR** — share a single account (`otpauth://`) or a full **migration QR** for multiple accounts, then scan it straight into Google Authenticator on your phone. Save the QR as a PNG.
- 🔎 **Instant search** — filter accounts by issuer or label as you type.
- 🗝️ **Keychain-backed storage** — your vault is stored as a single encrypted Keychain item, accessible only when your Mac is unlocked.
- 🛡️ **Sandboxed & offline** — no network access, no telemetry, no accounts in the cloud. Camera access is used only for scanning QR codes.
- 🖥️ **Native macOS experience** — `NavigationSplitView` layout, live countdown rings, and system-native sheets and menus.

---

## 📸 Screenshots

> _Add screenshots here — e.g. the account list, detail view with countdown, and the export QR sheet._

---

## 🚀 Getting Started

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (Swift 5.9)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (the Xcode project is generated from [`project.yml`](project.yml))

### Build & Run

```bash
# 1. Clone the repo
git clone https://github.com/<your-org>/GoogleAuthenticator.git
cd GoogleAuthenticator

# 2. Generate the Xcode project (if not already present)
brew install xcodegen   # if you don't have it
xcodegen generate

# 3. Open and run
open Authly.xcodeproj
```

Then build and run the **Authly** scheme (⌘R). On first launch macOS will ask for camera permission the first time you use **Scan with Camera**.

---

## 🧭 Usage

| Action | How |
| --- | --- |
| Add an account | Click the **＋** toolbar menu → *Scan with Camera*, *Import QR from File…*, or *Enter Manually* |
| Import from Google Authenticator | Export accounts from the phone app, then scan/import the resulting migration QR |
| View a code | Select an account in the sidebar — the current code and countdown appear in the detail view |
| Export an account | Open an account and export it as a QR, or use **Export All as QR…** for a migration QR |
| Search | Type in the sidebar search field to filter by issuer or label |

---

## 🏗️ How It Works

Authly is a small, dependency-free codebase. The interesting parts:

| Area | File |
| --- | --- |
| TOTP / HOTP generation (CryptoKit) | [`Services/TOTPGenerator.swift`](Authly/Services/TOTPGenerator.swift) |
| `otpauth://` URL parsing & building | [`Services/OTPAuthURL.swift`](Authly/Services/OTPAuthURL.swift) |
| Google Authenticator migration (protobuf) | [`Services/MigrationParser.swift`](Authly/Services/MigrationParser.swift), [`Services/Protobuf.swift`](Authly/Services/Protobuf.swift) |
| Base32 encode/decode | [`Services/Base32.swift`](Authly/Services/Base32.swift) |
| QR generation & scanning | [`Services/QRGenerator.swift`](Authly/Services/QRGenerator.swift), [`Services/QRImageScanner.swift`](Authly/Services/QRImageScanner.swift), [`Services/CameraScanner.swift`](Authly/Services/CameraScanner.swift) |
| Encrypted Keychain vault | [`Services/KeychainService.swift`](Authly/Services/KeychainService.swift) |
| App state / account store | [`ViewModels/AccountStore.swift`](Authly/ViewModels/AccountStore.swift) |

The protobuf reader/writer is hand-rolled to decode and re-encode Google Authenticator's migration payloads, so Authly can both **import from** and **export to** the official app.

---

## 🔒 Privacy & Security

- Secrets are decoded to raw bytes and stored in the macOS Keychain (`kSecAttrAccessibleWhenUnlocked`).
- The app is sandboxed; the only entitlements are camera access (for QR scanning) and user-selected file read/write (for importing/exporting images).
- No analytics, no network requests — Authly works entirely offline.

> ⚠️ **Note:** Anyone with access to your unlocked Mac and Authly can view your codes. Treat exported QR codes like passwords.

---

## 🤝 Contributing

Contributions are welcome! Please open an issue to discuss substantial changes first. For bug fixes and small improvements, feel free to submit a pull request.

---

## 📄 License

Released under the [MIT License](LICENSE) — free to use, modify, and distribute.
