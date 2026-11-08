'use strict';

const { getDatabase } = require('../connection');
const crypto = require('crypto');

class DiagnosticsRepository {
  constructor(db = null) {
    this._db = db;
  }

  get db() {
    return this._db || getDatabase();
  }

  findAll(limit = 100) {
    return this.db
      .prepare('SELECT * FROM diagnostics ORDER BY timestamp DESC LIMIT ?')
      .all(limit);
  }

  log(level, component, message, metadata = null) {
    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    const metaStr = metadata ? (typeof metadata === 'object' ? JSON.stringify(metadata) : String(metadata)) : null;

    this.db
      .prepare(
        `INSERT INTO diagnostics (id, level, component, message, metadata, timestamp)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
      .run(id, level.toUpperCase(), component, message, metaStr, now);

    return { id, level, component, message, metadata: metaStr, timestamp: now };
  }

  clear() {
    this.db.prepare('DELETE FROM diagnostics').run();
  }
}

const diagnosticsRepository = new DiagnosticsRepository();
module.exports = diagnosticsRepository;
module.exports.DiagnosticsRepository = DiagnosticsRepository;
