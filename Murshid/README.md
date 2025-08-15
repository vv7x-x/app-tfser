# مشروع مرشد (Murshid)

منظومة بلاغات مرئية فورية للمواطنين في مصر. يتيح التطبيق للمستخدم تصوير فيديو أو التقاط صورة عند مشاهدة جريمة أو فعل غير قانوني، ثم رفعها مباشرة إلى سيرفر حكومي (مثال تجريبي هنا) مع إرفاق الموقع الجغرافي ووقت البلاغ.

- تطبيق الموبايل: Flutter (Android و iOS)
- السيرفر: FastAPI (Python)

> تنبيه: هذا المستودع تعليمي وتجريبي. لا يحتوي على أي بيانات حكومية فعلية. عدِّل رابط السيرفر من `lib/config.dart` في تطبيق Flutter.


## هيكل المشروع

```
Murshid/
├─ mobile_app/
│  ├─ lib/
│  │  ├─ config.dart
│  │  ├─ main.dart
│  │  └─ screens/
│  │     ├─ home_screen.dart
│  │     └─ confirmation_screen.dart
│  │  └─ services/
│  │     └─ api_service.dart
│  └─ pubspec.yaml
│
└─ server/
   ├─ app/
   │  ├─ main.py
   │  ├─ config.py
   │  ├─ database.py
   │  ├─ models.py
   │  └─ schemas.py
   ├─ uploads/
   │  └─ .gitkeep
   └─ requirements.txt
```


## تشغيل السيرفر (FastAPI)

1) إنشاء بيئة عمل Python وتثبيت الاعتمادات:

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2) تشغيل السيرفر محليًا:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Endpoint رفع البلاغ: `POST /report`
- Endpoint استرجاع البلاغات: `GET /reports`
- الملفات تُحفَظ داخل `server/uploads/`
- قاعدة البيانات SQLite داخل `server/murshid.db`

> ملاحظة الحجم: تم ضبط التحقق لقبول ملفات حتى 100MB.


## إعداد وتشغيل تطبيق Flutter

1) المتطلبات: تثبيت Flutter SDK وAndroid Studio/Xcode.

2) تهيئة مشروع Flutter (إن لم تكن مجلدات المنصات موجودة):

```bash
cd mobile_app
flutter create .
flutter pub get
```

3) ضبط صلاحيات Android:
- الملف: `android/app/src/main/AndroidManifest.xml`
- أضِف ضمن `<manifest>` وقبل `<application>` صلاحيات الكاميرا والميكروفون والموقع:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

- ضمن `<application>` تأكد من وجود:
```xml
<application
    android:requestLegacyExternalStorage="true"
    ...>
</application>
```

4) ضبط صلاحيات iOS:
- الملف: `ios/Runner/Info.plist`

أضِف المفاتيح التالية بوصف عربي واضح:
```xml
<key>NSCameraUsageDescription</key>
<string>يحتاج التطبيق لاستخدام الكاميرا لتصوير البلاغ.</string>
<key>NSMicrophoneUsageDescription</key>
<string>يحتاج التطبيق لاستخدام الميكروفون لتسجيل الصوت مع الفيديو.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>يحتاج التطبيق للوصول إلى موقعك لإرساله مع البلاغ.</string>
```

5) تعديل رابط السيرفر:
- الملف: `lib/config.dart`
- عدِّل المتغير `serverBaseUrl` إلى عنوان السيرفر الحقيقي. عند استخدام Android Emulator استخدم: `http://10.0.2.2:8000`، وعلى جهاز حقيقي استخدم عنوان IP للسيرفر.

6) تشغيل التطبيق:

```bash
flutter run
```


## استخدام التطبيق

- من الشاشة الرئيسية اضغط "بدء البلاغ"، ثم اختر:
  - التقاط صورة
  - تسجيل فيديو
- سيطلب التطبيق صلاحيات الكاميرا والموقع (مرة واحدة).
- بعد الالتقاط، سيتم رفع الملف مع الإحداثيات ووقت البلاغ إلى السيرفر.
- ستظهر شاشة تأكيد بعد الإرسال، مع تنبيه نجاح/فشل عبر SnackBar.


## مواصفات تقنية موجزة

- تطبيق Flutter:
  - image_picker و geolocator و http
  - واجهة عربية واتجاه RTL
  - `config.dart` لتعديل رابط السيرفر بسهولة

- سيرفر FastAPI:
  - Endpoint `POST /report` يستقبل ملفًا (صورة/فيديو) + `latitude` + `longitude` + `reported_at`
  - حفظ الملف في `uploads/`، وتسجيل السجل في SQLite عبر SQLAlchemy
  - Endpoint `GET /reports` لإرجاع البلاغات (للاستخدام الحكومي)
  - تحقق من حجم الملف حتى 100MB


## ملاحظات أمنية (لبيئة الإنتاج)

- يُفضَّل تقييد CORS إلى نطاقات محددة بدل `*`.
- إضافة مصادقة/تفويض لـ `GET /reports`.
- رفع خلف Proxy آمن مع حدود حجم مناسبة.
- تشفير النقل عبر HTTPS دائمًا.