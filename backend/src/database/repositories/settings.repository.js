'use strict';

const { getDatabase } = require('../connection');
const crypto = require('crypto');

class SettingsRepository {
  constructor(db = null) {
    this._db = db;
  }

  get db() {
    return this._db || getDatabase();
  }

  getAll() {
    const rows = this.db.prepare('SELECT * FROM app_settings').all();
    const settings = {};
    rows.forEach((r) => {
      try {
        settings[r.key] = JSON.parse(r.value);
      } catch (e) {
        settings[r.key] = r.value;
      }
    });
    return settings;
  }

  get(key) {
    const row = this.db.prepare('SELECT * FROM app_settings WHERE key = ?').get(key);
    if (!row) return null;
    try {
      return JSON.parse(row.value);
    } catch (e) {
      return row.value;
    }
  }

  set(key, value) {
    const existing = this.db.prepare('SELECT * FROM app_settings WHERE key = ?').get(key);
    const now = new Date().toISOString();
    const strVal = typeof value === 'object' ? JSON.stringify(value) : String(value);

    if (existing) {
      this.db
        .prepare('UPDATE app_settings SET value = ?, updated_at = ? WHERE key = ?')
        .run(strVal, now, key);
    } else {
      const id = crypto.randomUUID();
      this.db
        .prepare('INSERT INTO app_settings (id, key, value, updated_at) VALUES (?, ?, ?, ?)')
        .run(id, key, strVal, now);
    }

    return this.get(key);
  }

  updateMany(settingsMap) {
    Object.keys(settingsMap).forEach((key) => {
      this.set(key, settingsMap[key]);
    });
    return this.getAll();
  }
}

const settingsRepository = new SettingsRepository();
module.exports = settingsRepository;
module.exports.SettingsRepository = SettingsRepository;
