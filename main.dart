import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaxiApp());
}

const String phone = '+967777521058';
const String waPhone = '967777521058';

class Trip {
  final String id;
  final String from;
  final String to;
  final DateTime startedAt;
  final DateTime endedAt;
  final double km;
  final double fare;
  final double fuelCost;
  final double waitingMinutes;

  Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.startedAt,
    required this.endedAt,
    required this.km,
    required this.fare,
    required this.fuelCost,
    required this.waitingMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'km': km,
        'fare': fare,
        'fuelCost': fuelCost,
        'waitingMinutes': waitingMinutes,
      };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] ?? '',
        from: j['from'] ?? '',
        to: j['to'] ?? '',
        startedAt: DateTime.parse(j['startedAt']),
        endedAt: DateTime.parse(j['endedAt']),
        km: (j['km'] as num).toDouble(),
        fare: (j['fare'] as num).toDouble(),
        fuelCost: (j['fuelCost'] as num).toDouble(),
        waitingMinutes: ((j['waitingMinutes'] ?? 0) as num).toDouble(),
      );
}

class Expense {
  final String title;
  final double amount;
  final DateTime date;

  Expense(this.title, this.amount, this.date);

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        j['title'] ?? '',
        (j['amount'] as num).toDouble(),
        DateTime.parse(j['date']),
      );
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تكسي الشاهين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff087f5b),
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const TaxiHome(),
    );
  }
}

class TaxiHome extends StatefulWidget {
  const TaxiHome({super.key});

  @override
  State<TaxiHome> createState() => _TaxiHomeState();
}

class _TaxiHomeState extends State<TaxiHome> {
  SharedPreferences? prefs;

  double baseFare = 500;
  double perKm = 200;
  double perMinute = 50;
  double fuelPrice = 1550;
  double consumption = 10;

  List<Trip> trips = [];
  List<Expense> expenses = [];

  bool running = false;
  Position? lastPosition;
  StreamSubscription<Position>? gpsSub;
  DateTime? startedAt;

  double tripKm = 0;
  double waitingMinutes = 0;
  String gpsMessage = 'الموقع غير مفعّل';

  final fromController = TextEditingController();
  final toController = TextEditingController();
  final waitController = TextEditingController(text: '0');
  final expenseTitle = TextEditingController();
  final expenseAmount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    gpsSub?.cancel();
    fromController.dispose();
    toController.dispose();
    waitController.dispose();
    expenseTitle.dispose();
    expenseAmount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    prefs = await SharedPreferences.getInstance();

    try {
      final loadedTrips = (jsonDecode(
        prefs!.getString('trips') ?? '[]',
      ) as List)
          .map((e) => Trip.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      final loadedExpenses = (jsonDecode(
        prefs!.getString('expenses') ?? '[]',
      ) as List)
          .map((e) => Expense.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      if (!mounted) return;

      setState(() {
        baseFare = prefs!.getDouble('baseFare') ?? 500;
        perKm = prefs!.getDouble('perKm') ?? 200;
        perMinute = prefs!.getDouble('perMinute') ?? 50;
        fuelPrice = prefs!.getDouble('fuelPrice') ?? 1550;
        consumption = prefs!.getDouble('consumption') ?? 10;
        trips = loadedTrips;
        expenses = loadedExpenses;
      });
    } catch (_) {
      if (mounted) {
        _snack('تعذر قراءة البيانات المحفوظة');
      }
    }
  }

  Future<void> _save() async {
    prefs ??= await SharedPreferences.getInstance();

    await prefs!.setDouble('baseFare', baseFare);
    await prefs!.setDouble('perKm', perKm);
    await prefs!.setDouble('perMinute', perMinute);
    await prefs!.setDouble('fuelPrice', fuelPrice);
    await prefs!.setDouble('consumption', consumption);

    await prefs!.setString(
      'trips',
      jsonEncode(trips.map((e) => e.toJson()).toList()),
    );

    await prefs!.setString(
      'expenses',
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }

  double get estimatedFare =>
      baseFare + tripKm * perKm + waitingMinutes * perMinute;

  double get fuelEstimate => tripKm * consumption / 100 * fuelPrice;

  double get revenue => trips.fold(0, (sum, t) => sum + t.fare);

  double get fuelTotal => trips.fold(0, (sum, t) => sum + t.fuelCost);

  double get expensesTotal => expenses.fold(0, (sum, e) => sum + e.amount);

  double get netProfit => revenue - fuelTotal - expensesTotal;

  Future<void> _startTrip() async {
    if (running) return;

    if (fromController.text.trim().isEmpty) {
      _snack('اكتب منطقة الانطلاق أولاً');
      return;
    }

    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      _snack('فعّل خدمة الموقع GPS من إعدادات الهاتف');
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _snack('يجب السماح للتطبيق باستخدام الموقع');

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }

      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        lastPosition = position;
        tripKm = 0;
        waitingMinutes = double.tryParse(waitController.text) ?? 0;
        startedAt = DateTime.now();
        running = true;
        gpsMessage = 'GPS يعمل';
      });

      gpsSub?.cancel();

      gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          if (!running) return;

          final previous = lastPosition;

          if (previous != null) {
            final meters = Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            );

            if (meters > 0 && meters < 1000 && mounted) {
              setState(() {
                tripKm += meters / 1000;
              });
            }
          }

          lastPosition = position;
        },
        onError: (_) {
          if (mounted) {
            setState(() => gpsMessage = 'تعذر تحديث GPS');
          }
        },
      );
    } catch (_) {
      _snack('تعذر الحصول على الموقع. تحقق من GPS والأذونات.');
    }
  }

  Future<void> _finishTrip() async {
    if (!running || startedAt == null) return;

    await gpsSub?.cancel();
    gpsSub = null;

    final now = DateTime.now();

    final trip = Trip(
      id: now.microsecondsSinceEpoch.toString(),
      from: fromController.text.trim(),
      to: toController.text.trim().isEmpty
          ? 'غير محددة'
          : toController.text.trim(),
      startedAt: startedAt!,
      endedAt: now,
      km: tripKm,
      fare: estimatedFare,
      fuelCost: fuelEstimate,
      waitingMinutes: waitingMinutes,
    );

    setState(() {
      trips.insert(0, trip);
      running = false;
      lastPosition = null;
      gpsMessage = 'انتهى المشوار';
    });

    await _save();
    _snack('تم حفظ المشوار');
  }

  Future<void> _call() async {
    final uri = Uri.parse('tel:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('تعذر فتح الاتصال');
    }
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse(
      'https://wa.me/$waPhone?text=${Uri.encodeComponent('السلام عليكم، أريد الاستفسار عن تكسي الشاهين')}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      _snack('تعذر فتح واتساب');
    }
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String money(num value) => '${value.toStringAsFixed(0)} ريال';

  Future<void> _settings() async {
    final b = TextEditingController(text: baseFare.toStringAsFixed(0));
    final k = TextEditingController(text: perKm.toStringAsFixed(0));
    final m = TextEditingController(text: perMinute.toStringAsFixed(0));
    final f = TextEditingController(text: fuelPrice.toStringAsFixed(0));
    final c = TextEditingController(text: consumption.toStringAsFixed(1));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعدادات التسعير والوقود'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(b, 'أجرة البداية (ريال)'),
              _field(k, 'سعر الكيلومتر (ريال)'),
              _field(m, 'سعر دقيقة الانتظار (ريال)'),
              _field(f, 'سعر لتر الوقود (ريال)'),
              _field(c, 'الاستهلاك لكل 100 كم (لتر)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        baseFare = double.tryParse(b.text) ?? baseFare;
        perKm = double.tryParse(k.text) ?? perKm;
        perMinute = double.tryParse(m.text) ?? perMinute;
        fuelPrice = double.tryParse(f.text) ?? fuelPrice;
        consumption = double.tryParse(c.text) ?? consumption;
      });

      await _save();
    }

    b.dispose();
    k.dispose();
    m.dispose();
    f.dispose();
    c.dispose();
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _addExpense() async {
    expenseTitle.clear();
    expenseAmount.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(expenseTitle, 'نوع المصروف'),
            _field(expenseAmount, 'المبلغ بالريال'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    final amount = double.tryParse(expenseAmount.text);

    if (ok == true && amount != null && amount > 0) {
      setState(() {
        expenses.insert(
          0,
          Expense(
            expenseTitle.text.trim().isEmpty
                ? 'مصروف'
                : expenseTitle.text.trim(),
            amount,
            DateTime.now(),
          ),
        );
      });

      await _save();
    }
  }

  Future<void> _shareReport() async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final buffer = StringBuffer('كشف حساب تكسي الشاهين\n\n');

    buffer.writeln('عدد المشاوير: ${trips.length}');
    buffer.writeln('الإيرادات: ${money(revenue)}');
    buffer.writeln('تكلفة الوقود التقديرية: ${money(fuelTotal)}');
    buffer.writeln('المصاريف الأخرى: ${money(expensesTotal)}');
    buffer.writeln('صافي الربح التقديري: ${money(netProfit)}\n');

    for (final trip in trips) {
      buffer.writeln(
        '${fmt.format(trip.startedAt)} | ${trip.from} ← ${trip.to} | '
        '${trip.km.toStringAsFixed(2)} كم | ${money(trip.fare)} | '
        'وقود ${money(trip.fuelCost)}',
      );
    }

    await Share.share(buffer.toString());
  }

  Widget _stat(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd – HH:mm');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تكسي الشاهين'),
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: _settings,
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              tooltip: 'كشف الحساب',
              onPressed: _shareReport,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'أجرة المشوار الحالية',
                      style: TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(estimatedFare),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'المسافة: ${tripKm.toStringAsFixed(2)} كم'
                      ' • الوقود التقديري: ${money(fuelEstimate)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          running ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: running ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(gpsMessage),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: 'منطقة الانطلاق',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'منطقة الوصول',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: waitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'دقائق الانتظار',
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: running ? null : _startTrip,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('بدء المشوار'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: running ? _finishTrip : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('إنهاء وحفظ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _call,
                    icon: const Icon(Icons.call),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _whatsapp,
                    icon: const Icon(Icons.chat),
                    label: const Text('واتساب'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'ملخص الحساب المحفوظ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _stat('عدد المشاوير', trips.length.toString(), Icons.alt_route),
                _stat('الإيرادات', money(revenue), Icons.account_balance_wallet),
                _stat('تكلفة الوقود', money(fuelTotal), Icons.local_gas_station),
                _stat('المصاريف الأخرى', money(expense
