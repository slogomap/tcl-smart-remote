'use strict';

const settingsRepository = require('../database/repositories/settings.repository');
const shortcutsRepository = require('../database/repositories/shortcuts.repository');

class SettingsService {
  async getSettings() {
    const appSettings = settingsRepository.getAll();
    const shortcuts = shortcutsRepository.findAll();

    // Default configuration if not set
    const merged = {
      theme: 'dark',
      hapticFeedback: true,
      buttonSound: false,
      autoReconnect: true,
      connectionTimeoutMs: 5000,
      wolBroadcastPort: 9,
      shortcuts,
      ...appSettings,
    };

    return merged;
  }

  async updateSettings(newSettings) {
    if (!newSettings || typeof newSettings !== 'object') {
      const error = new Error('Settings payload must be a valid JSON object');
      error.status = 400;
      throw error;
    }

    // Save individual settings into key-value store
    const updated = settingsRepository.updateMany(newSettings);
    return this.getSettings();
  }
}

module.exports = new SettingsService();
