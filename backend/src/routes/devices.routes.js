'use strict';

const express = require('express');
const router = express.Router();
const devicesController = require('../controllers/devices.controller');
const { validateDeviceInput } = require('../middleware/validation');

router.get('/devices', (req, res, next) => devicesController.getAllDevices(req, res, next));
router.post('/devices', validateDeviceInput, (req, res, next) => devicesController.createDevice(req, res, next));
router.get('/devices/:id', (req, res, next) => devicesController.getDeviceById(req, res, next));
router.put('/devices/:id', (req, res, next) => devicesController.updateDevice(req, res, next));
router.delete('/devices/:id', (req, res, next) => devicesController.deleteDevice(req, res, next));

module.exports = router;
