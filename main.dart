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
  double farePerKm = 1000.0;
  double totalFare = 500.0;
  double distanceKm = 0.00;
  int currentSpeed = 0;
  bool isTripActive = false;

  void _showSettingsDialog() {
    TextEditingController baseFareController =
        TextEditingController(text: baseFare.toStringAsFixed(0));
    TextEditingController farePerKmController =
        TextEditingController(text: farePerKm.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تعديل تسعيرة المشوار',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: baseFareController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر فتح الباب (ريال)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: farePerKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر الكيلومتر (ريال)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              setState(() {
                baseFare = double.tryParse(baseFareController.text) ?? baseFare;
                farePerKm = double.tryParse(farePerKmController.text) ?? farePerKm;
                if (!isTripActive && distanceKm == 0) {
                  totalFare = baseFare;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _toggleTrip() {
    setState(() {
      isTripActive = !isTripActive;
    });
  }

  void _resetTrip() {
    setState(() {
      isTripActive = false;
      distanceKm = 0.0;
      currentSpeed = 0;
      totalFare = baseFare;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text('الأجرة الإجمالية للمشوار',
                          style: TextStyle(fontSize: 15, color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(
                        totalFare.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'فتح الباب: ${baseFare.toStringAsFixed(0)} • السعر/كم: ${farePerKm.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المسافة المقطوعة',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('السرعة الحالية',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
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
                const SizedBox(height: 24),
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
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isTripActive ? Colors.orange : Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _resetTrip,
                      icon: const Icon(Icons.refresh, color: Colors.redAccent),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.all(14),
                      ),
                      tooltip: 'إعادة ضبط المشوار',
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
