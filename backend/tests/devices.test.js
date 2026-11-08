'use strict';

const test = require('node:test');
const assert = require('node:assert');
const path = require('path');
const os = require('os');
const fs = require('fs');
const deviceService = require('../src/services/device.service');
const { resetDatabaseForTesting, closeDatabase } = require('../src/database/connection');

test('DeviceService CRUD operations in isolated database', async (t) => {
  const tempDbPath = path.join(os.tmpdir(), `test-devices-${Date.now()}-${Math.random().toString(36).substring(2)}.sqlite`);
  
  t.after(() => {
    closeDatabase();
    if (fs.existsSync(tempDbPath)) {
      try { fs.unlinkSync(tempDbPath); } catch (_) {}
    }
  });

  resetDatabaseForTesting({ databasePath: tempDbPath });

  // 1. Create device
  const newDevice = await deviceService.registerDevice({
    name: 'Living Room TCL C835',
    ip_address: '192.168.1.150',
    port: 6467,
    model: 'TCL 65C835 Google TV',
    os_version: 'Android 12',
    mac_address: 'AA:BB:CC:DD:EE:FF',
  });

  assert.ok(newDevice.id, 'Device ID should be generated');
  assert.strictEqual(newDevice.name, 'Living Room TCL C835');
  assert.strictEqual(newDevice.ip_address, '192.168.1.150');

  // 2. Get by ID
  const fetched = await deviceService.getDeviceById(newDevice.id);
  assert.strictEqual(fetched.name, 'Living Room TCL C835');
  assert.strictEqual(fetched.ip_address, '192.168.1.150');

  // 3. List all devices
  const all = await deviceService.getAllDevices();
  assert.ok(Array.isArray(all));
  assert.strictEqual(all.length, 1);
  assert.strictEqual(all[0].id, newDevice.id);

  // 4. Update device
  const updated = await deviceService.updateDevice(newDevice.id, {
    name: 'Living Room TCL Master',
    is_paired: 1,
  });
  assert.strictEqual(updated.name, 'Living Room TCL Master');
  assert.strictEqual(updated.is_paired, 1);

  // 5. Delete device
  const deleted = await deviceService.deleteDevice(newDevice.id);
  assert.strictEqual(deleted, true);

  // 6. Verification after delete
  await assert.rejects(async () => {
    await deviceService.getDeviceById(newDevice.id);
  });
});
