# Equipify Mobile (Flutter)

تطبيق الجوال الرسمي لمنصة **Equipify** لتأجير المعدات — مبني على نفس الـ API
وبنفس لغة تصميم تطبيق الويب (أمبر على حبر داكن، بطاقات 20px، أزرار حبة دواء).

## المتطلبات

- Flutter SDK ≥ 3.9 (`fvm` مدعوم)
- خادم Equipify API يعمل على المنفذ `5000`

## التشغيل

```bash
flutter pub get

# محاكي Android (يصل للمضيف عبر 10.0.2.2 تلقائياً)
flutter run

# محاكي iOS (localhost يعمل مباشرة)
flutter run -d ios

# جهاز حقيقي على نفس الشبكة — مرّر عنوان مضيفك
flutter run --dart-define=API_URL=http://192.168.1.10:5000
```

## الحسابات التجريبية

| الدور | القيم |
|---|---|
| مستخدم | `0790666835` / `123456` |
| أدمن | تبويب "أدمن" في شاشة الدخول → `admin` / `Admin@12345` |
| OTP | `0000` (يُعرض أيضاً في الواجهة أثناء التطوير) |

## البنية

```
lib/
├── main.dart                  # Bootstrap + routing + providers
├── core/
│   ├── constants.dart         # API URL (dart-define) + helpers
│   ├── theme.dart             # EqColors / EqRadius / ThemeData فاتح وداكن
│   ├── api_client.dart        # Dio + Bearer + تجديد توكن أحادي الطيران
│   ├── app_state.dart         # AuthProvider · ThemeProvider · LocaleProvider
│   └── i18n.dart              # عربي/إنجليزي + SDelegate
├── models/models.dart         # نماذج مطابقة لعقود API 1:1
├── services/services.dart     # Auth · Category · Listing · Request · Admin
├── screens/                   # الرئيسية · الاستكشاف+الخريطة · التفاصيل · النموذج…
└── widgets/                   # بطاقة الإعلان · شريط الفئات · Skeletons · منتقي الخريطة
```

## أبرز التفاصيل التقنية

- **تجديد التوكن الشفاف**: أي 401 يطلق تحديثاً واحداً مشتركاً (single-flight)
  ثم يعيد إرسال الطلب الأصلي تلقائياً.
- **الخريطة**: `flutter_map` مع بطاقات أسعار بيضاء كدبابيس (أسلوب Airbnb)،
  وتحديث النتائج عند انتهاء كل حركة للخريطة، ومعاينة سفلية للإعلان.
- **نشر الإعلانات**: رفع متعدد الصور عبر `FormData` بأسماء الحقول المطابقة
  تماماً لعقد `ListingForm` في الـ API، مع منتقي موقع تفاعلي.
- **الحجز بـ OTP**: ورقة سفلية فيها اختيار تاريخ/وقت، حساب الإجمالي الحيّ،
  عدّاد تهدئة لإعادة الإرسال، وإدخال رمز بخط واسع.
- **RTL كامل**: عربي افتراضي مع قلب اتجاه فوري وترجمة كل النصوص.
