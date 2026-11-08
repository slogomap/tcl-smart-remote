import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'services/storage_service.dart';
import 'services/network_service.dart';
import 'services/backend_api_client.dart';
import 'services/diagnostics_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for remote handset ergonomics
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1015),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  AppLogger.info('Initializing TCL SMART REMOTE services...', 'Bootstrap');

  // Initialize Local-First Storage
  final storageService = StorageService();
  await storageService.init();

  final settings = storageService.getSettings();

  // Initialize Backend REST Client
  final backendApiClient = BackendApiClient(baseUrl: settings.backendUrl);

  // Initialize Diagnostics
  final diagnosticsService = DiagnosticsService(backendClient: backendApiClient);

  // Initialize Network & Battery Monitoring
  final networkService = NetworkService();
  networkService.startMonitoring();

  AppLogger.info('Services initialized. Launching application UI...', 'Bootstrap');

  runApp(
    TclSmartRemoteApp(
      storageService: storageService,
      networkService: networkService,
      backendApiClient: backendApiClient,
      diagnosticsService: diagnosticsService,
    ),
  );
}
