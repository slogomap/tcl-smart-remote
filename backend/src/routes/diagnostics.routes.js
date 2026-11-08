'use strict';

const express = require('express');
const router = express.Router();
const diagnosticsController = require('../controllers/diagnostics.controller');

router.get('/diagnostics', (req, res, next) => diagnosticsController.getDiagnostics(req, res, next));
router.post('/diagnostics/logs', (req, res, next) => diagnosticsController.createLog(req, res, next));
router.delete('/diagnostics/logs', (req, res, next) => diagnosticsController.clearLogs(req, res, next));

module.exports = router;
