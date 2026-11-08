'use strict';

const test = require('node:test');
const assert = require('node:assert');
const path = require('path');
const os = require('os');
const fs = require('fs');
const { createApp } = require('../src/app');
const { closeDatabase } = require('../src/database/connection');

test('GET /api/health returns 200 and healthy status', async (t) => {
  const tempDbPath = path.join(os.tmpdir(), `test-health-${Date.now()}-${Math.random().toString(36).substring(2)}.sqlite`);
  
  t.after(() => {
    closeDatabase();
    if (fs.existsSync(tempDbPath)) {
      try { fs.unlinkSync(tempDbPath); } catch (_) {}
    }
  });

  const app = createApp({ databasePath: tempDbPath });

  const req = {
    method: 'GET',
    url: '/api/health',
    headers: {},
  };

  let resStatus = null;
  let resJson = null;

  const res = {
    status(code) {
      resStatus = code;
      return this;
    },
    json(data) {
      resJson = data;
      return this;
    },
    setHeader() {},
  };

  await new Promise((resolve) => {
    app.handle(req, res, () => resolve());
    if (resStatus !== null) resolve();
  });

  assert.strictEqual(resStatus, 200);
  assert.strictEqual(resJson.status, 'ok');
  assert.strictEqual(resJson.service, 'TCL SMART REMOTE Backend API');
  assert.ok(resJson.timestamp);
  assert.ok(typeof resJson.uptimeSeconds === 'number');
});
