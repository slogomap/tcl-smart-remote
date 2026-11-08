import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tv_device.dart';
import '../state/discovery_provider.dart';
import '../state/remote_provider.dart';
import '../theme/colors.dart';
import '../tv/pairing/tv_pairer.dart';

class PairingScreen extends StatefulWidget {
  final TvDevice device;

  const PairingScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPairing = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPairingHandshake();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _startPairingHandshake() async {
    setState(() {
      _isPairing = true;
      _statusMessage = 'Connecting to television over secure TLS socket...';
      _errorMessage = null;
    });

    final remote = context.read<RemoteProvider>();
    final pairer = remote.pairer;

    // Build client security context
    final secContext = SecurityContext(withTrustedRoots: false);

    final success = await pairer.initiatePairing(
      device: widget.device,
      clientSecurityContext: secContext,
    );

    if (mounted) {
      setState(() {
        _isPairing = false;
        if (success) {
          _statusMessage = 'Enter the 6-character code displayed on your TV screen:';
        } else {
          _errorMessage = pairer.lastError ?? 'Failed to connect for pairing. Check that the TV is powered on.';
        }
      });
    }
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'Please enter the complete PIN code displayed on your TV.';
      });
      return;
    }

    setState(() {
      _isPairing = true;
      _statusMessage = 'Validating pairing secret with television...';
      _errorMessage = null;
    });

    final remote = context.read<RemoteProvider>();
    final pairer = remote.pairer;

    final success = await pairer.submitPin(
      pinCode: pin,
      clientCertDer: remote.clientCertDer,
    );

    if (mounted) {
      setState(() {
        _isPairing = false;
      });

      if (success) {
        // Mark device as paired and save in database
        final pairedDevice = widget.device.copyWith(isPaired: true, lastConnectedAt: DateTime.now());
        await context.read<DiscoveryProvider>().saveDevice(pairedDevice);

        // Connect directly to remote command service
        await remote.connectToDevice(pairedDevice);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.statusGreen),
                  SizedBox(width: 10),
                  Text('Pairing Successful!'),
                ],
              ),
              content: Text(
                '${widget.device.name} is now securely paired. You can now control your TV.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Return to remote
                  },
                  child: const Text('Start Controlling TV'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = pairer.lastError ?? 'Incorrect pairing code entered. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure TV Pairing'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.tclRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 36, color: AppColors.tclRed),
              ),
              const SizedBox(height: 16),
              Text(
                'Pair with ${widget.device.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.device.ipAddress,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 24),

              if (_isPairing) ...[
                const CircularProgressIndicator(color: AppColors.tclRed),
                const SizedBox(height: 16),
                Text(
                  _statusMessage ?? 'Processing...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.statusRed, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.statusRed, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _startPairingHandshake,
                        child: const Text('Retry Pairing'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  _statusMessage ?? 'Enter the 6-character PIN displayed on the TV:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _pinController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'PIN',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitPin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Confirm & Pair'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
