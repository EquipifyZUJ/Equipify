import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool busy = false;
  String? error;
  bool obscure = true;

  String _translateError(String raw) {
    final isAr = S.of(context).isAr;
    const map = {
      'Invalid phone number or password.':
          {'ar': 'رقم الهاتف أو كلمة المرور غير صحيحة', 'en': 'Invalid phone number or password.'},
      'Connection error — is the API running?':
          {'ar': 'خطأ في الاتصال بالخادم', 'en': 'Connection error'},
      'No internet connection — is the server running?':
          {'ar': 'لا يوجد اتصال بالإنترنت — تأكد من تشغيل الخادم', 'en': 'No internet connection — is the server running?'},
      'Connection timeout — check your network':
          {'ar': 'انتهت مهلة الاتصال — تحقق من شبكتك', 'en': 'Connection timeout — check your network'},
    };
    if (map.containsKey(raw)) return map[raw]![isAr ? 'ar' : 'en']!;
    return raw;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      await context.read<AuthProvider>().login(_phone.text, _password.text);
    } catch (e) {
      if (mounted) setState(() { error = _translateError('$e'); busy = false; });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = context.watch<LocaleProvider>();
    final isAr = locale.isArabic;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Language toggle — top corner ──
            PositionedDirectional(
              top: 12,
              end: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(Icons.language_rounded, size: 22, color: cs.onSurface),
                  tooltip: isAr ? 'English' : 'العربية',
                  onPressed: () => locale.toggle(),
                ),
              ),
            ),

            // ── Main content ──
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo centered ──
                      Center(
                        child: Image(
                          image: AssetImage(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'img/logo_dark.png'
                                : 'img/logo_light.png',
                          ),
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.t('auth.loginSub'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.outline, fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EqColors.bad.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(EqRadius.field),
                      border: Border.all(color: EqColors.bad.withValues(alpha: 0.4)),
                    ),
                    child: Text(error!,
                        style: const TextStyle(
                            color: EqColors.bad, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: s.t('auth.phone'),
                    prefixIcon: const Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? s.t('error.phoneEmpty') : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _password,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9!@#\$%^&*.]')),],
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: s.t('auth.password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? s.t('error.passwordEmpty') : null,
                ),
                const SizedBox(height: 22),

                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(s.t('nav.login')),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.t('auth.noAccount'),
                      style: TextStyle(color: cs.outline, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text(
                        s.t('nav.register'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }
}
