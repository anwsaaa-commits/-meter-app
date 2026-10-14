import 'dart:async';
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
      title: 'عداد التاكسي - أبو شاهين',
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
  double baseFare = 500.0;
  double farePerKm = 450.0; // السعر المعدل
  double farePerMinute = 100.0;

  double totalFare = 500.0;
  double distanceKm = 0.00;
  int currentSpeed = 0;
  int waitingSeconds = 0;
  bool isTripActive = false;
  Timer? _tripTimer;

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

  // نافذة التواصل المباشر المعدلة بدون أي خروج عن الحواف
  void _openWhatsAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.chat, color: Colors.greenAccent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'حجز مشوار - الشاهين',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'للحجز والتواصل المباشر مع الكابتن أبو شاهين عبر الواتساب أو الاتصال:',
              style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // زر الاتصال المباشر
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // فتح رقم الاتصال المباشر
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رقم الكابتن أبو شاهين: 967777521058+')),
                );
              },
              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
              label: const Text(
                'اتصال: 967777521058+',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),

            // زر الواتساب المباشر
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رابط الواتساب: wa.me/967777521058')),
                );
              },
              icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
              label: const Text(
                'واتساب مباشر',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

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
        return StatefulBuilder(
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
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '📊 كشف الأرباح واستهلاك الوقود',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'سعر اللتر (ريال)', labelStyle: TextStyle(fontSize: 11)),
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
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'استهلاك (كم/لتر)', labelStyle: TextStyle(fontSize: 11)),
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
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'إجمالي الدخل اليومي (ريال)', labelStyle: TextStyle(fontSize: 12)),
                      onChanged: (val) {
                        setModalState(() {
                          dailyRevenue = double.tryParse(val) ?? dailyRevenue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
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
        Text(title, style: TextStyle(color: Colors.white70, fontSize: isBold ? 14 : 12)),
        Text(value, style: TextStyle(color: color, fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  void _showSettingsDialog() {
    TextEditingController baseController = TextEditingController(text: baseFare.toStringAsFixed(0));
    TextEditingController kmController = TextEditingController(text: farePerKm.toStringAsFixed(0));
    TextEditingController minController = TextEditingController(text: farePerMinute.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعدادات التسعيرة والتقرير', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: baseController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر فتح الباب (ريال)')),
              const SizedBox(height: 10),
              TextField(controller: kmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الكيلومتر (ريال)')),
              const SizedBox(height: 10),
              TextField(controller: minController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر دقيقة الانتظار (ريال)')),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 45)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              setState(() {
                baseFare = double.tryParse(baseController.text) ?? baseFare;
                farePerKm = double.tryParse(kmController.text) ?? farePerKm;
                farePerMinute = double.tryParse(minController.text) ?? farePerMinute;
                if (!isTripActive && distanceKm == 0) totalFare = baseFare;
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'عداد التاكسي - أبو شاهين',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.settings, color: Colors.amber, size: 26), onPressed: _showSettingsDialog),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.amber.shade400, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text('أجرة المشوار الإجمالية', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 10),
                      Text('${totalFare.toStringAsFixed(0)} ريال', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المسافة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text('${distanceKm.toStringAsFixed(2)} كم', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('السرعة الحالية', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text('$currentSpeed كم/س', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openWhatsAppDialog,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('طلب مشوار عبر واتساب (الشاهين)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleTrip,
                        icon: Icon(isTripActive ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        label: Text(isTripActive ? 'إيقاف مؤقت' : 'بدء المشوار', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTripActive ? Colors.orange.shade700 : Colors.teal.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                      child: IconButton(
                        onPressed: _resetTrip,
                        icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 28),
                        padding: const EdgeInsets.all(14),
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
