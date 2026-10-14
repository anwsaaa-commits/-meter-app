import 'dart:async';
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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
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
  // --- متغيرات التسعيرة ---
  double baseFare = 500.0;       // فتح الباب
  double farePerKm = 1000.0;     // سعر الكيلو
  double farePerMinute = 100.0;  // سعر دقيقة الانتظار

  // --- متغيرات العداد والمشوار ---
  double totalFare = 500.0;
  double distanceKm = 0.00;
  int currentSpeed = 0;
  int waitingSeconds = 0;
  bool isTripActive = false;

  Timer? _tripTimer;

  // --- متغيرات حاسبة أرباح الوقود ---
  double fuelPricePerLiter = 1200.0;
  double kmPerLiter = 10.0;
  double dailyRevenue = 0.0;

  void _toggleTrip() {
    setState(() {
      isTripActive = !isTripActive;
    });

    if (isTripActive) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isTripActive) return;

      setState(() {
        currentSpeed = 40;
        distanceKm += (currentSpeed / 3600);
        waitingSeconds++;

        totalFare = baseFare + (distanceKm * farePerKm) + ((waitingSeconds / 60) * farePerMinute);
      });
    });
  }

  void _stopTimer() {
    _tripTimer?.cancel();
    setState(() {
      currentSpeed = 0;
    });
  }

  void _resetTrip() {
    _stopTimer();
    setState(() {
      isTripActive = false;
      distanceKm = 0.0;
      currentSpeed = 0;
      waitingSeconds = 0;
      totalFare = baseFare;
    });
  }

  // 🟢 دالة التحويل المباشر للواتساب برقمك الخاص
  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse("https://wa.me/967777521058?text=مرحباً%20كابتن%20أبو%20شاهين،%20أرغب%20بحجز%20مشوار.");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("خطأ في فتح الواتساب: $e");
    }
  }

  // 📊 شاشة حاسبة الأرباح واستهلاك الوقود الخاصة بك
  void _showProfitAndFuelCalculator() {
    TextEditingController fuelPriceCtrl = TextEditingController(text: fuelPricePerLiter.toStringAsFixed(0));
    TextEditingController kmPerLiterCtrl = TextEditingController(text: kmPerLiter.toStringAsFixed(1));
    TextEditingController revenueCtrl = TextEditingController(text: dailyRevenue.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulWidget(
          builder: (context, setModalState) {
            double totalKmDriven = distanceKm; 
            double fuelUsedLiters = totalKmDriven > 0 ? (totalKmDriven / kmPerLiter) : 0.0;
            double fuelCost = fuelUsedLiters * fuelPricePerLiter;
            double currentRevenue = dailyRevenue > 0 ? dailyRevenue : totalFare;
            double netProfit = currentRevenue - fuelCost;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📊 كشف الأرباح واستهلاك الوقود',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fuelPriceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'سعر اللتر (ريال)',
                              labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                fuelPricePerLiter = double.tryParse(val) ?? fuelPricePerLiter;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: kmPerLiterCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'استهلاك (كم/لتر)',
                              labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                kmPerLiter = double.tryParse(val) ?? kmPerLiter;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: revenueCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'إجمالي الدخل اليومي (ريال)',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 13),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          dailyRevenue = double.tryParse(val) ?? dailyRevenue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _buildReportRow('المسافة المحسوبة:', '${totalKmDriven.toStringAsFixed(2)} كم', Colors.white70),
                          const SizedBox(height: 8),
                          _buildReportRow('الوقود المستهلك:', '${fuelUsedLiters.toStringAsFixed(2)} لتر', Colors.orangeAccent),
                          const SizedBox(height: 8),
                          _buildReportRow('تكلفة الوقود:', '${fuelCost.toStringAsFixed(0)} ريال', Colors.redAccent),
                          const Divider(color: Colors.white24, height: 20),
                          _buildReportRow('صافي الأرباح:', '${netProfit.toStringAsFixed(0)} ريال', Colors.greenAccent, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportRow(String title, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.white70, fontSize: isBold ? 15 : 13)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ⚙️ نافذة الإعدادات
  void _showSettingsDialog() {
    TextEditingController baseController = TextEditingController(text: baseFare.toStringAsFixed(0));
    TextEditingController kmController = TextEditingController(text: farePerKm.toStringAsFixed(0));
    TextEditingController minController = TextEditingController(text: farePerMinute.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعدادات التسعيرة والتقرير',
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showProfitAndFuelCalculator();
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('كشف أرباح واستهلاك الوقود الخاص بك'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            child: const Text('حفظ والتحديث', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
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
                        'عداد التاكسي - أبو شاهين',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.amber, size: 26),
                        onPressed: _showSettingsDialog,
                        tooltip: 'الإعدادات والتقرير',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // شاشة الأجرة الرئيسية
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.amber.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'أجرة المشوار الإجمالية',
                        style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            totalFare.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ريال',
                            style: TextStyle(fontSize: 18, color: Colors.amberAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // بطاقات المسافة والسرعة الحالية
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.map_outlined, color: Colors.tealAccent, size: 18),
                                SizedBox(width: 6),
                                Text('المسافة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${distanceKm.toStringAsFixed(2)} كم',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.speed, color: Colors.tealAccent, size: 18),
                                SizedBox(width: 6),
                                Text('السرعة الحالية', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$currentSpeed كم/س',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // زر حجز عبر واتساب المباشر على الواجهة
                ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    'طلب مشوار عبر واتساب (الشاهين)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // أزرار التحكم بالمشوار (بدء/إيقاف وإعادة الضبط)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleTrip,
                        icon: Icon(
                          isTripActive ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: Text(
                          isTripActive ? 'إيقاف مؤقت' : 'بدء المشوار',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTripActive ? Colors.orange.shade700 : Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        onPressed: _resetTrip,
                        icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 28),
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
