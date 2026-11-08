import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tv_device.dart';
import '../models/app_settings.dart';
import '../utils/logger.dart';

class BackendApiClient {
  String _baseUrl;

  BackendApiClient({String baseUrl = 'http://192.168.1.100:3000'})
      : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl.replaceAll(RegExp(r'/+$'), '');
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/health')).timeout(
        const Duration(seconds: 3),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<TvDevice>> getDevices() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/devices')).timeout(
        const Duration(seconds: 4),
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        final List<dynamic> list = body['data'] ?? [];
        return list.map((item) => TvDevice.fromJson(item)).toList();
      }
    } catch (e) {
      AppLogger.warn('Backend unavailable, using local device list: $e', 'API');
    }
    return [];
  }

  Future<bool> syncDevice(TvDevice device) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/devices'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(device.toJson()),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDevice(String id) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/api/devices/$id')).timeout(
        const Duration(seconds: 4),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendDiagnosticLog({
    required String level,
    required String component,
    required String message,
    dynamic metadata,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/diagnostics/logs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'level': level,
          'component': component,
          'message': message,
          'metadata': metadata,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Backend may be offline; silently drop without breaking local operation
    }
  }
}
