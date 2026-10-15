import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

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

  // الإعدادات والرقم ورابط الواتساب الخاص بـ أبو شاهين
  double _baseFare = 300.0;
  double _perKmRate = 150.0;
  double _waitingRatePerMinute = 50.0;
  String _driverPhone = '+967777521058';
  String _whatsappUrl = 'https://wa.me/qr/5MVL3DGBOKSQI1';

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
      _driverPhone = prefs.getString('driverPhone') ?? '+967777521058';
      _whatsappUrl = prefs.getString('whatsappUrl') ?? 'https://wa.me/qr/5MVL3DGBOKSQI1';
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
            Text('المسافة المقطوعة: ${_distanceKm.toStringAsFixed(2)} كم'),
            Text('وقت الرحلة: ${(_elapsedSeconds / 60).toStringAsFixed(1)} دقيقة'),
            const Divider(),
            Text('إجمالي المستحق: ${_totalFare.toStringAsFixed(1)} ريال',
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

  // الاتصال المباشر
  Future<void> _makePhoneCall() async {
    final Uri url = Uri(scheme: 'tel', path: _driverPhone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // فتح رابط الواتساب المباشر
  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse(_whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openSettingsDialog() {
    TextEditingController baseController = TextEditingController(text: _baseFare.toString());
    TextEditingController kmController = TextEditingController(text: _perKmRate.toString());
    TextEditingController waitController = TextEditingController(text: _waitingRatePerMinute.toString());
    TextEditingController phoneController = TextEditingController(text: _driverPhone);
    TextEditingController waController = TextEditingController(text: _whatsappUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إعدادات العداد والاتصال'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: baseController, decoration: const InputDecoration(labelText: 'سعر الفتح الأساسي (ريال)'), keyboardType: TextInputType.number),
              TextField(controller: kmController, decoration: const InputDecoration(labelText: 'سعر الكيلومتر (ريال)'), keyboardType: TextInputType.number),
              TextField(controller: waitController, decoration: const InputDecoration(labelText: 'سعر دقيقة الانتظار (ريال)'), keyboardType: TextInputType.number),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الاتصال المباشر'), keyboardType: TextInputType.phone),
              TextField(controller: waController, decoration: const InputDecoration(labelText: 'رابط الواتساب المباشر')),
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
                _baseFare = double.tryParse(baseController.text) ?? 300.0;
                _perKmRate = double.tryParse(kmController.text) ?? 150.0;
                _waitingRatePerMinute = double.tryParse(waitController.text) ?? 50.0;
                _driverPhone = phoneController.text;
                _whatsappUrl = waController.text;
              });
              await prefs.setDouble('baseFare', _baseFare);
              await prefs.setDouble('perKmRate', _perKmRate);
              await prefs.setDouble('waitingRate', _waitingRatePerMinute);
              await prefs.setString('driverPhone', _driverPhone);
              await prefs.setString('whatsappUrl', _whatsappUrl);
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

            // أزرار الواتساب والاتصال التلقائي
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone),
                    label: const Text('اتصال مباشر'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('واتساب مباشر'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // زر سجل المشاوير والأرباح
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openHistoryScreen,
                icon: const Icon(Icons.history, color: Colors.amber),
                label: const Text('سجل الرحلات السابقة والأرباح', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.amber[800]!, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Spacer(),

            // زر تشغيل وإيقاف العداد
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
