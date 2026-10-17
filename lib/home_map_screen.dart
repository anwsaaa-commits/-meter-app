import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({Key? key}) : super(key: key);

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(14.5425, 49.1242), // حضرموت / المكلا
    zoom: 14.5,
  );

  int _selectedCarIndex = 0;

  final List<Map<String, dynamic>> _rideTypes = [
    {
      'title': 'شاهين عادي',
      'subtitle': 'تكسي اقتصادي وسريع',
      'price': '1500 ر.ي',
      'icon': Icons.local_taxi,
    },
    {
      'title': 'شاهين عائلي (Voxy/Previa)',
      'subtitle': 'سيارة واسعة للعائلات',
      'price': '2500 ر.ي',
      'icon': Icons.directions_car_filled,
    },
    {
      'title': 'مشوار خاص',
      'subtitle': 'توصيل مباشر وسريع',
      'price': '2000 ر.ي',
      'icon': Icons.car_rental,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. خريطة جوجل
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 2. شريط العلوي (القائمة والإشعارات)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(30),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      // القائمة الجانبية أو خيارات الحساب
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: const Text(
                    'تكسي الشاهين',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(30),
                  child: IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // 3. لوحة اختيار نوع الرحلة أسفل الشاشة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر نوع الرحلة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _rideTypes.length,
                      itemBuilder: (context, index) {
                        final ride = _rideTypes[index];
                        final isSelected = _selectedCarIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCarIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  // كارت عرض الخيار المحدد
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(_rideTypes[_selectedCarIndex]['icon'], size: 40, color: Colors.amber.shade800),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _rideTypes[_selectedCarIndex]['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _rideTypes[_selectedCarIndex]['subtitle'],
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _rideTypes[_selectedCarIndex]['price'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم طلب ${_rideTypes[_selectedCarIndex]['title']} بنجاح!')),
                        );
                      },
                      child: const Text(
                        'طلب تكسي الشاهين الان',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
