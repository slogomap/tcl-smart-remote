'use strict';

const { getDatabase } = require('../connection');
const crypto = require('crypto');

class DeviceRepository {
  constructor(db = null) {
    this._db = db;
  }

  get db() {
    return this._db || getDatabase();
  }

  findAll() {
    return this.db.prepare('SELECT * FROM devices ORDER BY last_connected_at DESC').all();
  }

  findById(id) {
    return this.db.prepare('SELECT * FROM devices WHERE id = ?').get(id);
  }

  findByIp(ip) {
    return this.db.prepare('SELECT * FROM devices WHERE ip_address = ?').get(ip);
  }

  create(device) {
    const id = device.id || crypto.randomUUID();
    const now = new Date().toISOString();
    const isPaired = device.is_paired ? 1 : 0;
    const port = device.port || 6467;

    this.db
      .prepare(
        `INSERT INTO devices (id, name, ip_address, port, mac_address, model, os_version, is_paired, last_connected_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
      .run(
        id,
        device.name,
        device.ip_address,
        port,
        device.mac_address || null,
        device.model || 'TCL Google TV',
        device.os_version || 'Android TV 12',
        isPaired,
        device.last_connected_at || null,
        now,
        now
      );

    return this.findById(id);
  }

  update(id, data) {
    const existing = this.findById(id);
    if (!existing) return null;

    const updated = {
      name: data.name !== undefined ? data.name : existing.name,
      ip_address: data.ip_address !== undefined ? data.ip_address : existing.ip_address,
      port: data.port !== undefined ? data.port : existing.port,
      mac_address: data.mac_address !== undefined ? data.mac_address : existing.mac_address,
      model: data.model !== undefined ? data.model : existing.model,
      os_version: data.os_version !== undefined ? data.os_version : existing.os_version,
      is_paired: data.is_paired !== undefined ? (data.is_paired ? 1 : 0) : existing.is_paired,
      last_connected_at:
        data.last_connected_at !== undefined ? data.last_connected_at : existing.last_connected_at,
    };

    this.db
      .prepare(
        `UPDATE devices SET name = ?, ip_address = ?, port = ?, mac_address = ?, model = ?, os_version = ?, is_paired = ?, last_connected_at = ? WHERE id = ?`
      )
      .run(
        updated.name,
        updated.ip_address,
        updated.port,
        updated.mac_address,
        updated.model,
        updated.os_version,
        updated.is_paired,
        updated.last_connected_at,
        id
      );

    return this.findById(id);
  }

  delete(id) {
    const existing = this.findById(id);
    if (!existing) return false;
    this.db.prepare('DELETE FROM devices WHERE id = ?').run(id);
    return true;
  }
}

const deviceRepository = new DeviceRepository();
module.exports = deviceRepository;
module.exports.DeviceRepository = DeviceRepository;
