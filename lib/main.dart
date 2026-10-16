import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_map_screen.dart';
import 'phone_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة فايربيس ببيانات مشروعك الحقيقية والخاصة بالتطبيق
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBxp1Oib1-G2ZFZ4PJWNtFfwNWKsvPqJHk",
      appId: "1:52073323980:android:ec07f04523c0a22b0fd169",
      messagingSenderId: "52073323980",
      projectId: "taxi-al-shaheen",
      storageBucket: "taxi-al-shaheen.firebasestorage.app",
    ),
  );

  runApp(const TaxiAlShaheenApp());
}

class TaxiAlShaheenApp extends StatelessWidget {
  const TaxiAlShaheenApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Al Shaheen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
      ),
      // الشاشة الرئيسية للتطبيق (الخريطة وطلب المشوار)
      home: const HomeMapScreen(),
    );
  }
}
