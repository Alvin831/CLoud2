import 'package:flutter/material.dart';
import '../../core/data/dummy_data.dart';
import '../../core/models/billiard_place.dart';
import '../../core/theme/app_theme.dart';
import '../detail/detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  BilliardPlace? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Simulated dark map background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0D1B2A)],
              ),
            ),
            child: CustomPaint(painter: _MapGridPainter(), child: const SizedBox.expand()),
          ),

          // Place markers on simulated map
          ..._buildMapMarkers(context),

          // Top search bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),

          // FAB My Location
          Positioned(
            bottom: _selectedPlace != null ? 220 : 100,
            right: 16,
            child: _buildFAB(),
          ),

          // Bottom sheet
          if (_selectedPlace != null) _buildBottomSheet(_selectedPlace!),
        ],
      ),
    );
  }

  List<Widget> _buildMapMarkers(BuildContext context) {
    // Distribusi posisi marker secara visual di layar
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    final positions = [
      Offset(screenW * 0.5, screenH * 0.35),
      Offset(screenW * 0.3, screenH * 0.45),
      Offset(screenW * 0.65, screenH * 0.55),
      Offset(screenW * 0.2, screenH * 0.60),
      Offset(screenW * 0.75, screenH * 0.40),
    ];

    return List.generate(dummyPlaces.length, (i) {
      final p = dummyPlaces[i];
      final pos = positions[i];
      final isSelected = _selectedPlace?.id == p.id;

      return Positioned(
        left: pos.dx - 22,
        top: pos.dy - 44,
        child: GestureDetector(
          onTap: () => setState(() => _selectedPlace = isSelected ? null : p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                // Marker bubble
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
                            ? AppColors.neonGreen.withOpacity(0.4)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_bar_rounded,
                        size: 12,
                        color: isSelected ? Colors.black : AppColors.neonGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rp ${p.pricePerHour.toInt()}k',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Triangle pointer
                CustomPaint(
                  painter: _MarkerPointerPainter(
                    color: isSelected ? AppColors.neonGreen : AppColors.surface,
                  ),
                  size: const Size(12, 6),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
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
      onTap: () {},
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    p.imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72, height: 72, color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image_not_supported, color: AppColors.textMuted),
                    ),
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
                          const SizedBox(width: 8),
                          const Icon(Icons.near_me_rounded, color: AppColors.neonGreen, size: 13),
                          const SizedBox(width: 3),
                          Text('${p.distanceKm} km',
                              style: const TextStyle(fontSize: 12, color: AppColors.neonGreen, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(p.shortAddress,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// Grid painter untuk simulasi peta
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1E3A5F).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final majorRoadPaint = Paint()
      ..color = const Color(0xFF2A5080).withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Grid lines (jalan kecil)
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 0; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // Jalan utama diagonal
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.6), majorRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.4), majorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.5, size.height), majorRoadPaint);

    // Block fill (area kota)
    final blockPaint = Paint()
      ..color = const Color(0xFF162030).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(60, 80, 100, 60), blockPaint);
    canvas.drawRect(Rect.fromLTWH(200, 160, 80, 120), blockPaint);
    canvas.drawRect(Rect.fromLTWH(80, 280, 120, 80), blockPaint);
    canvas.drawRect(Rect.fromLTWH(260, 320, 90, 100), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Triangle pointer untuk marker
class _MarkerPointerPainter extends CustomPainter {
  final Color color;
  const _MarkerPointerPainter({required this.color});

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

