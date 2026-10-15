import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
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
        scaffoldBackgroundColor: const Color(0xF1F5F9),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MeterScreen(),
    TripsHistoryScreen(),
    ExpenseScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[900],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'العداد'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الرحلات'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'المصاريف'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// ==================== الشاشة الرئيسية (العداد) ====================
class MeterScreen extends StatefulWidget {
  const MeterScreen({super.key});

  @override
  State<MeterScreen> createState() => _MeterScreenState();
}

class _MeterScreenState extends State<MeterScreen> {
  bool _isTripActive = false;
  double _distanceKm = 0.0;
  int _waitingMinutes = 0;
  Timer? _waitingTimer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  // الإعدادات
  double _baseFare = 500.0;
  double _kmRate = 200.0;
  double _waitingRate = 50.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseFare = prefs.getDouble('baseFare') ?? 500.0;
      _kmRate = prefs.getDouble('kmRate') ?? 200.0;
      _waitingRate = prefs.getDouble('waitingRate') ?? 50.0;
    });
  }

  double get _totalFare => _baseFare + (_distanceKm * _kmRate) + (_waitingMinutes * _waitingRate);

  void _startTrip() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showManualDialog('خدمة الموقع مغلقة. يُرجى تفعيل GPS أو إدخال الكيلومترات يدوياً.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showManualDialog('تم رفض إذن الموقع. ادخل الكيلومترات يدوياً.');
        return;
      }
    }

    setState(() {
      _isTripActive = true;
      _distanceKm = 0.0;
      _waitingMinutes = 0;
      _lastPosition = null;
    });

    _waitingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isTripActive) {
        setState(() => _waitingMinutes++);
      }
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (_lastPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        setState(() {
          _distanceKm += distanceInMeters / 1000.0;
        });
      }
      _lastPosition = position;
    });
  }

  void _stopTrip() async {
    _waitingTimer?.cancel();
    _positionStream?.cancel();

    final db = await DatabaseHelper.instance.database;
    await db.insert('trips', {
      'date': DateTime.now().toIso8601String(),
      'distance': _distanceKm,
      'waitingTime': _waitingMinutes,
      'totalFare': _totalFare,
    });

    setState(() => _isTripActive = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الرحلة بنجاح: ${_totalFare.toStringAsFixed(0)} ر.ي')),
      );
    }
  }

  void _showManualDialog(String message) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الموقع غير متاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المسافة المقطوعة (كم)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              double dist = double.tryParse(controller.text) ?? 0.0;
              setState(() {
                _distanceKm = dist;
                _isTripActive = false;
              });
              Navigator.pop(ctx);
              _stopTrip();
            },
            child: const Text('حفظ الرحلة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تكسي الشاهين - العداد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              color: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const Text('الأجرة الإجمالية', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      '${_totalFare.toStringAsFixed(0)} ر.ي',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 42, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _infoCard('المسافة', '${_distanceKm.toStringAsFixed(2)} كم', Icons.add_road)),
                const SizedBox(width: 10),
                Expanded(child: _infoCard('الانتظار', '$_waitingMinutes دقيقة', Icons.timer)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTripActive ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow, size: 30, color: Colors.white),
                label: Text(
                  _isTripActive ? 'إنهاء الرحلة' : 'بدء الرحلة',
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: _isTripActive ? _stopTrip : _startTrip,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber[800]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==================== باقي الشاشات وقاعدة البيانات ====================
class TripsHistoryScreen extends StatelessWidget {
  const TripsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الرحلات'), backgroundColor: Colors.amber),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getTrips(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final trips = snapshot.data!;
          if (trips.isEmpty) return const Center(child: Text('لا توجد رحلات مسجلة'));

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (ctx, i) {
              final trip = trips[i];
              return ListTile(
                leading: const Icon(Icons.local_taxi, color: Colors.amber),
                title: Text('${trip['totalFare']} ر.ي'),
                subtitle: Text('المسافة: ${trip['distance']} كم | الانتظار: ${trip['waitingTime']} دقيقة'),
                trailing: Text(DateFormat('yyyy/MM/dd').format(DateTime.parse(trip['date']))),
              );
            },
          );
        },
      ),
    );
  }
}

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  void _addExpense() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    await db.insert('expenses', {
      'date': DateTime.now().toIso8601String(),
      'title': _titleController.text,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
    });
    _amountController.clear();
    _titleController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المصاريف'), backgroundColor: Colors.amber),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'بند المصروف (بترول، صيانة...)')),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (ر.ي)')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addExpense, child: const Text('حفظ المصروف')),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.getExpenses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final expenses = snapshot.data!;
                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(expenses[i]['title']),
                      subtitle: Text('${expenses[i]['amount']} ر.ي'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والأرباح'), backgroundColor: Colors.amber),
      body: const Center(child: Text('قسم التقارير جاهز لتلخيص الأرباح والمصاريف')),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseFareController = TextEditingController();
  final _kmRateController = TextEditingController();
  final _waitingRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseFareController.text = (prefs.getDouble('baseFare') ?? 500.0).toString();
    _kmRateController.text = (prefs.getDouble('kmRate') ?? 200.0).toString();
    _waitingRateController.text = (prefs.getDouble('waitingRate') ?? 50.0).toString();
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('baseFare', double.tryParse(_baseFareController.text) ?? 500.0);
    await prefs.setDouble('kmRate', double.tryParse(_kmRateController.text) ?? 200.0);
    await prefs.setDouble('waitingRate', double.tryParse(_waitingRateController.text) ?? 50.0);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
  }

  void _callSupport() async {
    final Uri url = Uri.parse('tel:+967777521058');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), backgroundColor: Colors.amber),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _baseFareController, decoration: const InputDecoration(labelText: 'فتح العداد (ر.ي)')),
            TextField(controller: _kmRateController, decoration: const InputDecoration(labelText: 'سعر الكيلومتر (ر.ي)')),
            TextField(controller: _waitingRateController, decoration: const InputDecoration(labelText: 'سعر دقيقة الانتظار (ر.ي)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('حفظ التعديلات')),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('تواصل معنا / الدعم الفني'),
              subtitle: const Text('+967 777 521 058'),
              onTap: _callSupport,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper لفتح وقراءة قاعدة البيانات
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('taxi_shaheen.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        distance REAL,
        waitingTime INTEGER,
        totalFare REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        title TEXT,
        amount REAL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await instance.database;
    return await db.query('trips', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    return await db.query('expenses', orderBy: 'id DESC');
  }
}
