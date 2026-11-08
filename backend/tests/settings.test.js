'use strict';

const test = require('node:test');
const assert = require('node:assert');
const path = require('path');
const os = require('os');
const fs = require('fs');
const settingsService = require('../src/services/settings.service');
const { resetDatabaseForTesting, closeDatabase } = require('../src/database/connection');

test('SettingsService gets default settings and updates values in isolated database', async (t) => {
  const tempDbPath = path.join(os.tmpdir(), `test-settings-${Date.now()}-${Math.random().toString(36).substring(2)}.sqlite`);

  t.after(() => {
    closeDatabase();
    if (fs.existsSync(tempDbPath)) {
      try { fs.unlinkSync(tempDbPath); } catch (_) {}
    }
  });

  resetDatabaseForTesting({ databasePath: tempDbPath });

  // 1. Initial settings
  const initial = await settingsService.getSettings();
  assert.ok(initial);
  assert.strictEqual(initial.theme, 'dark');
  assert.strictEqual(initial.hapticFeedback, true);
  assert.ok(Array.isArray(initial.shortcuts), 'Shortcuts should be present in settings');
  assert.ok(initial.shortcuts.length >= 2, 'Default shortcuts seeded');

  // Verify YouTube and Spotify in shortcuts
  const yt = initial.shortcuts.find((s) => s.name === 'YouTube');
  assert.ok(yt, 'YouTube shortcut must be present');
  assert.strictEqual(yt.package_id, 'com.google.android.youtube.tv');

  const spotify = initial.shortcuts.find((s) => s.name === 'Spotify');
  assert.ok(spotify, 'Spotify shortcut must be present');
  assert.strictEqual(spotify.package_id, 'com.spotify.tv.android');

  // 2. Update settings
  const updated = await settingsService.updateSettings({
    theme: 'light',
    hapticFeedback: false,
    autoReconnect: true,
  });

  assert.strictEqual(updated.theme, 'light');
  assert.strictEqual(updated.hapticFeedback, false);
  assert.strictEqual(updated.autoReconnect, true);

  // 3. Confirm persistence
  const reloaded = await settingsService.getSettings();
  assert.strictEqual(reloaded.theme, 'light');
  assert.strictEqual(reloaded.hapticFeedback, false);
});
