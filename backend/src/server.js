'use strict';

const { createApp } = require('./app');
const { closeDatabase } = require('./database/connection');
const config = require('./config/environment');

const app = createApp();

const server = app.listen(config.port, () => {
  console.log(`===============================================`);
  console.log(` TCL SMART REMOTE - BACKEND SERVICE`);
  console.log(` Server running on port: ${config.port}`);
  console.log(` Environment: ${config.env}`);
  console.log(` Database: ${config.databasePath}`);
  console.log(` Health check: http://localhost:${config.port}/api/health`);
  console.log(`===============================================`);
});

// Graceful shutdown
function shutdown() {
  console.log('Shutting down TCL Smart Remote backend service...');
  server.close(() => {
    closeDatabase();
    console.log('HTTP server and database closed.');
    process.exit(0);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

module.exports = server;
