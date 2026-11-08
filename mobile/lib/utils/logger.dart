import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void log(String message, {LogLevel level = LogLevel.info, String component = 'Remote'}) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = '[$time][${level.name.toUpperCase()}][$component]';

    // Scrub any potential certificates or sensitive headers before printing
    final sanitized = _sanitize(message);

    if (kDebugMode) {
      debugPrint('$prefix $sanitized');
    }
  }

  static void info(String message, [String component = 'Remote']) =>
      log(message, level: LogLevel.info, component: component);

  static void warn(String message, [String component = 'Remote']) =>
      log(message, level: LogLevel.warning, component: component);

  static void error(String message, [String component = 'Remote']) =>
      log(message, level: LogLevel.error, component: component);

  static void debug(String message, [String component = 'Remote']) =>
      log(message, level: LogLevel.debug, component: component);

  static String _sanitize(String input) {
    var out = input;
    // Mask private keys or certificate blocks
    out = out.replaceAll(RegExp(r'-----BEGIN [A-Z ]+-----[^-]+-----END [A-Z ]+-----', multiLine: true), '[REDACTED_CERTIFICATE]');
    // Mask 6-digit PIN codes
    out = out.replaceAll(RegExp(r'(pairing|pin|code)[:=]\s*([a-zA-Z0-9]{4,8})', caseSensitive: false), r'$1: ******');
    return out;
  }
}
