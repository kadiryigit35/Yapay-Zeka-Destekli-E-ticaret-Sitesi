// lib/config/api_config.dart
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://192.168.1.105:44366';
    } else {
      return 'https://localhost:44366';
    }
  }
}