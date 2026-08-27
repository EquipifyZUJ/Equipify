import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_state.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.I.init();
  runApp(const EquipifyApp());
}

class EquipifyApp extends StatelessWidget {
  const EquipifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, locale, _) {
          return MaterialApp(
            title: 'Equipify',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: EqTheme.light(),
            darkTheme: EqTheme.dark(),
            locale: locale.locale,
            supportedLocales: S.supportedLocales,
            localizationsDelegates: const [
              SDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routes: {
              '/': (_) => const _Bootstrap(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}

/// Waits for the stored session to be validated, then routes to the shell
/// or the login screen. Reacts to auth state changes (login/logout).
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    if (!auth.ready) {
      return Directionality(
        textDirection: locale.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: Center(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                  image: AssetImage(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'img/logo_dark.png'
                        : 'img/logo_light.png',
                  ),
                  width: 180,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final signedIn = auth.user != null;
    return signedIn
        ? const RootShell()
        : const LoginScreen();
  }
}


