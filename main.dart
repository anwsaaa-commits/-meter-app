import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سجل المشاوير - أبو شاهين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        fontFamily: 'sans-serif',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// شاشة التنقل السفلية لتضمين (السجل، العداد، كشف الحساب، الإعدادات)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> _trips = [];
  String _defaultPhone = "967700000000";

  void _addTrip(Map<String, String> trip) {
    setState(() {
      _trips.insert(0, trip);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(trips: _trips, defaultPhone: _defaultPhone),
      MeterScreen(onTripCompleted: _addTrip, defaultPhone: _defaultPhone),
      StatementScreen(trips: _trips),
      SettingsScreen(
        defaultPhone: _defaultPhone,
        onPhoneChanged: (newPhone) {
          setState(() {
            _defaultPhone = newPhone;
          });
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'السجل'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'العداد'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'كشف الحساب'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// 1. شاشة السجل الرئيسية
class HomeScreen extends StatelessWidget {
  final List<Map<String, String>> trips;
  final String defaultPhone;

  const HomeScreen({super.key, required this.trips, required this.defaultPhone});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_taxi, color: Colors.black, size: 28),
            SizedBox(width: 8),
            Text(
              'سجل المشاوير',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.green),
            onPressed: () => _openWhatsApp(defaultPhone),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            onPressed: () => _makeCall(defaultPhone),
          ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_taxi, size: 80, color: Colors.amber),
                  SizedBox(height: 16),
                  Text('لا يوجد مشاوير مسجلة بعد', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (ctx, index) {
                final trip = trips[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.local_taxi, color: Colors.black),
                    ),
                    title: Text(trip['destination']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${trip['date']}\nالأجرة: ${trip['fare']} ريال'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          onPressed: () => _openWhatsApp(trip['phone'] ?? defaultPhone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.blue),
                          onPressed: () => _makeCall(trip['phone'] ?? defaultPhone),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// 2. شاشة العداد لحساب التكلفة
class MeterScreen extends StatefulWidget {
  final Function(Map<String, String>) onTripCompleted;
  final String defaultPhone;

  const MeterScreen({super.key, required this.onTripCompleted, required this.defaultPhone});

  @override
  State<MeterScreen> createState() => _MeterScreenState();
}

class _MeterScreenState extends State<MeterScreen> {
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();

  void _saveCurrentTrip() {
    if (_destinationController.text.isEmpty || _fareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الوجهة والسعر')),
      );
      return;
    }

    widget.onTripCompleted({
      'destination': _destinationController.text,
      'fare': _fareController.text,
      'phone': widget.defaultPhone,
      'date': DateTime.now().toString().substring(0, 16),
    });

    _destinationController.clear();
    _fareController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المشوار بنجاح في السجل')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عداد المشوار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'اسم الوجهة أو المكان',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fareController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'قيمة الأجرة (ريال)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveCurrentTrip,
              icon: const Icon(Icons.save, color: Colors.black),
              label: const Text('حفظ وتسجيل الرحلة', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. شاشة كشف الحساب والأرباح
class StatementScreen extends StatelessWidget {
  final List<Map<String, String>> trips;

  const StatementScreen({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    double totalRevenue = 0;
    for (var trip in trips) {
      totalRevenue += double.tryParse(trip['fare'] ?? '0') ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف الحساب والأرباح', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('إجمالي الأرباح الكلية', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('$totalRevenue ريال', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                    const Divider(height: 24),
                    Text('عدد المشاوير المسجلة: ${trips.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('ملخص الحركات الأخيرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: trips.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : ListView.builder(
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return ListTile(
                          title: Text(trip['destination']!),
                          subtitle: Text(trip['date']!),
                          trailing: Text('${trip['fare']} ريال', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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

// 4. شاشة الإعدادات
class SettingsScreen extends StatefulWidget {
  final String defaultPhone;
  final Function(String) onPhoneChanged;

  const SettingsScreen({super.key, required this.defaultPhone, required this.onPhoneChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.defaultPhone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التطبيق', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف الأساسي (للاتصال والواتساب)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onPhoneChanged(_phoneController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
                );
              },
              child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
