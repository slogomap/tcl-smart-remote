class AppConstants {
  static const String appName = 'TCL SMART REMOTE';
  static const String appVersion = '1.0.0';

  // Android TV Remote Service v2 Standard Ports
  static const int tvRemoteServicePort = 6467;
  static const int tvPairingServicePort = 6467; // Port 6467 for v2, fallback 6466
  static const int tvPairingServicePortLegacy = 6466;

  // mDNS Discovery Service Types
  static const String mdnsServiceV2 = '_androidtvremote2._tcp';
  static const String mdnsServiceLegacy = '_androidtvremote._tcp';

  // Network Timeouts
  static const Duration defaultSocketTimeout = Duration(seconds: 5);
  static const Duration pairingTimeout = Duration(seconds: 30);
  static const Duration discoveryTimeout = Duration(seconds: 8);
  static const Duration keepalivePingInterval = Duration(seconds: 5);

  // Secure Storage Keys
  static const String secKeyClientCert = 'tcl_remote_client_cert_pem';
  static const String secKeyClientPrivateKey = 'tcl_remote_client_private_key_pem';
  static const String secKeyServerCertPrefix = 'tcl_remote_server_cert_';

  // Local Preferences Keys
  static const String prefSelectedDeviceId = 'pref_selected_device_id';
  static const String prefSavedDevices = 'pref_saved_devices_json';
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefHapticFeedback = 'pref_haptic_feedback';
  static const String prefButtonSound = 'pref_button_sound';
  static const String prefAutoReconnect = 'pref_auto_reconnect';
  static const String prefBackendUrl = 'pref_backend_url';

  // Default Backend URL (Local Node.js REST API)
  static const String defaultBackendUrl = 'http://192.168.1.100:3000';
}
