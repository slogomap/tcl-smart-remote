'use strict';

const test = require('node:test');
const assert = require('node:assert');
const path = require('path');
const os = require('os');
const fs = require('fs');
const shortcutsRepo = require('../src/database/repositories/shortcuts.repository');
const diagnosticsRepo = require('../src/database/repositories/diagnostics.repository');
const { resetDatabaseForTesting, closeDatabase, initDatabase, getDatabase } = require('../src/database/connection');

test('Database schema verification, shortcuts seeding and diagnostics logging', async (t) => {
  const tempDbPath = path.join(os.tmpdir(), `test-database-${Date.now()}-${Math.random().toString(36).substring(2)}.sqlite`);

  t.after(() => {
    closeDatabase();
    if (fs.existsSync(tempDbPath)) {
      try { fs.unlinkSync(tempDbPath); } catch (_) {}
    }
  });

  const db = resetDatabaseForTesting({ databasePath: tempDbPath });

  // 1. Verify all required tables exist
  const requiredTables = [
    'devices',
    'app_settings',
    'remote_preferences',
    'app_shortcuts',
    'connection_history',
    'diagnostics',
  ];

  for (const table of requiredTables) {
    // Should prepare and execute without throwing 'no such table'
    const rows = db.prepare(`SELECT * FROM ${table} LIMIT 1`).all();
    assert.ok(Array.isArray(rows), `Table '${table}' must exist and return array`);
  }

  // 2. Verify default shortcuts seeded (YouTube and Spotify)
  const shortcuts = shortcutsRepo.findAll();
  assert.ok(shortcuts.length >= 2, 'Default shortcuts must be seeded');

  const yt = shortcuts.find((s) => s.name === 'YouTube');
  assert.ok(yt, 'YouTube shortcut present');
  assert.strictEqual(yt.package_id, 'com.google.android.youtube.tv');
  assert.strictEqual(yt.deep_link, 'https://www.youtube.com');

  const spotify = shortcuts.find((s) => s.name === 'Spotify');
  assert.ok(spotify, 'Spotify shortcut present');
  assert.strictEqual(spotify.package_id, 'com.spotify.tv.android');
  assert.strictEqual(spotify.deep_link, 'spotify://');

  // 3. Verify initialization is idempotent and safe to run multiple times
  const countBefore = shortcutsRepo.findAll().length;
  initDatabase({ databasePath: tempDbPath });
  const countAfter = shortcutsRepo.findAll().length;
  assert.strictEqual(countBefore, countAfter, 'Re-running initDatabase must not duplicate shortcuts');

  // 4. Diagnostics repository logging and retrieval
  const log = diagnosticsRepo.log('INFO', 'TestEngine', 'Testing diagnostics logging in isolated DB', { code: 123 });
  assert.ok(log.id);
  assert.strictEqual(log.level, 'INFO');
  assert.strictEqual(log.component, 'TestEngine');

  const logs = diagnosticsRepo.findAll(10);
  assert.ok(logs.length > 0);
  assert.strictEqual(logs[0].component, 'TestEngine');

  // 5. Diagnostics clear
  diagnosticsRepo.clear();
  const cleared = diagnosticsRepo.findAll(10);
  assert.strictEqual(cleared.length, 0);
});
