# TCL SMART REMOTE

**TCL SMART REMOTE** is a professional, cross-platform smart television remote-control application engineered specifically for **TCL Smart TVs running Google TV or compatible Android TV software**.

Built with a **Local-First, Zero-Cloud-Intermediary** architecture, the application communicates directly with televisions over encrypted TLS sockets (port 6467) using the **Android TV Remote Service v2** protocol.

---

## Key Features

- **Direct TV Communication**: Connects directly to the TV over your local home Wi-Fi network without third-party cloud intermediaries.
- **Android TV Remote v2 Protocol**: Official Protobuf wire encoding/decoding, key-down/key-up injection, ping/pong keepalives, and deep link app launching.
- **Hardware-Secured Pairing**: Mutual TLS authentication using a client-generated 2048-bit RSA keypair and self-signed X.509 certificate. All private keys and pairing secrets are stored exclusively inside **Android Keystore** and **iOS Keychain**.
- **Local-First & Offline Operation**: All navigation, volume, media playback, shortcuts, and device management operate seamlessly even if external internet connectivity drops.
- **Automatic Discovery**: Discovers compatible televisions via Multicast DNS (mDNS `_androidtvremote2._tcp.local` on `224.0.0.251:5353`) with directed subnet TCP probing fallback.
- **Wake-on-LAN**: Broadcasts UDP magic packets (ports 9 & 7) to wake compatible TCL televisions from network standby ("Fast Startup").
- **Premium Handset Interface**:
  - Professional dark interface (charcoal and true black with TCL crimson accent `#E50914`).
  - Tactile circular D-pad with center OK/Select button.
  - Dual volume and channel rockers with center mute and info buttons.
  - Media controls (Play/Pause, Stop, Rewind, Fast Forward).
  - Quick application shortcuts (YouTube, Spotify, Netflix, Prime Video) with custom launcher configurator.
  - Virtual TV keyboard and touchpad gesture navigation mode.
  - Status bar displaying TV name, IP address, connection status (Green/Yellow/Red), and phone battery level.
- **Backend & SQLite Database**: A separate Node.js / Express backend with SQLite persistence providing a REST API for device registries, user settings, shortcuts, and diagnostic auditing.

---

## Project Structure

```text
tcl-smart-remote/
├── mobile/                      # Cross-Platform Flutter Handset Application
│   ├── lib/
│   │   ├── main.dart            # Application bootstrap & lifecycle initialization
│   │   ├── app/                 # App config, routes, and global constants
│   │   ├── screens/             # Remote, Discovery, Pairing, Settings, Diagnostics
│   │   ├── widgets/             # Tactile D-pad, Rockers, Status Card, Touchpad, Buttons
│   │   ├── models/              # TvDevice, TvCommand, ConnectionState, AppShortcut
│   │   ├── services/            # Secure storage, network & battery monitor, REST client
│   │   ├── state/               # Provider state management (Remote, Discovery, Settings)
│   │   ├── theme/               # Dark & Light themes, TCL crimson color palette
│   │   ├── utils/               # 2048-bit RSA & X.509 cert crypto engine, safe logger
│   │   └── tv/                  # Isolated TV Communication Subsystem
│   │       ├── protocol/        # Android TV Remote v2 Protobuf & Pairing v2 wire framing
│   │       ├── discovery/       # mDNS scanner and Wake-on-LAN broadcaster
│   │       ├── pairing/         # Mutual TLS pairing state machine & SHA-256 PIN math
│   │       ├── connection/      # TLS socket manager, keepalive ping/pong, reconnect
│   │       └── commands/        # Key code dispatcher, intent launcher, IME text entry
│   ├── android/                 # Android configuration, Manifest with full permissions
│   ├── ios/                     # iOS configuration, Info.plist with Bonjour & Local Net
│   ├── test/                    # Flutter unit, protocol, model, and widget test suites
│   └── pubspec.yaml             # Flutter project manifest and dependencies
│
├── backend/                     # Administrative REST API & Local Database
│   ├── src/
│   │   ├── server.js            # Express server entry point
│   │   ├── app.js               # Application factory & middleware integration
│   │   ├── routes/              # Health, Devices, Settings, Diagnostics routes
│   │   ├── controllers/         # Request handling & HTTP response serialization
│   │   ├── services/            # Business logic for devices, settings, diagnostics
│   │   ├── database/            # SQLite connection, migrations, and repositories
│   │   ├── middleware/          # Rate limiting, Helmet security headers, validation
│   │   └── config/              # Environment configuration loader
│   ├── tests/                   # Native Node.js test runner suites
│   ├── data/                    # Persistent SQLite database storage
│   ├── package.json             # Backend dependencies and scripts
│   └── .env.example             # Documented environment template
│
├── documentation/               # Comprehensive Architecture & Engineering Guides
│   ├── ARCHITECTURE.md          # System diagrams, protocol specifications, data flow
│   ├── INSTALLATION.md          # Step-by-step setup for Flutter and Node.js
│   ├── SECURITY.md              # Keystore/Keychain integration, mTLS, sanitization
│   ├── TV_COMPATIBILITY.md      # Supported TCL models, protocol matrix, TV settings
│   ├── API_REFERENCE.md         # Full REST API documentation with sample payloads
│   ├── OFFLINE_MODE.md          # Local-first design, router scenarios, Wake-on-LAN
│   └── TESTING.md               # Test coverage report & physical TV testing checklist
│
├── .gitignore                   # Secrets, build artifacts, and system files ignore rules
└── README.md                    # Project overview and quick start guide
```

---

## Quick Start

### 1. Start the Backend Service
```bash
cd backend
npm install
npm start
```
*Health check available at: `http://localhost:3000/api/health`*

### 2. Launch the Mobile Handset Application
```bash
cd mobile
flutter pub get
flutter run
```

### 3. Connect to your TCL Google TV
1. Ensure your phone and TCL TV are connected to the **same Wi-Fi network**.
2. Tap the TV status banner at the top of the remote screen to open the **Discovery Screen**.
3. Select your discovered TCL TV (or tap `+` to enter the TV's IP address manually).
4. Enter the 6-character PIN code displayed on your TV screen.
5. Once paired, the status indicator turns **GREEN**, and your phone controls the television directly!

---

## Documentation Links

- [Architecture Specification](documentation/ARCHITECTURE.md)
- [Installation & Setup](documentation/INSTALLATION.md)
- [Security Architecture](documentation/SECURITY.md)
- [TV Compatibility Matrix](documentation/TV_COMPATIBILITY.md)
- [REST API Reference](documentation/API_REFERENCE.md)
- [Offline Mode & Local-First](documentation/OFFLINE_MODE.md)
- [Testing & Verification](documentation/TESTING.md)

---

## License
MIT License. Built for the TCL Smart TV Ecosystem.
