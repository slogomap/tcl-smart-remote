# TCL SMART REMOTE - Backend Service

REST API and SQLite database service for the TCL SMART REMOTE ecosystem.

## Features
- **Device Management**: Store discovered and paired TCL Google TVs.
- **Settings Store**: Persist user preferences (haptics, theme, timeouts, Wake-on-LAN settings).
- **Application Shortcuts**: Manage TV app launcher shortcuts (YouTube, Spotify, Netflix, etc.).
- **Diagnostics & Audit Log**: Record connection history, latency metrics, and errors without leaking credentials.
- **Security**: Rate limiting, Helmet security headers, input validation, strict CORS.

## Endpoints
- `GET /api/health` - Health check & server uptime
- `GET /api/devices` - List all registered devices
- `POST /api/devices` - Register/save a device
- `GET /api/devices/:id` - Fetch single device details
- `PUT /api/devices/:id` - Update device details
- `DELETE /api/devices/:id` - Delete/forget device
- `GET /api/settings` - Retrieve global settings & shortcuts
- `PUT /api/settings` - Update settings
- `GET /api/diagnostics` - Retrieve diagnostic logs & system metrics
- `POST /api/diagnostics/logs` - Append client diagnostic entry

## Quick Start
```bash
npm install
npm start
```
Run tests:
```bash
npm test
```
