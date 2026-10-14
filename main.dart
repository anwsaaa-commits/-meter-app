import 'package:flutter/material.dart';

void main() {
  runApp(const TaxiMeterApp());
}

class TaxiMeterApp extends StatelessWidget {
  const TaxiMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عداد التاكسي الذكي',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10172A),
        primarySwatch: Colors.blue,
      ),
      home: const TaxiHomePage(),
    );
  }
}

class TaxiHomePage extends StatefulWidget {
  const TaxiHomePage({super.key});

  @override
  State<TaxiHomePage> createState() => _TaxiHomePageState();
}

class _TaxiHomePageState extends State<TaxiHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان العلوي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('عداد التاكسي الذكي - أبو شاهين',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Icon(Icons.local_taxi, color: Colors.amber, size: 28),
                  ],
                ),
                const SizedBox(height: 20),

                // شاشة الأجرة الرئيسية
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: const [
                      Text('الأجرة الإجمالية للمشوار',
                          style: TextStyle(fontSize: 16, color: Colors.white70)),
                      SizedBox(height: 10),
                      Text('501',
                          style: TextStyle(
                              fontSize: 55,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber)),
                      SizedBox(height: 5),
                      Text('فتح الباب: 500 • السعر/كم: 1000',
                          style: TextStyle(fontSize: 14, color: Colors.white60)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // معلومات الرحلة (المسافة والسرعة)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('المسافة المقطوعة',
                                style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 8),
                            Text('0.00 كم',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('السرعة الحالية',
                                style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 8),
                            Text('0 كم/س',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // زر حجز المشوار عبر واتساب المباشر
                ElevatedButton.icon(
                  onPressed: () {
                    // رابط الواتساب برقمك الخاص والرسالة الجاهزة
                    // ملاحظة: في بيئة الويب أو التطبيق الحقيقي سيفتح المحادثة مباشرة
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    'احجز مشوارك عبر واتساب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // زر بدء المشوار
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'بدء المشوار',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
