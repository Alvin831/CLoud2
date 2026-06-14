import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/billiard_place.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/place_image.dart';
import '../detail/detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  BilliardPlace? _selectedPlace;
  final MapController _mapController = MapController();
  List<BilliardPlace> _places = [];
  bool _isLoading = true;

  // Pusat Surabaya
  static const ll.LatLng _surabaya = ll.LatLng(-7.2575, 112.7521);

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('places').get();
      final places = snapshot.docs.map((doc) => BilliardPlace.fromFirestore(doc)).toList();
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Flutter Map dengan OpenStreetMap tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _surabaya,
              initialZoom: 13,
              onTap: (_, __) => setState(() => _selectedPlace = null),
            ),
            children: [
              // OpenStreetMap tile layer dengan attribution
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.billiard_surabaya',
                retinaMode: true,
              ),
              // Attribution untuk OpenStreetMap
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
              // Marker layer
              if (!_isLoading)
                MarkerLayer(
                  markers: _places.map((p) {
                    final isSelected = _selectedPlace?.id == p.id;
                    return Marker(
                      point: ll.LatLng(p.latitude, p.longitude),
                      width: 120,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedPlace = p);
                          _mapController.move(ll.LatLng(p.latitude, p.longitude), 15);
                        },
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.neonGreen : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.neonGreen : AppColors.divider,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppColors.neonGreen.withOpacity(0.5)
                                        : Colors.black.withOpacity(0.4),
                                    blurRadius: isSelected ? 12 : 4,
                                    spreadRadius: isSelected ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sports_bar_rounded,
                                      size: 12,
                                      color: isSelected ? Colors.black : AppColors.neonGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.name.split(' ').first,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.black : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Triangle pointer
                            CustomPaint(
                              painter: _PointerPainter(
                                color: isSelected ? AppColors.neonGreen : AppColors.surface,
                              ),
                              size: const Size(10, 5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Top search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),

          // FAB lokasi saya
          Positioned(
            bottom: _selectedPlace != null ? 230 : 32,
            right: 16,
            child: _buildFAB(),
          ),

          // Bottom sheet marker
          if (_selectedPlace != null) _buildBottomSheet(_selectedPlace!),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Cari di peta...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.filter_list_rounded, color: AppColors.neonGreen, size: 14),
                SizedBox(width: 4),
                Text('Filter', style: TextStyle(fontSize: 11, color: AppColors.neonGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _mapController.move(_surabaya, 13),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.neonGreen,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
        ),
        child: const Icon(Icons.my_location_rounded, color: Colors.black, size: 22),
      ),
    );
  }

  Widget _buildBottomSheet(BilliardPlace p) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72, height: 72,
                    child: PlaceImage(imagePath: p.imagePath, imageUrl: p.imageUrl, height: 72),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.rating, size: 14),
                          const SizedBox(width: 3),
                          Text(p.rating.toString(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 12),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(p.shortAddress,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (p.isOpen ? AppColors.open : AppColors.closed).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.isOpen ? 'Buka Sekarang' : 'Tutup',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: p.isOpen ? AppColors.open : AppColors.closed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedPlace = null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(place: p))),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Lihat Detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
