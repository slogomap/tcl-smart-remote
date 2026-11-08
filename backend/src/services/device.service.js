'use strict';

const deviceRepository = require('../database/repositories/device.repository');
const diagnosticsRepository = require('../database/repositories/diagnostics.repository');

class DeviceService {
  async getAllDevices() {
    return deviceRepository.findAll();
  }

  async getDeviceById(id) {
    const device = deviceRepository.findById(id);
    if (!device) {
      const error = new Error(`Device with ID '${id}' not found`);
      error.status = 404;
      throw error;
    }
    return device;
  }

  async registerDevice(data) {
    const existing = deviceRepository.findByIp(data.ip_address);
    if (existing) {
      diagnosticsRepository.log('INFO', 'DeviceService', `Updating existing device at IP ${data.ip_address}`);
      return deviceRepository.update(existing.id, data);
    }
    diagnosticsRepository.log('INFO', 'DeviceService', `Registering new device '${data.name}' at IP ${data.ip_address}`);
    return deviceRepository.create(data);
  }

  async updateDevice(id, data) {
    await this.getDeviceById(id);
    return deviceRepository.update(id, data);
  }

  async deleteDevice(id) {
    await this.getDeviceById(id);
    diagnosticsRepository.log('INFO', 'DeviceService', `Removing device with ID ${id}`);
    return deviceRepository.delete(id);
  }
}

module.exports = new DeviceService();
