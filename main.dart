import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('أيقونة التاكسي'),
        ),
        body: Center(
          child: Image.network(
            'https://icon2.cleanpng.com/20180419/qwe/avsfile-taxi-computer-icons-emoticon-taxi-logos-5ad88df4615a63.8505560915241425803988.jpg',
            width: 100,
            height: 100,
            // هذه الخاصية تتعامل مع أخطاء التحميل لو انقطع الإنترنت مؤقتاً
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_taxi, size: 80, color: Colors.orange);
            },
          ),
        ),
      ),
    );
  }
}
