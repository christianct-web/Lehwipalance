// Add this to a utils file or at the top of your main.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static const bool _enableLogging = kDebugMode;

  static void log(String message) {
    if (_enableLogging) {
      debugPrint(message);
    }
  }

  static void error(String message) {
    if (_enableLogging) {
      debugPrint('❌ $message');
    }
  }

  static void success(String message) {
    if (_enableLogging) {
      debugPrint('✅ $message');
    }
  }

  static void info(String message) {
    if (_enableLogging) {
      debugPrint('ℹ️ $message');
    }
  }
}

// Then replace all debugPrint calls:
// From: debugPrint('Some message');
// To: AppLogger.info('Some message');
