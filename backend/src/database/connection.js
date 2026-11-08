'use strict';

const fs = require('fs');
const path = require('path');
const config = require('../config/environment');
const initialSchema = require('./migrations/001_initial_schema');

let currentDb = null;
let currentDbPath = null;

class FallbackSqliteDb {
  constructor(filePath) {
    this.filePath = filePath;
    this.tables = {
      devices: [],
      app_settings: [],
      remote_preferences: [],
      app_shortcuts: [],
      connection_history: [],
      diagnostics: [],
    };
    this._load();
  }

  _load() {
    if (!this.filePath || this.filePath === ':memory:') return;
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf8');
        const parsed = JSON.parse(raw);
        this.tables = { ...this.tables, ...parsed };
      }
    } catch (err) {
      // If corrupted or unreadable, initialize clean table collections
      this.tables = {
        devices: [],
        app_settings: [],
        remote_preferences: [],
        app_shortcuts: [],
        connection_history: [],
        diagnostics: [],
      };
    }
  }

  _save() {
    if (!this.filePath || this.filePath === ':memory:') return;
    try {
      const dir = path.dirname(this.filePath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(this.filePath, JSON.stringify(this.tables, null, 2), 'utf8');
    } catch (err) {
      console.error('Failed to persist database:', err.message);
    }
  }

  exec(sql) {
    if (!sql || typeof sql !== 'string') return this;
    const tableMatches = [...sql.matchAll(/CREATE TABLE IF NOT EXISTS\s+([a-zA-Z0-9_]+)/gi)];
    for (const match of tableMatches) {
      const tableName = match[1];
      if (!this.tables[tableName]) {
        this.tables[tableName] = [];
      }
    }
    return this;
  }

  prepare(sql) {
    const trimmed = sql.trim();
    const self = this;

    return {
      all(...params) {
        return self._queryAll(trimmed, params);
      },
      get(...params) {
        const rows = self._queryAll(trimmed, params);
        return rows[0] || null;
      },
      run(...params) {
        return self._executeRun(trimmed, params);
      },
    };
  }

  _queryAll(sql, params) {
    const tableMatch = sql.match(/FROM\s+([a-zA-Z0-9_]+)/i);
    if (!tableMatch) return [];
    const tableName = tableMatch[1];

    if (!this.tables[tableName]) {
      throw new Error(`no such table: ${tableName}`);
    }

    const table = this.tables[tableName] || [];
    let results = [...table];

    // Generic WHERE <column> = ?
    const whereMatch = sql.match(/WHERE\s+([a-zA-Z0-9_]+)\s*=\s*\?/i);
    if (whereMatch && params.length > 0) {
      const col = whereMatch[1];
      results = results.filter((r) => String(r[col]) === String(params[0]));
    }

    // Check for SELECT COUNT(*)
    if (/SELECT\s+COUNT\s*\([^)]*\)/i.test(sql)) {
      return [{ count: results.length }];
    }

    // ORDER BY
    const orderMatch = sql.match(/ORDER BY\s+([a-zA-Z0-9_]+)(?:\s+(ASC|DESC))?/i);
    if (orderMatch) {
      const orderCol = orderMatch[1];
      const isDesc = (orderMatch[2] || 'ASC').toUpperCase() === 'DESC';
      results.sort((a, b) => {
        const valA = a[orderCol] !== undefined ? a[orderCol] : '';
        const valB = b[orderCol] !== undefined ? b[orderCol] : '';
        if (valA < valB) return isDesc ? 1 : -1;
        if (valA > valB) return isDesc ? -1 : 1;
        return 0;
      });
    }

    // LIMIT
    const limitMatch = sql.match(/LIMIT\s+(\d+|\?)/i);
    if (limitMatch) {
      let limit = 100;
      if (limitMatch[1] === '?') {
        limit = parseInt(params[params.length - 1], 10) || 100;
      } else {
        limit = parseInt(limitMatch[1], 10);
      }
      results = results.slice(0, limit);
    }

    return results;
  }

  _executeRun(sql, params) {
    const insertMatch = sql.match(/INSERT INTO\s+([a-zA-Z0-9_]+)\s*\(([^)]+)\)\s*VALUES\s*\(([^)]+)\)/i);
    if (insertMatch) {
      const tableName = insertMatch[1];
      if (!this.tables[tableName]) {
        throw new Error(`no such table: ${tableName}`);
      }
      const cols = insertMatch[2].split(',').map((c) => c.trim());
      const row = {};
      cols.forEach((col, idx) => {
        row[col] = params[idx] !== undefined ? params[idx] : null;
      });
      if (!row.id) {
        row.id = String(Date.now()) + '-' + Math.random().toString(36).substring(2, 7);
      }
      if (!row.created_at) row.created_at = new Date().toISOString();
      if (!row.updated_at) row.updated_at = new Date().toISOString();

      this.tables[tableName].push(row);
      this._save();
      return { changes: 1, lastInsertRowid: row.id };
    }

    const updateMatch = sql.match(/UPDATE\s+([a-zA-Z0-9_]+)\s+SET\s+(.+?)\s+WHERE\s+([a-zA-Z0-9_]+)\s*=\s*\?/i);
    if (updateMatch) {
      const tableName = updateMatch[1];
      if (!this.tables[tableName]) {
        throw new Error(`no such table: ${tableName}`);
      }
      const setStr = updateMatch[2];
      const whereCol = updateMatch[3];
      const whereVal = params[params.length - 1];
      const setCols = setStr.split(',').map((s) => s.trim().split('=')[0].trim());

      const table = this.tables[tableName] || [];
      const item = table.find((r) => String(r[whereCol]) === String(whereVal));
      if (item) {
        setCols.forEach((col, idx) => {
          item[col] = params[idx];
        });
        item.updated_at = new Date().toISOString();
        this._save();
        return { changes: 1 };
      }
      return { changes: 0 };
    }

    const deleteMatch = sql.match(/DELETE FROM\s+([a-zA-Z0-9_]+)(?:\s+WHERE\s+([a-zA-Z0-9_]+)\s*=\s*\?)?/i);
    if (deleteMatch) {
      const tableName = deleteMatch[1];
      if (!this.tables[tableName]) {
        throw new Error(`no such table: ${tableName}`);
      }
      const whereCol = deleteMatch[2];
      if (whereCol) {
        const id = params[0];
        const table = this.tables[tableName] || [];
        const initialLen = table.length;
        this.tables[tableName] = table.filter((r) => String(r[whereCol]) !== String(id));
        this._save();
        return { changes: initialLen - this.tables[tableName].length };
      } else {
        const count = this.tables[tableName].length;
        this.tables[tableName] = [];
        this._save();
        return { changes: count };
      }
    }

    return { changes: 0 };
  }

  close() {
    this._save();
    this.tables = {
      devices: [],
      app_settings: [],
      remote_preferences: [],
      app_shortcuts: [],
      connection_history: [],
      diagnostics: [],
    };
  }
}

function createConnection(dbPath) {
  if (dbPath !== ':memory:') {
    const dbDir = path.dirname(dbPath);
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }
  }

  // 1. Try node:sqlite (Built-in in Node 22+)
  try {
    const { DatabaseSync } = require('node:sqlite');
    return new DatabaseSync(dbPath);
  } catch (err) {
    // 2. Try better-sqlite3
    try {
      const Database = require('better-sqlite3');
      return new Database(dbPath);
    } catch (e) {
      // 3. Robust Embedded Fallback Driver
      return new FallbackSqliteDb(dbPath);
    }
  }
}

function seedDefaultShortcuts(db) {
  const row = db.prepare('SELECT COUNT(*) as count FROM app_shortcuts').get();
  const count = row ? (typeof row.count === 'number' ? row.count : parseInt(row.count, 10)) : 0;

  if (count === 0) {
    const now = new Date().toISOString();
    const defaults = [
      {
        id: 'shortcut-youtube',
        name: 'YouTube',
        package_id: 'com.google.android.youtube.tv',
        deep_link: 'https://www.youtube.com',
        icon_name: 'youtube',
        is_enabled: 1,
        sort_order: 1,
      },
      {
        id: 'shortcut-spotify',
        name: 'Spotify',
        package_id: 'com.spotify.tv.android',
        deep_link: 'spotify://',
        icon_name: 'spotify',
        is_enabled: 1,
        sort_order: 2,
      },
      {
        id: 'shortcut-netflix',
        name: 'Netflix',
        package_id: 'com.netflix.ninja',
        deep_link: 'netflix://',
        icon_name: 'netflix',
        is_enabled: 1,
        sort_order: 3,
      },
      {
        id: 'shortcut-prime',
        name: 'Prime Video',
        package_id: 'com.amazon.amazonvideo.livingroom',
        deep_link: 'https://app.primevideo.com',
        icon_name: 'primevideo',
        is_enabled: 1,
        sort_order: 4,
      },
    ];

    const insertStmt = db.prepare(
      `INSERT INTO app_shortcuts (id, name, package_id, deep_link, icon_name, is_enabled, sort_order, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    );

    for (const s of defaults) {
      insertStmt.run(s.id, s.name, s.package_id, s.deep_link, s.icon_name, s.is_enabled, s.sort_order, now);
    }
  }
}

function initDatabase(options = {}) {
  const dbPath = options.databasePath || config.databasePath;

  if (currentDb && currentDbPath === dbPath) {
    return currentDb;
  }

  if (currentDb) {
    closeDatabase();
  }

  currentDb = createConnection(dbPath);
  currentDbPath = dbPath;

  // Execute schema migrations
  initialSchema.up(currentDb);

  // Seed default shortcuts after tables exist
  seedDefaultShortcuts(currentDb);

  return currentDb;
}

function getDatabase(options = {}) {
  if (currentDb) {
    return currentDb;
  }
  return initDatabase(options);
}

function closeDatabase() {
  if (currentDb) {
    try {
      if (typeof currentDb.close === 'function') {
        currentDb.close();
      }
    } catch (err) {
      // Ignore close error during teardown
    }
    currentDb = null;
    currentDbPath = null;
  }
}

function resetDatabaseForTesting(options = {}) {
  closeDatabase();
  return initDatabase(options);
}

module.exports = {
  initDatabase,
  getDatabase,
  closeDatabase,
  resetDatabaseForTesting,
  seedDefaultShortcuts,
};
