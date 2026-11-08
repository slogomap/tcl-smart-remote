# Local-First Architecture & Offline Operation

## 1. Local-First Design Philosophy

**TCL SMART REMOTE** is engineered from the ground up as a **Local-First, Cloud-Independent** application. 

Standard smart TV remotes often route button clicks through remote third-party cloud servers (e.g. smartphone $\to$ AWS $\to$ TV manufacturer cloud $\to$ home router $\to$ TV). This approach introduces unacceptable latency, creates single points of failure, leaks household viewing habits, and stops functioning the moment external internet connectivity drops.

In TCL SMART REMOTE:
- All commands flow directly from the smartphone to the television over the local Wi-Fi router:
  $$\text{Smartphone} \xrightarrow{\text{Direct TLS 1.3 on Port 6467}} \text{TCL Google TV}$$
- No internet access is required to control volume, navigate menus, launch installed apps, or enter text.

---

## 2. Network Scenario Behaviors

| Network Scenario | Remote Control | Discovery & Pairing | App Shortcuts | Diagnostic Sync |
| :--- | :--- | :--- | :--- | :--- |
| **Normal (Wi-Fi + Internet)** | Full Functionality | Full Functionality | Full Functionality | Real-time sync to backend |
| **Internet Offline (Local Wi-Fi Operational)** | **Full Functionality** | **Full Functionality** | **Full Functionality** *(Installed apps)* | Cached locally; sync paused |
| **Wi-Fi Router Powered Off** | Disconnected | Offline | Offline | Stored in local flash |
| **TV in Standby (Fast Startup Enabled)** | Wake-on-LAN wake | Standby IP responds | Standby | Handset reports Standby |
| **TV Unplugged / Cold Off** | Disconnected | Unreachable | Unreachable | Handset reports Disconnected |

---

## 3. Offline Capabilities Breakdown

1. **Persistent Device Database**: Saved televisions and their IP addresses are stored locally in SQLite and encrypted platform preferences. They remain available instantly on app launch without network calls.
2. **Local Pairing Workflow**: Mutual TLS pairing occurs entirely over the local subnet. The TV displays its PIN, the phone hashes the certificates and PIN locally using SHA-256, and the TV whitelists the certificate directly without contacting Google or TCL servers.
3. **Application Shortcuts (YouTube & Spotify)**: Launch commands are transmitted as standard Android `RemoteAppLink` deep link intents over the local TLS socket. The television handles launching the local app binary internally without cloud signaling.
4. **Wake-on-LAN (WoL)**: If the TV is powered off into network standby (TCL "Instant On" / "Fast Startup"), the mobile application broadcasts an IEEE 802.3 standard UDP magic packet containing 6 bytes of `0xFF` followed by 16 repetitions of the TV's MAC address across the local subnet, waking the TV without internet.
