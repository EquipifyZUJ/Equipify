/// Minimal i18n — Arabic (default) & English, mirroring the web dictionary.
library;

import 'package:flutter/material.dart';

class S {
  S(this.locale);

  final Locale locale;

  static S of(BuildContext context) => Localizations.of<S>(context, S)!;

  static const supportedLocales = [Locale('ar'), Locale('en')];

  bool get isAr => locale.languageCode == 'ar';

  String t(String key, [Map<String, String>? vars]) {
    var text = _dict[key]?[isAr ? 'ar' : 'en'] ?? key;
    if (vars != null) {
      for (final e in vars.entries) {
        text = text.replaceAll('{${e.key}}', e.value);
      }
    }
    return text;
  }

  static const _dict = <String, Map<String, String>>{
    // ── General ──
    'app.name': {'ar': 'Equipify', 'en': 'Equipify'},
    'common.retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'common.cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'common.save': {'ar': 'حفظ', 'en': 'Save'},
    'common.delete': {'ar': 'حذف', 'en': 'Delete'},
    'common.edit': {'ar': 'تعديل', 'en': 'Edit'},
    'common.confirm': {'ar': 'تأكيد', 'en': 'Confirm'},
    'common.loading': {'ar': 'جارٍ التحميل…', 'en': 'Loading…'},
    'common.error': {'ar': 'حدث خطأ ما', 'en': 'Something went wrong'},
    'common.search': {'ar': 'ابحث عن معدات…', 'en': 'Search equipment…'},
    'common.jod': {'ar': 'د.أ', 'en': 'JOD'},
    'common.perDay': {'ar': '/ يوم', 'en': '/ day'},
    'common.perHour': {'ar': '/ ساعة', 'en': '/ hour'},
    'common.perWeek': {'ar': '/ أسبوع', 'en': '/ week'},
    'common.perMonth': {'ar': '/ شهر', 'en': '/ month'},
    'common.back': {'ar': 'رجوع', 'en': 'Back'},
    'common.connectionError': {'ar': 'خطأ في الاتصال بالخادم', 'en': 'Connection error'},
    'error.noInternet': {'ar': 'لا يوجد اتصال بالإنترنت', 'en': 'No internet connection'},
    'error.serverUnavailable': {'ar': 'الخادم غير متاح', 'en': 'Server unavailable'},


    // ── Nav ──
    'nav.home': {'ar': 'الرئيسية', 'en': 'Home'},
    'nav.browse': {'ar': 'استكشاف', 'en': 'Browse'},
    'nav.myListings': {'ar': 'إعلاناتي', 'en': 'My Listings'},
    'nav.requests': {'ar': 'طلباتي', 'en': 'Requests'},
    'nav.incoming': {'ar': 'الواردة', 'en': 'Incoming'},
    'nav.profile': {'ar': 'حسابي', 'en': 'Profile'},
    'nav.admin': {'ar': 'الإدارة', 'en': 'Admin'},
    'nav.login': {'ar': 'دخول', 'en': 'Login'},
    'nav.register': {'ar': 'تسجيل', 'en': 'Register'},

    // ── Auth ──
    'auth.loginTitle': {'ar': 'مرحباً بعودتك 👋', 'en': 'Welcome back 👋'},
    'auth.loginSub': {
      'ar': 'سجّل الدخول للمتابعة إلى Equipify',
      'en': 'Sign in to continue to Equipify'
    },
    'auth.registerTitle': {'ar': 'أنشئ حسابك', 'en': 'Create account'},
    'auth.registerSub': {
      'ar': 'انضم لآلاف المستأجرين والمُلّاك',
      'en': 'Join thousands of renters & owners'
    },
    'auth.phone': {'ar': 'رقم الهاتف', 'en': 'Phone number'},
    'auth.password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'auth.firstName': {'ar': 'الاسم الأول', 'en': 'First name'},
    'auth.lastName': {'ar': 'اسم العائلة', 'en': 'Last name'},
    'auth.email': {'ar': 'البريد الإلكتروني', 'en': 'Email address'},
    'auth.username': {'ar': 'اسم المستخدم', 'en': 'Username'},
    'auth.otpSent': {
      'ar': 'أرسلنا رمز تحقق إلى رقمك (تجريبي: 0000)',
      'en': 'We sent a code to your phone (dev: 0000)'
    },
    'auth.otpLabel': {'ar': 'رمز التحقق', 'en': 'Verification code'},
    'auth.sendOtp': {'ar': 'إرسال الرمز', 'en': 'Send code'},
    'auth.noAccount': {'ar': 'ليس لديك حساب؟', 'en': "Don't have an account?"},
    'auth.haveAccount': {'ar': 'لديك حساب؟', 'en': 'Already have an account?'},
    'auth.adminTab': {'ar': 'أدمن', 'en': 'Admin'},
    'auth.userTab': {'ar': 'مستخدم', 'en': 'User'},
    'auth.forgot': {'ar': 'نسيت كلمة المرور؟', 'en': 'Forgot password?'},
    'auth.otpRequired': {'ar': 'أدخل رمز التحقق أولاً', 'en': 'Enter the code first'},
    'auth.phoneRequired': {'ar': 'أدخل رقم الهاتف أولاً', 'en': 'Enter phone number first'},
    'auth.registrationSuccess': {
      'ar': 'تم إنشاء الحساب بنجاح! سجّل دخولك الآن',
      'en': 'Account created! Please sign in'
    },
    'auth.mustAgree': {
      'ar': 'يجب الموافقة على الشروط والأحكام',
      'en': 'You must agree to the terms'
    },
    'auth.termsLink': {'ar': 'الشروط', 'en': 'terms'},
    'auth.emailExists': {'ar': 'البريد الإلكتروني مسجّل مسبقاً', 'en': 'Email already exists'},
    'auth.phoneExists': {'ar': 'رقم الهاتف مسجّل مسبقاً', 'en': 'Phone already exists'},
    'auth.continue': {'ar': 'متابعة', 'en': 'Continue'},
    'auth.resetPassword': {'ar': 'إعادة تعيين كلمة المرور', 'en': 'Reset password'},
    'auth.resetSub': {'ar': 'أدخل رقم هاتفك واستلم رمز التحقق', 'en': 'Enter your phone to receive a code'},
    'auth.newPassword': {'ar': 'كلمة المرور الجديدة', 'en': 'New password'},
    'auth.reviews': {'ar': 'التقييمات', 'en': 'Reviews'},
    'auth.noReviews': {'ar': 'لا توجد تقييمات بعد', 'en': 'No reviews yet'},


    // ── API error translations ──
    'api.invalidCredentials': {
      'ar': 'رقم الهاتف أو كلمة المرور غير صحيحة',
      'en': 'Invalid phone number or password.'
    },
    'api.invalidOtp': {
      'ar': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
      'en': 'Invalid or expired verification code.'
    },
    'api.fieldRequired': {
      'ar': 'هذا الحقل مطلوب',
      'en': 'This field is required.'
    },
    'api.serverError': {
      'ar': 'خطأ في الخادم، حاول مرة أخرى',
      'en': 'Server error, please try again.'
    },
    'api.sessionExpired': {
      'ar': 'انتهت الجلسة، سجّل الدخول مجدداً',
      'en': 'Session expired. Please sign in again.'
    },

    // ── Validation errors ──
    'error.phoneEmpty': {'ar': 'أدخل رقم الهاتف', 'en': 'Enter your phone number'},
    'error.phoneInvalid': {
      'ar': 'رقم الهاتف غير صحيح (يبدأ بـ 077/078/079)',
      'en': 'Invalid phone number'
    },
    'error.passwordEmpty': {'ar': 'أدخل كلمة المرور', 'en': 'Enter your password'},
    'error.passwordShort': {
      'ar': 'كلمة المرور قصيرة (8 أحرف على الأقل)',
      'en': 'Min 8 characters'
    },
    'error.firstNameEmpty': {'ar': 'أدخل الاسم الأول', 'en': 'Enter first name'},
    'error.lastNameEmpty': {'ar': 'أدخل اسم العائلة', 'en': 'Enter last name'},
    'error.emailInvalid': {'ar': 'البريد الإلكتروني غير صحيح', 'en': 'Invalid email'},
    'error.otpEmpty': {'ar': 'أدخل رمز التحقق', 'en': 'Enter verification code'},
    'error.otpShort': {
      'ar': 'رمز التحقق يجب أن يكون 4 أرقام على الأقل',
      'en': 'Min 4 digits'
    },


    // ── Home ──
    'home.heroTitle': {'ar': 'كرّ أي معدات\nمن حولك بسهولة', 'en': 'Rent any equipment\naround you, easily'},
    'home.heroSub': {
      'ar': 'معدات بناء، حواسيب، أدوات رياضية وأكثر — من أشخاص في منطقتك',
      'en': 'Construction gear, computers, sports tools and more — from people nearby'
    },
    'home.categories': {'ar': 'التصنيفات', 'en': 'Categories'},
    'home.featured': {'ar': 'الأحدث للإيجار', 'en': 'Newly listed for rent'},
    'home.seeAll': {'ar': 'عرض الكل', 'en': 'See all'},
    'home.cta': {'ar': 'ابحث', 'en': 'Search'},

    // ── Browse ──
    'browse.title': {'ar': 'استكشف المعدات', 'en': 'Explore equipment'},
    'browse.grid': {'ar': 'شبكة', 'en': 'Grid'},
    'browse.mapView': {'ar': 'خريطة', 'en': 'Map'},
    'browse.allCategories': {'ar': 'كل التصنيفات', 'en': 'All categories'},
    'browse.minPrice': {'ar': 'أقل سعر', 'en': 'Min price'},
    'browse.maxPrice': {'ar': 'أعلى سعر', 'en': 'Max price'},
    'browse.rentalUnit': {'ar': 'وحدة الإيجار', 'en': 'Rental unit'},
    'browse.allUnits': {'ar': 'كل الوحدات', 'en': 'All units'},
    'browse.unitHour': {'ar': 'بالساعة', 'en': 'Per hour'},
    'browse.unitDay': {'ar': 'بيوم', 'en': 'Per day'},
    'browse.unitWeek': {'ar': 'بأسبوع', 'en': 'Per week'},
    'browse.unitMonth': {'ar': 'بشهر', 'en': 'Per month'},
    'browse.unitYear': {'ar': 'بسنة', 'en': 'Per year'},
    'browse.unitHourSingular': {'ar': 'ساعة', 'en': 'hour'},
    'browse.unitDaySingular': {'ar': 'يوم', 'en': 'day'},
    'browse.unitWeekSingular': {'ar': 'أسبوع', 'en': 'week'},
    'browse.unitMonthSingular': {'ar': 'شهر', 'en': 'month'},
    'browse.unitYearSingular': {'ar': 'سنة', 'en': 'year'},
    'browse.duration': {'ar': 'المدة', 'en': 'Duration'},
    'browse.minDuration': {'ar': 'أقل {unit}', 'en': 'Min {unit}'},
    'browse.maxDuration': {'ar': 'أعلى {unit}', 'en': 'Max {unit}'},
    'browse.filters': {'ar': 'الفلاتر', 'en': 'Filters'},
    'browse.applyFilters': {'ar': 'تطبيق', 'en': 'Apply'},
    'browse.resetFilters': {'ar': 'إعادة تعيين', 'en': 'Reset'},
    'browse.results': {'ar': 'نتيجة', 'en': 'results'},
    'browse.empty': {'ar': 'لا نتائج مطابقة', 'en': 'No matching results'},

    // ── Listing ──
    'listing.about': {'ar': 'عن هذه المعدة', 'en': 'About this item'},
    'listing.location': {'ar': 'الموقع', 'en': 'Location'},
    'listing.owner': {'ar': 'المالك', 'en': 'Owner'},
    'listing.bookNow': {'ar': 'اطلب الحجز', 'en': 'Request booking'},
    'listing.from': {'ar': 'من', 'en': 'From'},
    'listing.to': {'ar': 'إلى', 'en': 'To'},
    'listing.timeFrom': {'ar': 'وقت البدء', 'en': 'Start time'},
    'listing.timeTo': {'ar': 'وقت الانتهاء', 'en': 'End time'},
    'listing.total': {'ar': 'الإجمالي التقديري', 'en': 'Estimated total'},
    'listing.days': {'ar': 'يوم', 'en': 'days'},
    'listing.unavailable': {'ar': 'غير متاح حالياً', 'en': 'Currently unavailable'},
    'listing.contactOwner': {'ar': 'اتصل بالمالك', 'en': 'Call owner'},

    // ── Requests / OTP ──
    'otp.title': {'ar': 'تأكيد الحجز', 'en': 'Confirm booking'},
    'otp.sent': {
      'ar': 'أدخل رمز التحقق المرسل إلى هاتفك',
      'en': 'Enter the code sent to your phone'
    },
    'otp.devCode': {'ar': 'رمز التجربة', 'en': 'Dev code'},
    'otp.resendIn': {'ar': 'إعادة الإرسال بعد', 'en': 'Resend in'},
    'otp.seconds': {'ar': 'ث', 'en': 's'},
    'requests.mine': {'ar': 'طلباتي', 'en': 'My requests'},
    'requests.incoming': {'ar': 'الطلبات الواردة', 'en': 'Incoming requests'},
    'requests.none': {'ar': 'لا توجد طلبات بعد', 'en': 'No requests yet'},
    'requests.accept': {'ar': 'قبول', 'en': 'Accept'},
    'requests.reject': {'ar': 'رفض', 'en': 'Reject'},
    'requests.rate': {'ar': 'قيّم', 'en': 'Rate'},
    'requests.rated': {'ar': 'تم التقييم', 'en': 'Rated'},
    'status.Pending': {'ar': 'قيد الانتظار', 'en': 'Pending'},
    'status.Accepted': {'ar': 'مقبول', 'en': 'Accepted'},
    'status.Rejected': {'ar': 'مرفوض', 'en': 'Rejected'},
    'status.Active': {'ar': 'نشط', 'en': 'Active'},
    'status.Inactive': {'ar': 'غير نشط', 'en': 'Inactive'},

    // ── My listings / form ──
    'mylistings.title': {'ar': 'إعلاناتي', 'en': 'My listings'},
    'mylistings.new': {'ar': 'إعلان جديد', 'en': 'New listing'},
    'mylistings.none': {
      'ar': 'لم تنشر أي إعلان بعد',
      'en': "You haven't posted anything yet"
    },
    'mylistings.activate': {'ar': 'تفعيل', 'en': 'Activate'},
    'mylistings.deactivate': {'ar': 'تعطيل', 'en': 'Deactivate'},
    'form.title': {'ar': 'عنوان الإعلان', 'en': 'Listing title'},
    'form.description': {'ar': 'الوصف', 'en': 'Description'},
    'form.category': {'ar': 'التصنيف', 'en': 'Category'},
    'form.address': {'ar': 'الموقع (المدينة/المنطقة)', 'en': 'Location (city/area)'},
    'form.priceDay': {'ar': 'سعر اليوم', 'en': 'Price per day'},
    'form.priceHour': {'ar': 'سعر الساعة (اختياري)', 'en': 'Price per hour (optional)'},
    'form.priceWeek': {'ar': 'سعر الأسبوع (اختياري)', 'en': 'Price per week (optional)'},
    'form.priceMonth': {'ar': 'سعر الشهر (اختياري)', 'en': 'Price per month (optional)'},
    'form.priceYear': {'ar': 'سعر السنة', 'en': 'Price per year'},
    'form.minDays': {'ar': 'أقل مدة (أيام)', 'en': 'Min rental days'},
    'form.maxDays': {'ar': 'أقصى مدة (أيام)', 'en': 'Max rental days'},
    'form.images': {'ar': 'الصور', 'en': 'Photos'},
    'form.addImages': {'ar': 'إضافة صور', 'en': 'Add photos'},
    'form.pickLocation': {'ar': 'حدد الموقع على الخريطة', 'en': 'Pick location on map'},
    'form.submit': {'ar': 'نشر الإعلان', 'en': 'Publish listing'},
    'form.updateSubmit': {'ar': 'حفظ التعديلات', 'en': 'Save changes'},
    'form.pendingNote': {
      'ar': 'سيخضع الإعلان لمراجعة الإدارة قبل الظهور.',
      'en': 'Listings are reviewed by admins before going live.'
    },

    // ── Profile ──
    'profile.title': {'ar': 'حسابي', 'en': 'Profile'},
    'profile.changePassword': {'ar': 'تغيير كلمة المرور', 'en': 'Change password'},
    'profile.currentPassword': {'ar': 'كلمة المرور الحالية', 'en': 'Current password'},
    'profile.newPassword': {'ar': 'كلمة المرور الجديدة', 'en': 'New password'},
    'profile.logout': {'ar': 'تسجيل الخروج', 'en': 'Log out'},
    'profile.darkMode': {'ar': 'الوضع الليلي', 'en': 'Dark mode'},
    'profile.language': {'ar': 'اللغة', 'en': 'Language'},
    'profile.memberSince': {'ar': 'عضو منذ', 'en': 'Member since'},

    // ── Admin ──
    'admin.dashboard': {'ar': 'اللوحة', 'en': 'Dashboard'},
    'admin.listings': {'ar': 'الإعلانات', 'en': 'Listings'},
    'admin.users': {'ar': 'المستخدمون', 'en': 'Users'},
    'admin.categories': {'ar': 'الفئات', 'en': 'Categories'},
    'admin.approve': {'ar': 'موافقة', 'en': 'Approve'},
    'admin.deactivate': {'ar': 'تعطيل', 'en': 'Deactivate'},
    'admin.blocked': {'ar': 'محظور', 'en': 'Blocked'},
    'admin.active': {'ar': 'نشط', 'en': 'Active'},
    'admin.stat.users': {'ar': 'مستخدمون', 'en': 'Users'},
    'admin.stat.listings': {'ar': 'إعلانات', 'en': 'Listings'},
    'admin.stat.active': {'ar': 'نشطة', 'en': 'Active'},
    'admin.stat.pending': {'ar': 'بانتظار المراجعة', 'en': 'Pending'},
    'admin.stat.requests': {'ar': 'طلبات', 'en': 'Requests'},
  };
}

/// LocalizationsDelegate exposing [S] to the widget tree.
class SDelegate extends LocalizationsDelegate<S> {
  const SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => Future.value(S(locale));

  @override
  bool shouldReload(SDelegate old) => false;
}
