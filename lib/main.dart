import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
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
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', '')],
      locale: const Locale('ar', ''),
      home: const HomeScreen(),
    );
  }
}

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
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        startLocation TEXT,
        endLocation TEXT,
        distance REAL,
        waitingMinutes INTEGER,
        totalFare REAL,
        fuelCost REAL,
        netProfit REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        category TEXT,
        date TEXT,
        notes TEXT
      )
    ''');
  }

  Future<int> insertTrip(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trips', row);
  }

  Future<List<Map<String, dynamic>>> queryAllTrips() async {
    final db = await instance.database;
    return await db.query('trips', orderBy: 'id DESC');
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('expenses', row);
  }

  Future<List<Map<String, dynamic>>> queryAllExpenses() async {
    final db = await instance.database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const MeterScreen(),
    const TripsScreen(),
    const ExpensesScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_taxi), label: 'العداد'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الرحلات'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'المصاريف'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class MeterScreen extends StatefulWidget {
  const MeterScreen({super.key});

  @override
  State<MeterScreen> createState() => _MeterScreenState();
}

class _MeterScreenState extends State<MeterScreen> {
  bool _isTripActive = false;
  double _distanceKm = 0.0;
  int _waitingMinutes = 0;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;

  double baseFare = 500;
  double kmRate = 200;
  double minuteRate = 50;
  double fuelPrice = 1550;
  double fuelConsumption = 10;

  final TextEditingController _startLocController = TextEditingController(text: 'المنطقة الحالية');
  final TextEditingController _endLocController = TextEditingController(text: 'الوجهة');
  final TextEditingController _manualDistanceController = TextEditingController();
  final TextEditingController _manualWaitingController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      baseFare = prefs.getDouble('baseFare') ?? 500;
      kmRate = prefs.getDouble('kmRate') ?? 200;
      minuteRate = prefs.getDouble('minuteRate') ?? 50;
      fuelPrice = prefs.getDouble('fuelPrice') ?? 1550;
      fuelConsumption = prefs.getDouble('fuelConsumption') ?? 10;
    });
  }

  void _startTrip() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showManualInputDialog("أذونات الموقع مرفوضة. يجوز إدخال المسافة يدوياً.");
        return;
      }
    }

    setState(() {
      _isTripActive = true;
      _distanceKm = 0.0;
      _waitingMinutes = 0;
    });

    try {
      _lastPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) {
        if (_lastPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            _lastPosition!.latitude, _lastPosition!.longitude,
            position.latitude, position.longitude,
          );
          setState(() {
            _distanceKm += distanceInMeters / 1000.0;
            _lastPosition = position;
          });
        }
      });
    } catch (e) {
      _showManualInputDialog("تعذر تشغيل نظام GPS تلقائياً. أدخل المسافة يدوياً.");
    }
  }

  void _stopTrip() {
    _positionStream?.cancel();
    setState(() {
      _isTripActive = false;
    });
    _saveTripToDB();
  }

  double get _totalFare {
    int waitingMins = int.tryParse(_manualWaitingController.text) ?? _waitingMinutes;
    return baseFare + (_distanceKm * kmRate) + (waitingMins * minuteRate);
  }

  double get _estimatedFuelCost {
    return (_distanceKm * fuelConsumption / 100) * fuelPrice;
  }

  void _saveTripToDB() async {
    int waitingMins = int.tryParse(_manualWaitingController.text) ?? _waitingMinutes;
    double fare = _totalFare;
    double fCost = _estimatedFuelCost;
    double net = fare - fCost;

    await DatabaseHelper.instance.insertTrip({
      'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'startLocation': _startLocController.text,
      'endLocation': _endLocController.text,
      'distance': _distanceKm,
      'waitingMinutes': waitingMins,
      'totalFare': fare,
      'fuelCost': fCost,
      'netProfit': net,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الرحلة بنجاح في السجل!')),
    );
  }

  void _showManualInputDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال يدوي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            TextField(
              controller: _manualDistanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المسافة (كيلومتر)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _distanceKm = double.tryParse(_manualDistanceController.text) ?? 0.0;
                _isTripActive = true;
              });
              Navigator.pop(context);
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تكسي الشاهين - العداد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('إجمالي الأجرة المستحقة', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text('${_totalFare.toStringAsFixed(0)} ر.ي',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber[850])),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text('المسافة', style: TextStyle(color: Colors.grey)),
                          Text('${_distanceKm.toStringAsFixed(2)} كم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                        Column(children: [
                          const Text('الانتظار', style: TextStyle(color: Colors.grey)),
                          Text('$_waitingMinutes دقيقة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _startLocController,
              decoration: const InputDecoration(labelText: 'منطقة الانطلاق', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _endLocController,
              decoration: const InputDecoration(labelText: 'منطقة الوصول', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _manualWaitingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'دقائق الانتظار اليدوية', border: OutlineInputBorder()),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                    onPressed: _isTripActive ? null : _startTrip,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('بدء الرحلة', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                    onPressed: !_isTripActive ? null : _stopTrip,
                    icon: const Icon(Icons.stop),
                    label: const Text('إنهاء الرحلة', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final Uri launchUri = Uri(scheme: 'tel', path: '+967777521058');
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text('اتصال', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () async {
                    final Uri whatsappUri = Uri.parse('https://wa.me/967777521058');
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('واتساب', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() async {
    final data = await DatabaseHelper.instance.queryAllTrips();
    setState(() {
      _trips = data;
    });
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الرحلة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteTrip(id);
              Navigator.pop(context);
              _loadTrips();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الرحلات السابقة')),
      body: _trips.isEmpty
          ? const Center(child: Text('لا توجد رحلات مسجلة بعد'))
          : ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text('${trip['startLocation']} ➔ ${trip['endLocation']}'),
                    subtitle: Text('التاريخ: ${trip['date']}\nالمسافة: ${trip['distance'].toStringAsFixed(2)} كم | الأجرة: ${trip['totalFare']} ر.ي'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(trip['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _expenses = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _category = 'وقود';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final data = await DatabaseHelper.instance.queryAllExpenses();
    setState(() {
      _expenses = data;
    });
  }

  void _addExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مصروف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان المصروف (مثلاً: تغيير زيت)')),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (ريال يمني)')),
            DropdownButtonFormField<String>(
              value: _category,
              items: ['وقود', 'صيانة', 'غسيل', 'زيوت وإطارات', 'أخرى']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertExpense({
                  'title': _titleController.text,
                  'amount': double.tryParse(_amountController.text) ?? 0.0,
                  'category': _category,
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                });
                _titleController.clear();
                _amountController.clear();
                Navigator.pop(context);
                _loadExpenses();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مصاريف التشغيل')),
      body: _expenses.isEmpty
          ? const Center(child: Text('لا توجد مصاريف مسجلة'))
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return ListTile(
                  leading: const Icon(Icons.money_off, color: Colors.red),
                  title: Text(exp['title']),
                  subtitle: Text('النوع: ${exp['category']} | التاريخ: ${exp['date']}'),
                  trailing: Text('${exp['amount']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpenseDialog,
        backgroundColor: Colors.amber[800],
        child: const Icon(Icons.add),
      ),
    );
  }
}
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double totalRevenue = 0;
  double totalFuelCost = 0;
  double totalExpenses = 0;
  int tripCount = 0;

  @override
  void initState() {
    super.initState();
    _calculateReports();
  }

  void _calculateReports() async {
    final trips = await DatabaseHelper.instance.queryAllTrips();
    final expenses = await DatabaseHelper.instance.queryAllExpenses();

    double rev = 0;
    double fCost = 0;
    for (var t in trips) {
      rev += (t['totalFare'] as num).toDouble();
      fCost += (t['fuelCost'] as num).toDouble();
    }

    double exp = 0;
    for (var e in expenses) {
      exp += (e['amount'] as num).toDouble();
    }

    setState(() {
      totalRevenue = rev;
      totalFuelCost = fCost;
      totalExpenses = exp;
      tripCount = trips.length;
    });
  }

  void _shareReportText() {
    String report = 'تقرير تكسي الشاهين:\n'
        'عدد الرحلات: $tripCount\n'
        'إجمالي الإيرادات: $totalRevenue ر.ي\n'
        'تكلفة الوقود التقديرية: $totalFuelCost ر.ي\n'
        'إجمالي المصاريف: $totalExpenses ر.ي\n'
        'صافي الربح: ${totalRevenue - totalFuelCost - totalExpenses} ر.ي';
    Share.share(report);
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('تكسي الشاهين - تقرير الأرباح والمصاريف', style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('عدد الرحلات: $tripCount'),
            pw.Text('إجمالي الإيرادات: $totalRevenue ر.ي'),
            pw.Text('تكلفة الوقود التقديرية: $totalFuelCost ر.ي'),
            pw.Text('المصاريف المسجلة: $totalExpenses ر.ي'),
            pw.Divider(),
            pw.Text('صافي الربح التقديري: ${totalRevenue - totalFuelCost - totalExpenses} ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    double netProfit = totalRevenue - totalFuelCost - totalExpenses;
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير المالية والأرباح')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('إجمالي الإيرادات'),
                trailing: Text('$totalRevenue ر.ي', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('تكلفة الوقود التقديرية'),
                trailing: Text('$totalFuelCost ر.ي', style: const TextStyle(color: Colors.orange)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('إجمالي مصاريف التشغيل'),
                trailing: Text('$totalExpenses ر.ي', style: const TextStyle(color: Colors.red)),
              ),
            ),
            Card(
              color: Colors.amber[100],
              child: ListTile(
                title: const Text('صافي الربح النهائي', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('$netProfit ر.ي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber[900])),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _shareReportText,
              icon: const Icon(Icons.share),
              label: const Text('مشاركة التقرير كنص'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _generatePdfReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('طباعة / حفظ تقرير PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _baseFareController = TextEditingController();
  final TextEditingController _kmRateController = TextEditingController();
  final TextEditingController _minuteRateController = TextEditingController();
  final TextEditingController _fuelPriceController = TextEditingController();
  final TextEditingController _fuelConsumptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseFareController.text = (prefs.getDouble('baseFare') ?? 500).toString();
      _kmRateController.text = (prefs.getDouble('kmRate') ?? 200).toString();
      _minuteRateController.text = (prefs.getDouble('minuteRate') ?? 50).toString();
      _fuelPriceController.text = (prefs.getDouble('fuelPrice') ?? 1550).toString();
      _fuelConsumptionController.text = (prefs.getDouble('fuelConsumption') ?? 10).toString();
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('baseFare', double.parse(_baseFareController.text));
    await prefs.setDouble('kmRate', double.parse(_kmRateController.text));
    await prefs.setDouble('minuteRate', double.parse(_minuteRateController.text));
    await prefs.setDouble('fuelPrice', double.parse(_fuelPriceController.text));
    await prefs.setDouble('fuelConsumption', double.parse(_fuelConsumptionController.text));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات بنجاح!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العداد والوقود')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _baseFareController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أجرة بداية الرحلة (ر.ي)')),
          TextField(controller: _kmRateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أجرة الكيلومتر (ر.ي)')),
          TextField(controller: _minuteRateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أجرة دقيقة الانتظار (ر.ي)')),
          TextField(controller: _fuelPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر لتر الوقود (ر.ي)')),
          TextField(controller: _fuelConsumptionController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'استهلاك الوقود (لتر لكل 100 كم)')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
            child: const Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }
}
// بناء جديد
