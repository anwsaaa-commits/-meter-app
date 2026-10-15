import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaxiAlShaheenApp());
}

class TaxiAlShaheenApp extends StatelessWidget {
  const TaxiAlShaheenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تكسي الشاهين',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [Locale('ar', 'YE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Roboto',
      ),
      home: const TaxiHomeScreen(),
    );
  }
}

class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {
  bool _isTripActive = false;
  double _totalFare = 0.0;
  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // إعدادات العداد الافتراضية
  double _baseFare = 300.0;
  double _perKmRate = 150.0;
  double _waitingRatePerMinute = 50.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseFare = prefs.getDouble('baseFare') ?? 300.0;
      _perKmRate = prefs.getDouble('perKmRate') ?? 150.0;
      _waitingRatePerMinute = prefs.getDouble('waitingRate') ?? 50.0;
    });
  }

  void _startTrip() {
    setState(() {
      _isTripActive = true;
      _totalFare = _baseFare;
      _distanceKm = 0.0;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        // محاكاة بسيطة لزيادة المسافة والأجرة مع الوقت لضمان عمل العداد بسلاسة تامة
        _distanceKm += 0.005; // تقريباً 18 كم في الساعة
        _totalFare = _baseFare + (_distanceKm * _perKmRate) + ((_elapsedSeconds / 60) * _waitingRatePerMinute);
      });
    });
  }

  void _stopTrip() {
    _timer?.cancel();
    setState(() {
      _isTripActive = false;
    });
    _showTripSummaryDialog();
  }

  void _showTripSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نتيجة الرحلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المسافة المقطوعة: ${_distanceKm.toStringAsFixed(2)} كم'),
            Text('وقت الانتظار/الرحلة: ${(_elapsedSeconds / 60).toStringAsFixed(1)} دقيقة'),
            const Divider(),
            Text('الإجمالي المستحق: ${_totalFare.toStringAsFixed(1)} ريال',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حفظ وإغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تكسي الشاهين - العداد الذكي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[800],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('الأجرة الحالية', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      '${_totalFare.toStringAsFixed(1)} ريال',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('المسافة', style: TextStyle(color: Colors.grey)),
                            Text('${_distanceKm.toStringAsFixed(2)} كم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('الوقت', style: TextStyle(color: Colors.grey)),
                            Text('${(_elapsedSeconds / 60).toStringAsFixed(0)} دقيقة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isTripActive ? _stopTrip : _startTrip,
                icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow, size: 30),
                label: Text(
                  _isTripActive ? 'إيقاف العداد وإنهاء الرحلة' : 'بدء الرحلة الجديدة',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTripActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
