import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'constants.dart';

/// Auth + session state for the whole app.
class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();

  User? user;
  bool ready = false;

  Future<void> bootstrap() async {
    try {
      // Skip network entirely if no stored tokens
      final sp = await SharedPreferences.getInstance();
      final hasToken = sp.getString(StorageKeys.accessToken)?.isNotEmpty == true;
      if (!hasToken) {
        ready = true;
        notifyListeners();
        return;
      }
      user = await _auth.restore();
    } catch (_) {
      user = null;
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> login(String phone, String password) =>
      _signIn(() => _auth.login(phone, password));

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String emailAddress,
    required String phoneNumber,
    required String password,
    required String otpCode,
  }) async {
    await _auth.register(
      firstName: firstName,
      lastName: lastName,
      emailAddress: emailAddress,
      phoneNumber: phoneNumber,
      password: password,
      otpCode: otpCode,
    );
    return true;
  }

  Future<void> refreshMe() async {
    user = await _auth.me();
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    notifyListeners();
  }

  Future<bool> _signIn(Future<AuthSession> Function() fn) async {
    final session = await fn();
    user = session.user ?? await _auth.me();
    notifyListeners();
    return true;
  }
}

/// Light/dark mode persisted across launches.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _mode = sp.getString(StorageKeys.themeMode) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void toggle() => set(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> set(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        StorageKeys.themeMode, m == ThemeMode.dark ? 'dark' : 'light');
  }
}

/// Arabic (default, RTL) ↔ English.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getString(StorageKeys.locale) == 'en') _locale = const Locale('en');
    notifyListeners();
  }

  Future<void> set(Locale l) async {
    _locale = l;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(StorageKeys.locale, l.languageCode);
  }

  void toggle() => set(isArabic ? const Locale('en') : const Locale('ar'));
}
