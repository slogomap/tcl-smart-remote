# Installation & Setup Guide: TCL SMART REMOTE

## 1. Prerequisites

### Mobile Development Environment
- **Flutter SDK**: `>= 3.19.0` (Dart `>= 3.3.0`)
- **Android Studio** / **VS Code** with Flutter & Dart extensions
- **Android SDK**: API 34 (Android 14) recommended, minimum API 24 (Android 7.0)
- **Xcode**: 15+ (required only when building for iOS on macOS)

### Backend Environment
- **Node.js**: `>= 18.0.0` (LTS recommended: Node 20.x or 22.x)
- **npm**: `>= 9.0.0`

---

## 2. Backend Service Setup

1. Open your terminal and navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Copy the environment variables example:
   ```bash
   cp .env.example .env
   ```

3. Install project dependencies:
   ```bash
   npm install
   ```

4. Verify database creation and start the service:
   ```bash
   npm start
   ```
   *The server starts listening on `http://localhost:3000` and automatically runs initial SQLite migrations in `./data/tcl_remote.sqlite`.*

5. Run automated test suites:
   ```bash
   npm test
   ```

---

## 3. Mobile Handset Setup (Android)

1. Open your terminal and navigate to the mobile directory:
   ```bash
   cd mobile
   ```

2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

3. Connect your Android smartphone via USB or launch an Android Virtual Device (AVD).
   - Ensure Developer Options & USB Debugging are enabled on your physical phone.
   - Connect the phone to the **same Wi-Fi network** as your TCL Google TV.

4. Run the application in debug mode:
   ```bash
   flutter run
   ```

---

## 4. Building Production Artifacts

### 4.1 Building Android APK (Section 19 / Phase 10)
To produce a standalone release APK:
```bash
cd mobile
flutter build apk --release
```
The output file will be generated at:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

To produce an Android App Bundle (AAB) for Google Play:
```bash
flutter build appbundle --release
```

### 4.2 Building iOS App (Section 14)
> [!NOTE]
> Building for iOS requires a macOS workstation with Xcode installed.

1. Ensure CocoaPods is installed:
   ```bash
   sudo gem install cocoapods
   ```
2. Navigate to the iOS runner directory and install pods:
   ```bash
   cd mobile/ios
   pod install
   cd ..
   ```
3. Build the iOS archive:
   ```bash
   flutter build ipa --release
   ```
