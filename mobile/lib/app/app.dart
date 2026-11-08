import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/network_service.dart';
import '../services/backend_api_client.dart';
import '../services/diagnostics_service.dart';
import '../state/remote_provider.dart';
import '../state/discovery_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import 'routes.dart';

class TclSmartRemoteApp extends StatelessWidget {
  final StorageService storageService;
  final NetworkService networkService;
  final BackendApiClient backendApiClient;
  final DiagnosticsService diagnosticsService;

  const TclSmartRemoteApp({
    Key? key,
    required this.storageService,
    required this.networkService,
    required this.backendApiClient,
    required this.diagnosticsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<NetworkService>.value(value: networkService),
        Provider<BackendApiClient>.value(value: backendApiClient),
        Provider<DiagnosticsService>.value(value: diagnosticsService),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            storageService: storageService,
            backendApiClient: backendApiClient,
          ),
        ),
        ChangeNotifierProvider<DiscoveryProvider>(
          create: (_) => DiscoveryProvider(
            storageService: storageService,
            backendApiClient: backendApiClient,
          ),
        ),
        ChangeNotifierProvider<RemoteProvider>(
          create: (_) => RemoteProvider(
            storageService: storageService,
            networkService: networkService,
            backendApiClient: backendApiClient,
            diagnosticsService: diagnosticsService,
          )..init(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'TCL SMART REMOTE',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            initialRoute: AppRoutes.remote,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
