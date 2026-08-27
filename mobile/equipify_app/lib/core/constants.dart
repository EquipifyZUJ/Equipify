/// Global configuration for the Equipify mobile client.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode;

/// Resolves the Equipify API base URL.
///
/// Production URL is always used for release builds.
/// Debug builds default to local dev server.
final String kApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: _resolveUrl(),
);

String _resolveUrl() {
  // Release builds always use production
  if (kReleaseMode) return 'https://equipifyapi.onrender.com';
  // Debug: local dev server
  if (Platform.isAndroid) return 'http://10.0.2.2:5000';
  return 'http://localhost:5000';
}

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
