import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diagnostic_log.dart';
import '../services/diagnostics_service.dart';
import '../state/remote_provider.dart';
import '../theme/colors.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late List<DiagnosticLog> _logs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshLogs();
  }

  void _refreshLogs() {
    final diag = context.read<DiagnosticsService>();
    setState(() {
      _logs = diag.logs.reversed.toList();
    });
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return AppColors.statusRed;
      case 'WARN':
        return AppColors.statusYellow;
      case 'INFO':
        return AppColors.statusGreen;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remote = context.watch<RemoteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics & Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Logs',
            onPressed: () {
              context.read<DiagnosticsService>().clear();
              _refreshLogs();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Connection Status Metrics Bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Socket Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        remote.state.status.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: remote.state.isConnected ? AppColors.statusGreen : AppColors.statusRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target IP & Port:', style: TextStyle(color: AppColors.darkTextSecondary)),
                      Text(
                        '${remote.state.activeDeviceIp ?? 'None'}:6467',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Local Wi-Fi Link:', style: TextStyle(color: AppColors.darkTextSecondary)),
                      Text(
                        remote.state.isLocalWifiActive ? 'Connected (LAN)' : 'Offline',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: remote.state.isLocalWifiActive ? AppColors.statusGreen : AppColors.statusRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Log List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT SYSTEM LOGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                  Text(
                    '${_logs.length} entries',
                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                  ),
                ],
              ),
            ),

            // Log List
            Expanded(
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No diagnostic logs recorded yet.',
                        style: TextStyle(color: AppColors.darkTextMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final levelColor = _getLevelColor(log.level);
                        final timeStr = log.timestamp.toIso8601String().substring(11, 19);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: levelColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.level,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: levelColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextMuted,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '[${log.component}] ${log.message}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (log.metadata != null)
                                      Text(
                                        log.metadata.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.darkTextMuted,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
