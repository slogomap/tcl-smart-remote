'use strict';

const express = require('express');
const { initDatabase } = require('./database/connection');
const { securityMiddleware } = require('./middleware/security');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const healthRoutes = require('./routes/health.routes');
const devicesRoutes = require('./routes/devices.routes');
const settingsRoutes = require('./routes/settings.routes');
const diagnosticsRoutes = require('./routes/diagnostics.routes');

function createApp(options = {}) {
  // Ensure database initialization and migrations complete before handling requests
  initDatabase(options);

  const app = express();

  // Security Middleware
  securityMiddleware(app);

  // Body parser
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Routes
  app.use('/api', healthRoutes);
  app.use('/api', devicesRoutes);
  app.use('/api', settingsRoutes);
  app.use('/api', diagnosticsRoutes);

  // Fallback 404
  app.use(notFoundHandler);

  // Centralized Error Handler
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
