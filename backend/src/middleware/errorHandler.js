'use strict';

const config = require('../config/environment');

function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  const message = err.message || 'An internal server error occurred';

  // Log error server-side safely without secrets
  if (config.logLevel === 'debug' || status === 500) {
    console.error(`[ERROR] ${req.method} ${req.originalUrl}:`, err.message);
  }

  // Safe response avoiding stack leaks in production
  const response = {
    success: false,
    error: message,
  };

  if (config.env === 'development') {
    response.stack = err.stack;
  }

  res.status(status).json(response);
}

function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: `Endpoint not found: ${req.method} ${req.originalUrl}`,
  });
}

module.exports = {
  errorHandler,
  notFoundHandler,
};
