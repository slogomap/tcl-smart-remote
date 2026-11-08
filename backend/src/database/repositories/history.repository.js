'use strict';

const { getDatabase } = require('../connection');
const crypto = require('crypto');

class HistoryRepository {
  constructor(db = null) {
    this._db = db;
  }

  get db() {
    return this._db || getDatabase();
  }

  findByDeviceId(deviceId) {
    return this.db
      .prepare('SELECT * FROM connection_history WHERE device_id = ? ORDER BY connected_at DESC LIMIT 50')
      .all(deviceId);
  }

  recordConnection(deviceId, status, errorReason = null) {
    const id = crypto.randomUUID();
    const now = new Date().toISOString();

    this.db
      .prepare(
        `INSERT INTO connection_history (id, device_id, status, error_reason, connected_at, disconnected_at)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
      .run(id, deviceId, status, errorReason, now, null);

    return { id, device_id: deviceId, status, error_reason: errorReason, connected_at: now };
  }

  recordDisconnection(id) {
    const now = new Date().toISOString();
    this.db
      .prepare('UPDATE connection_history SET disconnected_at = ? WHERE id = ?')
      .run(now, id);
  }
}

const historyRepository = new HistoryRepository();
module.exports = historyRepository;
module.exports.HistoryRepository = HistoryRepository;
