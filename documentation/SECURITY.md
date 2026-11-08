# Security Architecture & Best Practices: TCL SMART REMOTE

## 1. Security Philosophy

TCL SMART REMOTE adheres to the principle of **Defense-in-Depth** and **Strict Local Scoping**. The application controls physical televisions inside a user's home; therefore, unauthorized network access, cleartext interception, or credential leakage could lead to severe physical and privacy intrusions.

---

## 2. Cryptographic Architecture

### 2.1 Hardware-Backed Key Storage
- **Android**: Keys and pairing certificates are protected by the **Android Keystore System** via `flutter_secure_storage` using EncryptedSharedPreferences (AES-256-GCM). Cryptographic operations take place inside the device's Trusted Execution Environment (TEE) or StrongBox Keymaster.
- **iOS**: Stored within the **iOS Keychain Services** with accessibility attribute `kSecAttrAccessibleAfterFirstUnlock`.
- **Database Non-Storage**: The SQLite database **never stores private keys or TV PIN codes**.

### 2.2 Mutual TLS Authentication (mTLS)
Communication with the TV (port 6467) strictly mandates TLS:
1. **Client Identity**: The mobile handset generates a 2048-bit RSA keypair and self-signed X.509 certificate upon first run.
2. **TV Identity**: The TCL Google TV issues its own self-signed TLS certificate.
3. **Pin-Based Whitelisting**: During the initial pairing handshake, the client proves possession of the user-entered PIN code by exchanging the SHA-256 secret:
   $$\text{Secret} = \text{SHA-256}(\text{ClientCert}_{\text{DER}} \parallel \text{ServerCert}_{\text{DER}} \parallel \text{PIN}_{\text{UTF-8}})$$
4. Once verified, the TV whitelists the client's public certificate fingerprint in its persistent trust store. Subsequent socket connections require presenting this client certificate in the TLS client handshake.

---

## 3. Threat Mitigation Matrix

| Threat | Impact | Mitigation Strategy Implemented |
| :--- | :--- | :--- |
| **Man-in-the-Middle (MitM)** | High | Mutual TLS encryption for all TV commands; SHA-256 cert challenge verification during pairing. |
| **Credential Extraction** | Critical | Keys stored in Android Keystore / iOS Keychain; zero plaintext secrets in SQLite or SharedPreferences. |
| **Log Exposure** | Medium | Centralized `AppLogger` automatically redacts PEM certificate blocks and regex patterns matching PIN codes. |
| **Public Internet Exposure** | High | The remote operates exclusively over local subnet (`192.168.x.x`, `10.x.x.x`, `172.16.x.x`); backend binds to local network with rate limiting. |
| **SQL Injection** | High | All database operations utilize parameterized queries (`?`) in both SQLite and fallback drivers. |
| **Denial of Service (DoS)** | Medium | Backend Express API employs strict rate limiting (`express-rate-limit`) restricting burst calls. |

---

## 4. Safe Logging Policy
Any log output emitted by the client or backend is processed through sanitizers:
- Matches against `-----BEGIN [A-Z ]+-----[^-]+-----END [A-Z ]+-----` are replaced with `[REDACTED_CERTIFICATE]`.
- Matches against pairing tokens, PINs, or secrets are masked with asterisks.
- Technical stack traces are concealed from the user UI in production mode.
