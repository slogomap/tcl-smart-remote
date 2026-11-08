'use strict';

// IP address regex (IPv4)
const IP_REGEX = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;

function validateDeviceInput(req, res, next) {
  const { name, ip_address, port } = req.body;

  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Device name is required and must be a non-empty string',
    });
  }

  if (name.length > 100) {
    return res.status(400).json({
      success: false,
      error: 'Device name cannot exceed 100 characters',
    });
  }

  if (!ip_address || typeof ip_address !== 'string' || !IP_REGEX.test(ip_address.trim())) {
    return res.status(400).json({
      success: false,
      error: 'Valid IPv4 address is required',
    });
  }

  if (port !== undefined) {
    const portNum = parseInt(port, 10);
    if (isNaN(portNum) || portNum < 1 || portNum > 65535) {
      return res.status(400).json({
        success: false,
        error: 'Port must be an integer between 1 and 65535',
      });
    }
  }

  next();
}

function validateSettingsInput(req, res, next) {
  if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body)) {
    return res.status(400).json({
      success: false,
      error: 'Settings body must be a valid JSON object',
    });
  }
  next();
}

module.exports = {
  validateDeviceInput,
  validateSettingsInput,
};
