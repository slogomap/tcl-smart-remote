'use strict';

const diagnosticsRepository = require('../database/repositories/diagnostics.repository');
const os = require('os');

class DiagnosticsService {
  async getDiagnostics(limit = 100) {
    const logs = diagnosticsRepository.findAll(limit);
    const systemInfo = {
      platform: os.platform(),
      release: os.release(),
      uptimeSeconds: Math.floor(os.uptime()),
      nodeVersion: process.version,
      memoryUsage: process.memoryUsage(),
      timestamp: new Date().toISOString(),
    };

    return {
      system: systemInfo,
      logsCount: logs.length,
      logs,
    };
  }

  async recordLog(level, component, message, metadata = null) {
    return diagnosticsRepository.log(level, component, message, metadata);
  }

  async clearLogs() {
    diagnosticsRepository.clear();
    return { success: true, message: 'Diagnostic logs cleared' };
  }
}

module.exports = new DiagnosticsService();
