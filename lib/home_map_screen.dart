import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({Key? key}) : super(key: key);

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  late GoogleMapController _mapController;

  // موقع افتراضي (يمكن تغييره لموقعك الحالي)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(14.5425, 49.1242), // بالمكلا / اليمن
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
          // 1. الخريطة التفاعلية في الخلفية
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 2. زر القائمة العلوي وشعار التطبيق
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'تكسي الشاهين',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // 3. شريحة اختيار نوع المشوار والطلب (مثل كريم وأوبر)
          DraggableScrollableSheet(
            initialChildSize: 0.40,
            minChildSize: 0.25,
            maxChildSize: 0.70,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // مقبض السحب
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'إلى أين تريد الذهاب؟',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // قائمة خيارات السيارات
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rideTypes.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedCarIndex == index;
                        var item = _rideTypes[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCarIndex = index);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.grey[100] : Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(item['icon'], size: 36, color: Colors.black),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        item['subtitle'],
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item['price'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    // زر تأكيد طلب المشوار
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم إرسال طلبك: ${_rideTypes[_selectedCarIndex]['title']} جاري البحث عن أقرب سائق...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text(
                          'تأكيد طلب ${_rideTypes[_selectedCarIndex]['title']}',
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
