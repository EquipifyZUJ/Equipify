import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// Thrown when a request fails after any refresh attempt.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;

  /// Translates known English API errors to Arabic when the locale is Arabic.
  static String translateError(String msg, bool isArabic) {
    if (!isArabic) return msg;
    const map = {
      'Invalid phone number or password.': 'رقم الهاتف أو كلمة المرور غير صحيحة',
      'Invalid or expired verification code.': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
      'Session expired. Please sign in again.': 'انتهت الجلسة، سجّل الدخول مجدداً',
      'Connection error — is the API running?': 'خطأ في الاتصال بالخادم',
    };
    return map[msg] ?? msg;
  }

  static ApiException fromDio(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    String msg;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        msg = 'Connection timeout — check your network';
        break;
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        msg = 'No internet connection — is the server running?';
        break;
      case DioExceptionType.cancel:
        msg = 'Request cancelled';
        break;
      default:
        msg = 'Connection error — is the API running?';
    }

    if (data is Map) {
      msg = (data['error'] ??
              data['title'] ??
              data['detail'] ??
              (data['errors'] is Map
                  ? (data['errors'] as Map).values.first.toString()
                  : null) ??
              msg)
          .toString();
    } else if (data is String && data.isNotEmpty && code != 404) {
      if (data.contains('"error":"')) {
        final s = data.split('"error":"').last;
        msg = s.split('"').first;
      }
    }
    return ApiException(msg, statusCode: code);
  }
}

/// Single shared Dio client with:
///  • Bearer token attachment
///  • transparent refresh-token rotation on 401 (single-flight)
///  • JSON error normalisation into [ApiException]
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiUrl,
        connectTimeout: const Duration(seconds: kReleaseMode ? 60 : 12),
        receiveTimeout: const Duration(seconds: kReleaseMode ? 60 : 20),
        headers: {'Accept': 'application/json'},
        validateStatus: (_) => true, // handled manually below
      ),
    )..interceptors.add(InterceptorsWrapper(
        onRequest: _attachToken,
        onError: (e, handler) async {
          final res = await _maybeRefreshAndRetry(e);
          handler.resolve(res);
        },
      ));
  }

  static final ApiClient I = ApiClient._internal();
  late final Dio _dio;

  static const _accessKey = StorageKeys.accessToken;
  static const _refreshKey = StorageKeys.refreshToken;

  Future<String?> accessToken() async =>
      (await SharedPreferences.getInstance()).getString(_accessKey);

  Future<void> saveSession({
    required String? access,
    required String? refresh,
  }) async {
    final sp = await SharedPreferences.getInstance();
    if (access == null || refresh == null) {
      await sp.remove(_accessKey);
      await sp.remove(_refreshKey);
    } else {
      await sp.setString(_accessKey, access);
      await sp.setString(_refreshKey, refresh);
    }
    _refreshing = null; // allow new flights with the fresh token
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.startsWith('/auth/login') &&
        !options.path.startsWith('/auth/register') &&
        !options.path.startsWith('/auth/admin-login') &&
        !options.path.startsWith('/auth/refresh') &&
        !options.path.startsWith('/auth/send-otp') &&
        !options.path.startsWith('/auth/forgot-password') &&
        !options.path.startsWith('/auth/reset-password')) {
      final token = await accessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Completer<bool>? _refreshing;

  /// On 401 → try refreshing once. All concurrent failures wait on the same
  /// flight. Retries the original request with the new access token.
  Future<Response<dynamic>> _maybeRefreshAndRetry(DioException e) async {
    final res = e.response;
    final status = res?.statusCode ?? 0;
    if (status != 401 ||
        e.requestOptions.path.startsWith('/auth/refresh') ||
        e.requestOptions.path.startsWith('/auth/login') ||
        e.requestOptions.extra['retried'] == true) {
      throw e;
    }

    final ok = await _flight();
    if (!ok) throw e;

    final req = e.requestOptions;
    req.extra['retried'] = true;
    final token = await accessToken();
    req.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch(req);
  }

  /// Single-flight refresh shared by all concurrent 401s.
  Future<bool> _flight() {
    final existing = _refreshing;
    if (existing != null) return existing.future;

    final c = Completer<bool>();
    _refreshing = c;
    _doRefresh().then(c.complete, onError: c.completeError).whenComplete(() {
      _refreshing = null;
    });
    return c.future;
  }

  Future<bool> _doRefresh() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final refresh = sp.getString(_refreshKey);
      if (refresh == null) return false;

      final bare = Dio(BaseOptions(baseUrl: kApiUrl));
      final r = await bare.post('/api/auth/refresh', data: {
        'refreshToken': refresh,
      });
      if (r.statusCode != 200) return false;

      await saveSession(
        access: r.data['accessToken'] as String,
        refresh: r.data['refreshToken'] as String?,
      );
      return true;
    } catch (_) {
      await saveSession(access: null, refresh: null);
      return false;
    }
  }

  // ---- convenience verbs -------------------------------------------------
  Future<dynamic> get(String path, [Map<String, dynamic>? query]) async {
    final r = await _dio.get(path, queryParameters: query);
    return _unwrap(r);
  }

  Future<dynamic> post(String path, [Object? body]) async {
    final r = await _dio.post(path, data: body);
    return _unwrap(r);
  }

  Future<dynamic> put(String path, [Object? body]) async {
    final r = await _dio.put(path, data: body);
    return _unwrap(r);
  }

  Future<dynamic> delete(String path) async {
    final r = await _dio.delete(path);
    return _unwrap(r);
  }

  /// Multipart POST/PUT used by listing create/edit and admin category images.
  Future<dynamic> sendForm(
    String method,
    String path,
    FormData form,
  ) async {
    final r =
        await _dio.request(path, data: form, options: Options(method: method));
    return _unwrap(r);
  }

  dynamic _unwrap(Response r) {
    if ((r.statusCode ?? 500) >= 400) {
      throw ApiException.fromDio(
        DioException(requestOptions: r.requestOptions, response: r),
      );
    }
    if (r.statusCode == 204) return null;
    return r.data;
  }
}
