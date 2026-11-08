# Backend REST API Reference: TCL SMART REMOTE

The backend REST API provides device registration, configuration sync, and diagnostic monitoring for the TCL SMART REMOTE ecosystem.

**Base URL**: `http://localhost:3000/api`

---

## 1. System Health

### `GET /api/health`
Retrieves server operational status, uptime, and API version.

**Response `200 OK`**:
```json
{
  "status": "ok",
  "service": "TCL SMART REMOTE Backend API",
  "version": "1.0.0",
  "timestamp": "2026-11-08T14:30:00.000Z",
  "uptimeSeconds": 1420
}
```

---

## 2. Device Management

### `GET /api/devices`
Returns all registered and discovered TCL televisions stored in the database.

**Response `200 OK`**:
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": "tv-192.168.1.150",
      "name": "Living Room TCL C835",
      "ip_address": "192.168.1.150",
      "port": 6467,
      "mac_address": "AA:BB:CC:DD:EE:FF",
      "model": "TCL 65C835 Google TV",
      "os_version": "Android TV 12",
      "is_paired": 1,
      "last_connected_at": "2026-11-08T14:20:10.000Z",
      "created_at": "2026-11-08T12:00:00.000Z",
      "updated_at": "2026-11-08T14:20:10.000Z"
    }
  ]
}
```

### `POST /api/devices`
Registers a new television or updates an existing entry matching the same IP address.

**Request Body**:
```json
{
  "name": "Master Bedroom TCL P745",
  "ip_address": "192.168.1.160",
  "port": 6467,
  "mac_address": "11:22:33:44:55:66",
  "model": "TCL 55P745",
  "os_version": "Google TV 11",
  "is_paired": 0
}
```

**Response `201 Created`**:
```json
{
  "success": true,
  "data": {
    "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "name": "Master Bedroom TCL P745",
    "ip_address": "192.168.1.160",
    "port": 6467,
    "mac_address": "11:22:33:44:55:66",
    "model": "TCL 55P745",
    "os_version": "Google TV 11",
    "is_paired": 0,
    "created_at": "2026-11-08T14:35:00.000Z",
    "updated_at": "2026-11-08T14:35:00.000Z"
  }
}
```

### `GET /api/devices/:id`
Retrieves a single device by its unique ID.

**Response `200 OK`**:
```json
{
  "success": true,
  "data": { ...device details... }
}
```

### `DELETE /api/devices/:id`
Removes a television from the database registry.

**Response `200 OK`**:
```json
{
  "success": true,
  "message": "Device successfully removed"
}
```

---

## 3. Settings & Shortcuts

### `GET /api/settings`
Returns global application preferences and application shortcut profiles.

**Response `200 OK`**:
```json
{
  "success": true,
  "data": {
    "theme": "dark",
    "hapticFeedback": true,
    "buttonSound": false,
    "autoReconnect": true,
    "connectionTimeoutMs": 5000,
    "shortcuts": [
      {
        "id": "youtube-shortcut",
        "name": "YouTube",
        "package_id": "com.google.android.youtube.tv",
        "deep_link": "https://www.youtube.com",
        "icon_name": "youtube",
        "is_enabled": 1,
        "sort_order": 1
      },
      {
        "id": "spotify-shortcut",
        "name": "Spotify",
        "package_id": "com.spotify.tv.android",
        "deep_link": "spotify://",
        "icon_name": "spotify",
        "is_enabled": 1,
        "sort_order": 2
      }
    ]
  }
}
```

### `PUT /api/settings`
Updates application preferences.

**Request Body**:
```json
{
  "theme": "light",
  "hapticFeedback": false,
  "autoReconnect": true
}
```

**Response `200 OK`**:
```json
{
  "success": true,
  "data": { ...updated settings... }
}
```

---

## 4. Diagnostics & Auditing

### `GET /api/diagnostics`
Retrieves system diagnostics, memory usage, host details, and the latest event logs.

**Query Parameters**:
- `limit` *(optional, integer)*: Maximum log entries to return (default: `100`).

**Response `200 OK`**:
```json
{
  "success": true,
  "data": {
    "system": {
      "platform": "win32",
      "uptimeSeconds": 18450,
      "nodeVersion": "v20.12.0",
      "timestamp": "2026-11-08T14:40:00.000Z"
    },
    "logsCount": 4,
    "logs": [
      {
        "id": "3194a87c-17c3-4d6f-b258-c9fbcefae8e2",
        "level": "INFO",
        "component": "DeviceService",
        "message": "Registering new device 'Living Room TCL C835' at IP 192.168.1.150",
        "metadata": null,
        "timestamp": "2026-11-08T14:38:00.000Z"
      }
    ]
  }
}
```

### `POST /api/diagnostics/logs`
Allows mobile clients to append diagnostic entries (e.g., connection drops, socket timeouts).

**Request Body**:
```json
{
  "level": "WARN",
  "component": "TvConnection",
  "message": "Socket heartbeat dropped after 5000ms",
  "metadata": { "reconnectAttempt": 2 }
}
```
