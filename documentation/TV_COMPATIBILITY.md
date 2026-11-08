# TV Compatibility Matrix & Protocol Analysis

## 1. Overview
The primary target for **TCL SMART REMOTE** is TCL Smart TVs running official **Google TV** or certified **Android TV** software versions. Secondary targets include third-party Android TV streaming boxes and televisions implementing the Android TV Remote Service v2 protocol.

---

## 2. Feature Implementation & Testing Matrix

| Feature / Protocol Component | Status | Implementation Details | Physical Device Testing Requirement |
| :--- | :--- | :--- | :--- |
| **mDNS Device Discovery** | **Implemented & Tested** | Queries `_androidtvremote2._tcp.local` on 224.0.0.251:5353 | Unit tested; LAN broadcast verified |
| **Direct Subnet TCP Probe** | **Implemented & Tested** | Scans port 6467 across local subnet as fallback | Unit tested |
| **TLS Socket Handshake** | **Implemented & Tested** | Port 6467 TLS 1.2 / 1.3 client handshake | Unit tested |
| **Pairing Request / Config** | **Implemented & Tested** | Pairing protocol v2 Protobuf framing | Wire format verified by unit test |
| **Pairing PIN Verification** | **Implemented & Tested** | SHA-256 cert fingerprint secret calculation | Tested with test vectors |
| **Key Injections (DPAD/OK/Back)** | **Implemented & Tested** | AndroidKeyCodes 19-23, 4, 3 via RemoteKeyInject | Protobuf wire verified by unit test |
| **Volume & Mute Controls** | **Implemented & Tested** | Keycodes 24, 25, 164 via RemoteKeyInject | Verified by wire test |
| **Media Controls (Play/Pause/Seek)**| **Implemented & Tested** | Keycodes 85, 86, 89, 90 via RemoteKeyInject | Verified by wire test |
| **YouTube Deep Linking** | **Implemented & Tested** | `RemoteAppLink` with URI `https://www.youtube.com` | Intent wire format verified |
| **Spotify Deep Linking** | **Implemented & Tested** | `RemoteAppLink` with URI `spotify://` | Intent wire format verified |
| **Wake-on-LAN Power-On** | **Implemented** | 102-byte magic packet broadcast on UDP 9/7 | Requires physical TV with Fast Startup enabled |
| **Touchpad Cursor Emulation** | **Implemented** | Translates pan velocity into DPAD events | Unit tested |
| **Voice Assistant Trigger** | **Implemented** | Keycode 231 (KEYCODE_VOICE_ASSIST) | Requires TV with Google Assistant enabled |
| **Direct Audio Streaming** | **Unsupported** | Real-time PCM audio streaming from handset mic | Requires proprietary Google microphone stream token |

---

## 3. Supported TCL TV Models & Software Platforms

### 3.1 Fully Supported
- **TCL Google TV Series (2021–Present)**:
  - TCL C-Series: C645, C735, C745, C835, C845, C935, C955, X955
  - TCL P-Series: P635, P735, P745, P755
  - TCL S-Series: S450G, S550G, Q650G, Q750G, QM850G
- **Operating Systems**: Google TV (Android 11, Android 12, Android 14)
- **Protocol**: Android TV Remote Service v2 on TCP Port 6467

### 3.2 Compatible Android TV Devices
- Sony Bravia TVs with Google TV (Android 10+)
- Philips Android TV / Google TV
- Xiaomi Mi Box S, Mi TV Stick 4K
- Google Chromecast with Google TV (HD & 4K)
- NVIDIA Shield TV (Shield Experience 9.0+)

### 3.3 Unsupported Hardware
- **TCL Roku TVs**: Roku models run Roku OS, which utilizes Roku ECP (External Control Protocol) on port 8060 instead of the Android TV Remote Service.
- **TCL TVs running legacy Linux / Opera / SmartTV 3.0**: Models prior to 2017 lacking Android TV or Google TV firmware.

---

## 4. Physical TV Setup Requirements

To ensure flawless communication:
1. **Network Connectivity**: Connect both smartphone and TV to the same Wi-Fi SSID and subnet (avoid router Guest Mode, which isolates clients).
2. **Fast Startup / Network Standby**:
   - On TCL Google TV: Open **Settings** > **System** > **Power & Energy** > Enable **Fast Startup** (or **Network Standby**).
   - This ensures the TV's network card remains energized during standby, enabling Wake-on-LAN and immediate reconnection.
