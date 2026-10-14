import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TaxiMeterApp());
}

class TaxiMeterApp extends StatelessWidget {
  const TaxiMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عداد التاكسي الذكي - أبو شاهين',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10172A),
        primarySwatch: Colors.amber,
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
  // متغيرات التسعيرة
  double baseFare = 500.0;       // فتح الباب
  double farePerKm = 1000.0;     // سعر الكيلو
  double farePerMinute = 100.0;  // سعر دقيقة الانتظار

  // متغيرات المشوار والعداد
  double totalFare = 500.0;
  double distanceKm = 0.00;
  int currentSpeed = 0;
  bool isTripActive = false;

  // فتح الواتساب الخاص بك
  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/967777521058?text=مرحباً%20كابتن%20أبو%20شاهين،%20أرغب%20بحجز%20مشوار.");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("خطأ في فتح الواتساب: $e");
    }
  }

  // بدء / إيقاف العداد
  void _toggleTrip() {
    setState(() {
      isTripActive = !isTripActive;
    });
  }

  // إعادة ضبط المشوار
  void _resetTrip() {
    setState(() {
      isTripActive = false;
      distanceKm = 0.0;
      currentSpeed = 0;
      totalFare = baseFare;
    });
  }

  // نافذة الإعدادات لتعديل التسعيرة الكاملة
  void _showSettingsDialog() {
    TextEditingController baseController =
        TextEditingController(text: baseFare.toStringAsFixed(0));
    TextEditingController kmController =
        TextEditingController(text: farePerKm.toStringAsFixed(0));
    TextEditingController minController =
        TextEditingController(text: farePerMinute.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل تسعيرة المشوار',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baseController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'سعر فتح الباب (ريال)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kmController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'سعر الكيلومتر (ريال)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'سعر دقيقة الانتظار (ريال)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                baseFare = double.tryParse(baseController.text) ?? baseFare;
                farePerKm = double.tryParse(kmController.text) ?? farePerKm;
                farePerMinute = double.tryParse(minController.text) ?? farePerMinute;
                if (!isTripActive && distanceKm == 0) {
                  totalFare = baseFare;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الشريط العلوي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'عداد التاكسي الذكي - أبو شاهين',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.amber, size: 26),
                      onPressed: _showSettingsDialog,
                      tooltip: 'تعديل الأسعار',
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // شاشة الأجرة الرئيسية
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text('الأجرة الإجمالية للمشوار',
                          style: TextStyle(fontSize: 15, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        totalFare.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'فتح الباب: ${baseFare.toStringAsFixed(0)} • كم: ${farePerKm.toStringAsFixed(0)} • دقيقة: ${farePerMinute.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقات المسافة والسرعة
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المسافة المقطوعة',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              '${distanceKm.toStringAsFixed(2)} كم',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent),
                            ),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('السرعة الحالية',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              '$currentSpeed كم/س',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // زر حجز المشوار عبر واتساب المباشر
                ElevatedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    'حجز مشوار عبر واتساب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // أزرار التحكم بالمشوار (بدء/إيقاف وإعادة ضبط)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleTrip,
                        icon: Icon(
                            isTripActive ? Icons.pause : Icons.play_arrow,
                            color: Colors.white),
                        label: Text(
                          isTripActive ? 'إيقاف مؤقت' : 'بدء المشوار',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTripActive ? Colors.orange : Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        onPressed: _resetTrip,
                        icon: const Icon(Icons.refresh, color: Colors.redAccent),
                        padding: const EdgeInsets.all(14),
                        tooltip: 'إعادة ضبط المشوار',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
