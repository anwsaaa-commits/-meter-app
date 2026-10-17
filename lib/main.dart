import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_map_screen.dart';
import 'phone_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBxp10iWl-G2ZF24PJWNtFfWNwKsvPqJhk",
      appId: "1:52073323980:android:ec07f04523c0a22b0fd169",
      messagingSenderId: "52073323980",
      projectId: "taxi-al-shaheen",
      storageBucket: "taxi-al-shaheen.appspot.com",
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
      home: const HomeMapScreen(),
    );
  }
}
