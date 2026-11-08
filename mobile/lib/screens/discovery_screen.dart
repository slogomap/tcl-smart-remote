import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tv_device.dart';
import '../state/discovery_provider.dart';
import '../state/remote_provider.dart';
import '../theme/colors.dart';
import '../widgets/device_card.dart';
import 'pairing_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().startScan();
    });
  }

  void _showManualIpDialog() {
    final ipController = TextEditingController();
    final nameController = TextEditingController(text: 'TCL Living Room TV');
    final macController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Television by IP'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your TCL Google TV local IP address. You can find this on your TV under Settings > Network & Internet.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'IPv4 Address',
                  hintText: 'e.g. 192.168.1.150',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: macController,
                decoration: const InputDecoration(
                  labelText: 'MAC Address (Optional, for Wake-on-LAN)',
                  hintText: 'e.g. AA:BB:CC:DD:EE:FF',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                final device = await context.read<DiscoveryProvider>().addManualDevice(
                  name: nameController.text.trim(),
                  ipAddress: ip,
                  macAddress: macController.text.trim(),
                );
                _navigateToPairing(device);
              }
            },
            child: const Text('Add & Pair'),
          ),
        ],
      ),
    );
  }

  void _navigateToPairing(TvDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PairingScreen(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryProvider>();
    final remote = context.watch<RemoteProvider>();
    final isScanning = discovery.isScanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Television'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add by IP',
            onPressed: _showManualIpDialog,
          ),
          IconButton(
            icon: isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Scan for TVs',
            onPressed: isScanning ? null : () => discovery.startScan(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Scanning Status Banner
            if (isScanning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tclRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tclRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tclRed),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Searching for TCL Google TVs on your Wi-Fi network via mDNS...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Discovered Section
            if (discovery.discoveredDevices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text(
                  'DISCOVERED ON LOCAL NETWORK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ),
              ...discovery.discoveredDevices.map((dev) {
                final isCurrent = remote.state.activeDeviceId == dev.id && remote.state.isConnected;
                return DeviceCard(
                  device: dev,
                  isConnected: isCurrent,
                  onConnect: () => remote.connectToDevice(dev),
                  onPair: () => _navigateToPairing(dev),
                  onForget: () => discovery.forgetDevice(dev.id),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Saved Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'SAVED TELEVISIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.darkTextMuted,
                ),
              ),
            ),
            if (discovery.savedDevices.isEmpty && discovery.discoveredDevices.isEmpty && !isScanning)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Icon(Icons.tv_off, size: 48, color: AppColors.darkTextMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'No TVs Found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ensure your phone and TCL TV are connected to the exact same Wi-Fi network.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add by IP Address'),
                      onPressed: _showManualIpDialog,
                    ),
                  ],
                ),
              )
            else
              ...discovery.savedDevices.map((dev) {
                final isCurrent = remote.state.activeDeviceId == dev.id && remote.state.isConnected;
                return DeviceCard(
                  device: dev,
                  isConnected: isCurrent,
                  onConnect: () => remote.connectToDevice(dev),
                  onPair: () => _navigateToPairing(dev),
                  onForget: () => discovery.forgetDevice(dev.id),
                );
              }),
          ],
        ),
      ),
    );
  }
}
