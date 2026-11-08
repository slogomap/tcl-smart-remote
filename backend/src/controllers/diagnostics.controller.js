'use strict';

const diagnosticsService = require('../services/diagnostics.service');

class DiagnosticsController {
  async getDiagnostics(req, res, next) {
    try {
      const limit = parseInt(req.query.limit, 10) || 100;
      const diagnostics = await diagnosticsService.getDiagnostics(limit);
      res.status(200).json({ success: true, data: diagnostics });
    } catch (err) {
      next(err);
    }
  }

  async createLog(req, res, next) {
    try {
      const { level, component, message, metadata } = req.body;
      const log = await diagnosticsService.recordLog(level || 'INFO', component || 'App', message, metadata);
      res.status(201).json({ success: true, data: log });
    } catch (err) {
      next(err);
    }
  }

  async clearLogs(req, res, next) {
    try {
      const result = await diagnosticsService.clearLogs();
      res.status(200).json({ success: true, message: result.message });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DiagnosticsController();
