'use strict';

const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settings.controller');
const { validateSettingsInput } = require('../middleware/validation');

router.get('/settings', (req, res, next) => settingsController.getSettings(req, res, next));
router.put('/settings', validateSettingsInput, (req, res, next) => settingsController.updateSettings(req, res, next));

module.exports = router;
