import 'dart:collection';
import '../models/diagnostic_log.dart';
import '../services/backend_api_client.dart';
import '../utils/logger.dart';

class DiagnosticsService {
  final Queue<DiagnosticLog> _logQueue = Queue<DiagnosticLog>();
  static const int maxLogs = 200;
  final BackendApiClient? _backendClient;

  DiagnosticsService({BackendApiClient? backendClient}) : _backendClient = backendClient;

  List<DiagnosticLog> get logs => _logQueue.toList();

  void record({
    required String level,
    required String component,
    required String message,
    dynamic metadata,
  }) {
    final entry = DiagnosticLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      level: level,
      component: component,
      message: message,
      metadata: metadata,
      timestamp: DateTime.now(),
    );

    if (_logQueue.length >= maxLogs) {
      _logQueue.removeFirst();
    }
    _logQueue.addLast(entry);

    // Also mirror to backend in background if available
    _backendClient?.sendDiagnosticLog(
      level: level,
      component: component,
      message: message,
      metadata: metadata,
    );
  }

  void clear() {
    _logQueue.clear();
  }
}
