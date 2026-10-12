# عداد التاكسي الذكي - تطبيق فلاتر باللغة العربية (Flutter Taxi Meter)

تطبيق متكامل لاحتساب أجرة التاكسي بدقة عبر نظام تحديد المواقع العالمي (GPS) مع زر وقت الانتظار والتوقف في الازدحام المروري، وتخزين كامل لسجل المشاوير في قاعدة بيانات محلية SQLite.

## المميزات الرئيسية:
- **تتبع المسافة بدقة GPS**: باستخدام حزمة `geolocator: ^13.0.1` وحساب المسافة بدقة عالية بين الإحداثيات.
- **حساب الأجرة الديناميكي**: رسوم فتح الباب + سعر الكيلومتر + سعر دقيقة الانتظار والتوقف في الزحمة.
- **زر إيقاف مؤقت / انتظار**: لحساب تكلفة الدقائق أثناء انتظار الراكب أو التوقف في الإشارات.
- **قاعدة بيانات محلية SQLite**: تخزين سجل الرحلات والأرباح محلياً عبر `sqflite` مع استعلامات حساب الإجمالي.
- **واجهة مستخدم احترافية باللغة العربية (RTL)** تدعم مختلف العملات والأجهزة.

## طريقة التشغيل:

1. فك ضغط المشروع وافتح المجلد:
```bash
unzip smart_taxi_meter.zip
cd smart_taxi_meter
```

2. تثبيت الحزم:
```bash
flutter pub get
```

3. تفعيل أذونات الموقع:
- **Android (`android/app/src/main/AndroidManifest.xml`)**:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
- **iOS (`ios/Runner/Info.plist`)**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>يحتاج التطبيق لإذن تحديد الموقع لحساب مسافة المشوار بدقة.</string>
```

4. التشغيل:
```bash
flutter run
```
