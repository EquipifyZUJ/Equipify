import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../services/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();

  bool otpSent = false;
  String? devCode;
  bool busy = false;
  String? error;
  bool obscure = true;
  bool otpBusy = false;

  String _translateError(String raw) {
    final isAr = S.of(context).isAr;
    const map = {
      'Invalid or expired verification code.':
          {'ar': 'رمز التحقق غير صحيح أو منتهي الصلاحية', 'en': 'Invalid or expired verification code.'},
      'Connection error — is the API running?':
          {'ar': 'خطأ في الاتصال بالخادم', 'en': 'Connection error'},
      'No internet connection — is the server running?':
          {'ar': 'لا يوجد اتصال بالإنترنت — تأكد من تشغيل الخادم', 'en': 'No internet connection — is the server running?'},
      'Connection timeout — check your network':
          {'ar': 'انتهت مهلة الاتصال — تحقق من شبكتك', 'en': 'Connection timeout — check your network'},
      'The Name field is required.':
          {'ar': 'جميع الحقول مطلوبة', 'en': 'All fields are required.'},
      'The FirstName field is required.':
          {'ar': 'الاسم الأول مطلوب', 'en': 'First name is required.'},
      'The LastName field is required.':
          {'ar': 'اسم العائلة مطلوب', 'en': 'Last name is required.'},
      'The EmailAddress field is required.':
          {'ar': 'البريد الإلكتروني مطلوب', 'en': 'Email is required.'},
      'The PhoneNumber field is required.':
          {'ar': 'رقم الهاتف مطلوب', 'en': 'Phone number is required.'},
      'The Password field is required.':
          {'ar': 'كلمة المرور مطلوبة', 'en': 'Password is required.'},
    };
    if (map.containsKey(raw)) return map[raw]![isAr ? 'ar' : 'en']!;
    return raw;
  }

  Future<void> _sendOtp() async {
    final s = S.of(context);
    if (_phone.text.trim().isEmpty) {
      setState(() => error = s.t('error.phoneEmpty'));
      return;
    }
    setState(() { error = null; otpBusy = true; });
    try {
      final code = await _authSvc.sendOtp(_phone.text.trim());
      if (mounted) setState(() { otpSent = true; devCode = code; otpBusy = false; });
    } catch (e) {
      if (mounted) setState(() { error = _translateError('$e'); otpBusy = false; });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final s = S.of(context);
    if (!otpSent) {
      setState(() => error = s.t('auth.otpRequired'));
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await context.read<AuthProvider>().register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            emailAddress: _email.text,
            phoneNumber: _phone.text,
            password: _password.text,
            otpCode: _otp.text,
          );

      // Auto-login after successful registration
      if (!mounted) return;
      try {
        await context.read<AuthProvider>().login(_phone.text, _password.text);
      } catch (_) {
        // Registration succeeded but auto-login failed — go to login screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.t('auth.registrationSuccess')),
              backgroundColor: EqColors.ok,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
    } catch (e) {
      if (mounted) setState(() { error = _translateError('$e'); busy = false; });
      return;
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(Icons.language_rounded, size: 22, color: Theme.of(context).colorScheme.onSurface),
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
                  autovalidateMode: AutovalidateMode.disabled,
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
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(s.t('auth.registerSub'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),],
                          decoration:
                          InputDecoration(labelText: s.t('auth.firstName'), hintTextDirection: TextDirection.ltr),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? s.t('error.firstNameEmpty')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),],
                          decoration:
                          InputDecoration(labelText: s.t('auth.lastName'), hintTextDirection: TextDirection.ltr),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? s.t('error.lastNameEmpty')
                          : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-]')),],
                  decoration: InputDecoration(labelText: s.t('auth.email'), hintTextDirection: TextDirection.ltr),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return s.t('error.emailInvalid');
                    return v.contains('@') ? null : s.t('error.emailInvalid');
                  },
                ),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                        labelText: s.t('auth.phone'),
                        hintText: '07XXXXXXXX',
                        hintTextDirection: TextDirection.ltr,
                      ),
                      validator: (v) => v != null &&
                              RegExp(r'^07[7-9]\d{7}$').hasMatch(v.trim())
                          ? null
                          : s.t('error.phoneInvalid'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton(
                      onPressed: busy || otpSent ? null : _sendOtp,
                      style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
                      child: otpBusy
                          ? const SizedBox(
                              height: 16, width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(s.t('auth.sendOtp')),
                    ),
                  ),
                ]),

                if (otpSent) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EqColors.ok.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(EqRadius.field),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: EqColors.ok),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${s.t('auth.otpSent')} ${devCode != null ? '($devCode)' : ''}',
                            style: const TextStyle(
                                color: EqColors.ok, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: s.t('auth.otpLabel'),
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    validator: (v) =>
                        v != null && v.length >= 4 ? null : s.t('error.otpShort'),
                  ),
                ],

                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9!@#\$%^&*.]')),],
                  onFieldSubmitted: (_) => _submit(),
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.t('error.passwordEmpty');
                    return v.length >= 8 ? null : s.t('error.passwordShort');
                  },
                ),

                if (error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EqColors.bad.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(EqRadius.field),
                      border: Border.all(color: EqColors.bad.withValues(alpha: 0.4)),
                    ),
                    child: Text(error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: EqColors.bad, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 22),

                FilledButton(
                  onPressed: busy || !otpSent ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(s.t('nav.register')),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.t('auth.haveAccount'),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        s.t('nav.login'),
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

AuthService get _authSvc => AuthService();
