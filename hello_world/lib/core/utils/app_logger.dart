import 'package:flutter/foundation.dart';

/// A centralized logging utility to handle app-wide logging.
/// This allows us to easily disable/re-route logs in production.
class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('📘 [INFO]: $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARN]: $message');
    }
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR]: $message');
      if (error != null) debugPrint('Error Detail: $error');
      if (stackTrace != null) debugPrint('Stack Trace: $stackTrace');
    }
    // In production, we could send these to Sentry or Firebase Crashlytics
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [SUCCESS]: $message');
    }
  }
}
