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

  // الإعدادات الافتراضية
  double _baseFare = 300.0;
  double _perKmRate = 150.0;
  double _waitingRatePerMinute = 50.0;
  String _driverPhone = '+967700000000'; // رقم التواصل والواتساب

  Database? _database;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'taxi_shaheen.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE trips(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, distance REAL, fare REAL, duration INTEGER)',
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseFare = prefs.getDouble('baseFare') ?? 300.0;
      _perKmRate = prefs.getDouble('perKmRate') ?? 150.0;
      _waitingRatePerMinute = prefs.getDouble('waitingRate') ?? 50.0;
      _driverPhone = prefs.getString('driverPhone') ?? '+967700000000';
    });
  }

  Future<void> _saveTripToDB(double distance, double fare, int seconds) async {
    if (_database != null) {
      await _database!.insert(
        'trips',
        {
          'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          'distance': distance,
          'fare': fare,
          'duration': seconds,
        },
      );
    }
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
        _distanceKm += 0.005; // محاكاة المسافة
        _totalFare = _baseFare + (_distanceKm * _perKmRate) + ((_elapsedSeconds / 60) * _waitingRatePerMinute);
      });
    });
  }

  void _stopTrip() {
    _timer?.cancel();
    setState(() {
      _isTripActive = false;
    });
    _saveTripToDB(_distanceKm, _totalFare, _elapsedSeconds);
    _showTripSummaryDialog();
  }

  void _showTripSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ملخص الرحلة المحفوظة'),
        content: Column(
      mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المسافة: ${_distanceKm.toStringAsFixed(2)} كم'),
            Text('الوقت: ${(_elapsedSeconds / 60).toStringAsFixed(1)} دقيقة'),
            const Divider(),
            Text('الإجمالي: ${_totalFare.toStringAsFixed(1)} ريال',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('تم الحفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  void _openSettingsDialog() {
    Text_baseController = TextEditingController(text: _baseFare.toString());
    Text_kmController = TextEditingController(text: _perKmRate.toString());
    Text_waitController = TextEditingController(text: _waitingRatePerMinute.toString());
    Text_phoneController = TextEditingController(text: _driverPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إعدادات العداد والأسعار'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: Text_baseController, decoration: const InputDecoration(labelText: 'الفتح الأساسي (ريال)'), keyboardType: TextInputType.number),
              TextField(controller: Text_kmController, decoration: const InputDecoration(labelText: 'سعر الكيلومتر (ريال)'), keyboardType: TextInputType.number),
              TextField(controller: Text_waitController, decoration: const InputDecoration(labelText: 'سعر دقيقة الانتظار (ريال)'), keyboardType: TextInputType.number),
              TextField(controller: Text_phoneController, decoration: const InputDecoration(labelText: 'رقم واتساب واتصال السائق'), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                _baseFare = double.tryParse(Text_baseController.text) ?? 300.0;
                _perKmRate = double.tryParse(Text_kmController.text) ?? 150.0;
                _waitingRatePerMinute = double.tryParse(Text_waitController.text) ?? 50.0;
                _driverPhone = Text_phoneController.text;
              });
              await prefs.setDouble('baseFare', _baseFare);
              await prefs.setDouble('perKmRate', _perKmRate);
              await prefs.setDouble('waitingRate', _waitingRatePerMinute);
              await prefs.setString('driverPhone', _driverPhone);
              Navigator.pop(context);
            },
            child: const Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _openHistoryScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const TripHistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تكسي الشاهين - العداد الذكي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[800],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsDialog,
            tooltip: 'الإعدادات',
          ),
        ],
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
            const SizedBox(height: 16),
            // أزرار الاتصال والواتساب السريعة بحواف دائرية
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL('tel:$_driverPhone'),
                    icon: const Icon(Icons.phone),
                    label: const Text('اتصال بالطلب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL('https://wa.me/$_driverPhone?text=مرحباً، أريد طلب تكسي الشاهين'),
                    icon: const Icon(Icons.chat),
                    label: const Text('واتساب المشاوير'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // زر سجل الحسابات والأرباح بحواف دائرية
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openHistoryScreen,
                icon: const Icon(Icons.history, color: Colors.amber),
                label: const Text('سجل وحسابات الرحلات السابقة والأرباح', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.amber[800]!, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isTripActive ? _stopTrip : _startTrip,
                icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow, size: 28),
                label: Text(
                  _isTripActive ? 'إيقاف العداد وإنهاء الرحلة' : 'بدء الرحلة الجديدة',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTripActive ? Colors.red[700] : Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// شاشة سجل الرحلات والأرباح
class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<Map<String, dynamic>> _trips = [];
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    String path = p.join(await getDatabasesPath(), 'taxi_shaheen.db');
    final db = await openDatabase(path);
    final List<Map<String, dynamic>> maps = await db.query('trips', orderBy: 'id DESC');

    double sum = 0.0;
    for (var trip in maps) {
      sum += (trip['fare'] as num).toDouble();
    }

    setState(() {
      _trips = maps;
      _totalEarnings = sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المشاوير والأرباح'),
        backgroundColor: Colors.amber[800],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[800]!, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الأرباح المحفوظة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_totalEarnings.toStringAsFixed(1)} ريال', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber[900])),
              ],
            ),
          ),
          Expanded(
            child: _trips.isEmpty
                ? const Center(child: Text('لا توجد رحلات مسجلة حتى الآن'))
                : ListView.builder(
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text('الأجرة: ${trip['fare']} ريال', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('المسافة: ${trip['distance']} كم | الوقت: ${trip['duration']} ثانية'),
                          trailing: Text('${trip['date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// متغيرات مؤقتة لحقول الإعدادات
TextEditingController Text_baseController = TextEditingController();
TextEditingController Text_kmController = TextEditingController();
TextEditingController Text_waitController = TextEditingController();
TextEditingController Text_phoneController = TextEditingController();
