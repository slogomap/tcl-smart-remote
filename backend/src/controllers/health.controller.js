'use strict';

class HealthController {
  getHealth(req, res) {
    res.status(200).json({
      status: 'ok',
      service: 'TCL SMART REMOTE Backend API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
    });
  }
}

module.exports = new HealthController();
