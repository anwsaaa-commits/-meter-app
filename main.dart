import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaxiApp());
}

class TripModel {
  final int? id;
  final double distanceKm;
  final double fare;
  final int durationSeconds;
  final String date;

  TripModel({
    this.id,
    required this.distanceKm,
    required this.fare,
    required this.durationSeconds,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'distanceKm': distanceKm,
      'fare': fare,
      'durationSeconds': durationSeconds,
      'date': date,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'],
      distanceKm: (map['distanceKm'] as num).toDouble(),
      fare: (map['fare'] as num).toDouble(),
      durationSeconds: map['durationSeconds'] as int,
      date: map['date'] as String,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('taxi_trips.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            distanceKm REAL,
            fare REAL,
            durationSeconds INTEGER,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertTrip(TripModel trip) async {
    final db = await instance.database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<TripModel>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'id DESC');
    return result.map((json) => TripModel.fromMap(json)).toList();
  }

  Future<void> deleteTrip(int id) async {
    final db = await instance.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('trips');
  }
}
class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عداد التاكسي الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const TaxiMeterScreen(),
    );
  }
}

class TaxiMeterScreen extends StatefulWidget {
  const TaxiMeterScreen({super.key});

  @override
  State<TaxiMeterScreen> createState() => _TaxiMeterScreenState();
}

class _TaxiMeterScreenState extends State<TaxiMeterScreen> {
  double baseFare = 500.0;
  double ratePerKm = 1000.0;
  double ratePerMinuteWait = 50.0;

  bool isTripActive = false;
  bool isPaused = false;
  double totalDistanceInMeters = 0.0;
  double totalFare = 0.0;
  int elapsedSeconds = 0;
  int pausedSeconds = 0;
  double currentSpeed = 0.0;

  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  Timer? _timer;

  void _openSettingsDialog() {
    TextEditingController baseController = TextEditingController(text: baseFare.toStringAsFixed(0));
    TextEditingController rateController = TextEditingController(text: ratePerKm.toStringAsFixed(0));
    TextEditingController waitController = TextEditingController(text: ratePerMinuteWait.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('تعديل التسعيرة والرسوم', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رسوم فتح الباب', labelStyle: TextStyle(color: Colors.white70)),
                ),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الكيلومتر', labelStyle: TextStyle(color: Colors.white70)),
                ),
                TextField(
                  controller: waitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر دقيقة الانتظار', labelStyle: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
              onPressed: () {
                setState(() {
                  baseFare = double.tryParse(baseController.text) ?? baseFare;
                  ratePerKm = double.tryParse(rateController.text) ?? ratePerKm;
                  ratePerMinuteWait = double.tryParse(waitController.text) ?? ratePerMinuteWait;
                });
                Navigator.pop(ctx);
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
    Future<void> _startTrip() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      isTripActive = true;
      isPaused = false;
      totalDistanceInMeters = 0.0;
      elapsedSeconds = 0;
      pausedSeconds = 0;
      totalFare = baseFare;
      _lastPosition = null;
      currentSpeed = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
        if (isPaused || (currentSpeed < 5.0 && isTripActive)) {
          pausedSeconds++;
          _calculateFare();
        }
      });
    });

    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3);

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      setState(() {
        currentSpeed = (position.speed * 3.6).clamp(0.0, 180.0);
      });

      if (!isPaused) {
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (distance >= 2.5) {
            setState(() {
              totalDistanceInMeters += distance;
              _calculateFare();
            });
          }
        }
        _lastPosition = position;
      }
    });
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  Future<void> _stopTrip() async {
    _positionStream?.cancel();
    _timer?.cancel();

    if (totalDistanceInMeters > 0 || totalFare > baseFare) {
      String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
      TripModel newTrip = TripModel(
        distanceKm: totalDistanceInMeters / 1000.0,
        fare: totalFare,
        durationSeconds: elapsedSeconds,
        date: formattedDate,
      );
      await DatabaseHelper.instance.insertTrip(newTrip);
    }

    setState(() {
      isTripActive = false;
      isPaused = false;
      currentSpeed = 0.0;
    });

    _showTripSummaryDialog();
  }

  void _calculateFare() {
    double distanceInKm = totalDistanceInMeters / 1000.0;
    double distanceCost = distanceInKm * ratePerKm;
    double waitMinutes = pausedSeconds / 60.0;
    double waitCost = waitMinutes * ratePerMinuteWait;

    totalFare = baseFare + distanceCost + waitCost;
  }

  void _showTripSummaryDialog() {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('ملخص المشوار النهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المسافة المقطوعة: ${(totalDistanceInMeters / 1000).toStringAsFixed(2)} كم', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('الوقت الإجمالي: ${_formatTime(elapsedSeconds)}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('وقت الانتظار: ${_formatTime(pausedSeconds)}', style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text(
                    currencyFormatter.format(totalFare.round()),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تم وحفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عداد التاكسي الذكي', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F172A),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFFF59E0B)),
              onPressed: isTripActive
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: isTripActive ? null : _openSettingsDialog,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFF0A0F1D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      const Text('الأجرة الإجمالية للمشوار', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(totalFare.round()),
                        style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B), fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Text('فتح الباب: ${baseFare.toStringAsFixed(0)} • السعر/كم: ${ratePerKm.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildMetricCard('المسافة المقطوعة', '${(totalDistanceInMeters / 1000).toStringAsFixed(2)} كم', Icons.navigation, const Color(0xFF06B6D4)),
                    _buildMetricCard('السرعة الحالية', '${currentSpeed.toStringAsFixed(0)} كم/س', Icons.speed, const Color(0xFF10B981)),
                    _buildMetricCard('الوقت المنقضي', _formatTime(elapsedSeconds), Icons.timer, Colors.white70),
                    _buildMetricCard('وقت الانتظار', _formatTime(pausedSeconds), Icons.pause_circle_outline, const Color(0xFFF59E0B)),
                  ],
                ),
              ),
              if (!isTripActive)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _startTrip,
                  icon: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
                  label: const Text('بدء المشوار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaused ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _togglePause,
                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isPaused ? Colors.black : Colors.white),
                        label: Text(isPaused ? 'استئناف' : 'انتظار', style: TextStyle(fontWeight: FontWeight.bold, color: isPaused ? Colors.black : Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _stopTrip,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text('إنهاء', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
// شاشة سجل المشاوير
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<TripModel>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _tripsFuture = DatabaseHelper.instance.getAllTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل المشاوير السابقة'),
          backgroundColor: const Color(0xFF0F172A),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'حذف السجل بالكامل',
              onPressed: () async {
                await DatabaseHelper.instance.clearHistory();
                _loadTrips();
              },
            ),
          ],
        ),
        body: FutureBuilder<List<TripModel>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('لا توجد مشاوير مسجلة حتى الآن', style: TextStyle(color: Colors.white60, fontSize: 16)),
              );
            }

            final trips = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips.length > index ? trips[index] : trips[0];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      'الأجرة: ${currencyFormatter.format(trip.fare.round())}',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'المسافة: ${trip.distanceKm.toStringAsFixed(2)} كم\nالتاريخ: ${trip.date}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        if (trip.id != null) {
                          await DatabaseHelper.instance.deleteTrip(trip.id!);
                          _loadTrips();
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
