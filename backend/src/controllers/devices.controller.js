'use strict';

const deviceService = require('../services/device.service');

class DevicesController {
  async getAllDevices(req, res, next) {
    try {
      const devices = await deviceService.getAllDevices();
      res.status(200).json({ success: true, count: devices.length, data: devices });
    } catch (err) {
      next(err);
    }
  }

  async getDeviceById(req, res, next) {
    try {
      const device = await deviceService.getDeviceById(req.params.id);
      res.status(200).json({ success: true, data: device });
    } catch (err) {
      next(err);
    }
  }

  async createDevice(req, res, next) {
    try {
      const device = await deviceService.registerDevice(req.body);
      res.status(201).json({ success: true, data: device });
    } catch (err) {
      next(err);
    }
  }

  async updateDevice(req, res, next) {
    try {
      const device = await deviceService.updateDevice(req.params.id, req.body);
      res.status(200).json({ success: true, data: device });
    } catch (err) {
      next(err);
    }
  }

  async deleteDevice(req, res, next) {
    try {
      await deviceService.deleteDevice(req.params.id);
      res.status(200).json({ success: true, message: 'Device successfully removed' });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DevicesController();
