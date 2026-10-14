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
      title: 'سجل المشاوير',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        fontFamily: 'sans-serif',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _trips = [];
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();
  final _phoneController = TextEditingController();

  final String _defaultPhone = "967700000000"; 

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

  void _addTrip() {
    if (_destinationController.text.isEmpty || _fareController.text.isEmpty) {
      return;
    }
    setState(() {
      _trips.add({
        'destination': _destinationController.text,
        'fare': _fareController.text,
        'phone': _phoneController.text.isEmpty ? _defaultPhone : _phoneController.text,
        'date': DateTime.now().toString().substring(0, 16),
      });
      _destinationController.clear();
      _fareController.clear();
      _phoneController.clear();
    });
    Navigator.of(context).pop();
  }

  void _showAddTripDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة مشوار جديد', textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'الوجهة / المكان'),
                textAlign: TextAlign.right,
              ),
              TextField(
                controller: _fareController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الأجرة / السعر'),
                textAlign: TextAlign.right,
              ),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: _addTrip,
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
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
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.green),
            tooltip: 'واتساب',
            onPressed: () => _openWhatsApp(_defaultPhone),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            tooltip: 'اتصال',
            onPressed: () => _makeCall(_defaultPhone),
          ),
        ],
      ),
      body: _trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_taxi, size: 80, color: Colors.amber),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد مشاوير مسجلة بعد',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _trips.length,
              itemBuilder: (ctx, index) {
                final trip = _trips[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // حواف مقوسة ومرتبة
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.local_taxi, color: Colors.black),
                      ),
                      title: Text(
                        trip['destination']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${trip['date']}'),
                          const SizedBox(height: 2),
                          Text(
                            '${trip['fare']} ريال',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      // إعطاء مساحة كافية لظهور الأزرار كاملة بدون أي قص
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.green, size: 26),
                            onPressed: () => _openWhatsApp(trip['phone']!),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.blue, size: 26),
                            onPressed: () => _makeCall(trip['phone']!),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTripDialog,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('مشوار جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
