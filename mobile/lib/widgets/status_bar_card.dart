import 'package:flutter/material.dart';
import '../models/connection_state.dart';
import '../theme/colors.dart';

class StatusBarCard extends StatelessWidget {
  final RemoteConnectionState connectionState;
  final VoidCallback onTapTvStatus;

  const StatusBarCard({
    Key? key,
    required this.connectionState,
    required this.onTapTvStatus,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (connectionState.status) {
      case DeviceConnectionStatus.connected:
        return AppColors.statusGreen;
      case DeviceConnectionStatus.connecting:
      case DeviceConnectionStatus.pairing:
        return AppColors.statusYellow;
      case DeviceConnectionStatus.disconnected:
      case DeviceConnectionStatus.offline:
      case DeviceConnectionStatus.error:
        return AppColors.statusRed;
    }
  }

  String _getStatusText() {
    switch (connectionState.status) {
      case DeviceConnectionStatus.connected:
        return 'Connected';
      case DeviceConnectionStatus.connecting:
        return 'Connecting...';
      case DeviceConnectionStatus.pairing:
        return 'Pairing...';
      case DeviceConnectionStatus.offline:
        return 'Wi-Fi Offline';
      case DeviceConnectionStatus.disconnected:
        return 'Disconnected';
      case DeviceConnectionStatus.error:
        return 'Connection Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: App Header & Phone Battery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Title
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.tclRed,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tclRed.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'TCL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TCL SMART REMOTE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              // Phone Battery Indicator
              Row(
                children: [
                  Icon(
                    connectionState.batteryLevel != null && connectionState.batteryLevel! <= 20
                        ? Icons.battery_alert
                        : Icons.battery_charging_full,
                    size: 18,
                    color: connectionState.batteryLevel != null && connectionState.batteryLevel! <= 20
                        ? AppColors.statusRed
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${connectionState.batteryLevel ?? 100}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 10),

          // Row 2: Television Status & Tap Target
          InkWell(
            onTap: onTapTvStatus,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                // Glowing Status Dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // TV Name & IP
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connectionState.activeDeviceName ?? 'No Television Selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        connectionState.activeDeviceIp != null
                            ? '${connectionState.activeDeviceIp} • $statusText'
                            : 'Tap to discover & connect',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
