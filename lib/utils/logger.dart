// lib/utils/logger.dart

import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      print('[WARNING] $message');
    }
  }
  
  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('  → $error');
      }
    }
    // TODO: En producción, enviar a Crashlytics o Sentry
  }
}