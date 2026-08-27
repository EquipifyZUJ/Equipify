/// Global configuration for the Equipify mobile client.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode;

/// Resolves the Equipify API base URL.
///
/// Release builds connect to the production server by default.
/// Override from the CLI:
///   flutter run --dart-define=API_URL=http://192.168.1.10:5000
final String kApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: _defaultApiUrl,
);

final String _defaultApiUrl = kReleaseMode
    ? 'https://equipifyapi.onrender.com'
    : (kIsAndroidEmulator ? 'http://10.0.2.2:5000' : 'http://localhost:5000');

final bool kIsAndroidEmulator = !kReleaseMode && Platform.isAndroid;

/// Absolute URL for a relative image path returned by the API
/// (e.g. "/uploads/listings/x.jpg" → "http://host/uploads/listings/x.jpg").
String imageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '$kApiUrl$path';
}

abstract final class StorageKeys {
  static const accessToken = 'equipify.access_token';
  static const refreshToken = 'equipify.refresh_token';
  static const locale = 'equipify.locale';
  static const themeMode = 'equipify.theme_mode';
}

/// Fixed development OTP shown in the API logs / echoed by the dev endpoint.
const String kDevOtpHint = '0000';
