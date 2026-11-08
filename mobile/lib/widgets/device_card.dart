import 'package:flutter/material.dart';
import '../models/tv_device.dart';
import '../theme/colors.dart';

class DeviceCard extends StatelessWidget {
  final TvDevice device;
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onPair;
  final VoidCallback onForget;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.isConnected,
    required this.onConnect,
    required this.onPair,
    required this.onForget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected
              ? AppColors.statusGreen
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isConnected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // TV Icon Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.statusGreen.withOpacity(0.15)
                    : (isDark ? AppColors.darkButton : AppColors.lightCard),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tv,
                color: isConnected ? AppColors.statusGreen : AppColors.tclRed,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // TV Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${device.ipAddress} • ${device.model}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: device.isPaired ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          device.isPaired ? 'PAIRED' : 'NOT PAIRED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: device.isPaired ? Colors.blue : Colors.orange,
                          ),
                        ),
                      ),
                      if (isConnected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                if (!device.isPaired)
                  ElevatedButton(
                    onPressed: onPair,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Pair TV'),
                  )
                else if (!isConnected)
                  OutlinedButton(
                    onPressed: onConnect,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Connect'),
                  ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.statusRed),
                  tooltip: 'Forget TV',
                  onPressed: onForget,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
