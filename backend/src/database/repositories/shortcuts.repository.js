'use strict';

const { getDatabase } = require('../connection');
const crypto = require('crypto');

class ShortcutsRepository {
  constructor(db = null) {
    this._db = db;
  }

  get db() {
    return this._db || getDatabase();
  }

  findAll() {
    return this.db.prepare('SELECT * FROM app_shortcuts ORDER BY sort_order ASC').all();
  }

  findById(id) {
    return this.db.prepare('SELECT * FROM app_shortcuts WHERE id = ?').get(id);
  }

  create(data) {
    const id = data.id || crypto.randomUUID();
    const now = new Date().toISOString();
    this.db
      .prepare(
        `INSERT INTO app_shortcuts (id, name, package_id, deep_link, icon_name, is_enabled, sort_order, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      )
      .run(
        id,
        data.name,
        data.package_id,
        data.deep_link || null,
        data.icon_name || 'app',
        data.is_enabled !== undefined ? (data.is_enabled ? 1 : 0) : 1,
        data.sort_order || 0,
        now
      );
    return this.findById(id);
  }

  update(id, data) {
    const existing = this.findById(id);
    if (!existing) return null;
    const updated = {
      name: data.name !== undefined ? data.name : existing.name,
      package_id: data.package_id !== undefined ? data.package_id : existing.package_id,
      deep_link: data.deep_link !== undefined ? data.deep_link : existing.deep_link,
      icon_name: data.icon_name !== undefined ? data.icon_name : existing.icon_name,
      is_enabled: data.is_enabled !== undefined ? (data.is_enabled ? 1 : 0) : existing.is_enabled,
      sort_order: data.sort_order !== undefined ? data.sort_order : existing.sort_order,
    };
    this.db
      .prepare(
        `UPDATE app_shortcuts SET name = ?, package_id = ?, deep_link = ?, icon_name = ?, is_enabled = ?, sort_order = ? WHERE id = ?`
      )
      .run(
        updated.name,
        updated.package_id,
        updated.deep_link,
        updated.icon_name,
        updated.is_enabled,
        updated.sort_order,
        id
      );
    return this.findById(id);
  }

  delete(id) {
    const existing = this.findById(id);
    if (!existing) return false;
    this.db.prepare('DELETE FROM app_shortcuts WHERE id = ?').run(id);
    return true;
  }
}

const shortcutsRepository = new ShortcutsRepository();
module.exports = shortcutsRepository;
module.exports.ShortcutsRepository = ShortcutsRepository;
