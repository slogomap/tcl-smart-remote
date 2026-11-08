'use strict';

function up(db) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS devices (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      ip_address TEXT NOT NULL UNIQUE,
      port INTEGER NOT NULL DEFAULT 6467,
      mac_address TEXT,
      model TEXT,
      os_version TEXT,
      is_paired INTEGER DEFAULT 0,
      last_connected_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS app_settings (
      id TEXT PRIMARY KEY,
      key TEXT NOT NULL UNIQUE,
      value TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS remote_preferences (
      id TEXT PRIMARY KEY,
      device_id TEXT,
      haptic_feedback INTEGER DEFAULT 1,
      button_sound INTEGER DEFAULT 0,
      auto_reconnect INTEGER DEFAULT 1,
      connection_timeout_ms INTEGER DEFAULT 5000,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS app_shortcuts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      package_id TEXT NOT NULL,
      deep_link TEXT,
      icon_name TEXT,
      is_enabled INTEGER DEFAULT 1,
      sort_order INTEGER DEFAULT 0,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS connection_history (
      id TEXT PRIMARY KEY,
      device_id TEXT NOT NULL,
      status TEXT NOT NULL,
      error_reason TEXT,
      connected_at TEXT,
      disconnected_at TEXT
    );

    CREATE TABLE IF NOT EXISTS diagnostics (
      id TEXT PRIMARY KEY,
      level TEXT NOT NULL,
      component TEXT NOT NULL,
      message TEXT NOT NULL,
      metadata TEXT,
      timestamp TEXT NOT NULL
    );
  `);
}

module.exports = { up };
