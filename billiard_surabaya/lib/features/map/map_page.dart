import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../core/models/billiard_place.dart';
import '../../core/providers/billiard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/place_image.dart';
import '../detail/detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  BilliardPlace? _selectedPlace;

  // ── Radius (dalam km) ─────────────────────────────────────────────────────
  double _radiusKm = 5.0;
  static const List<double> _radiusOptions = [1, 3, 5, 10];

  // ── Pulse animation untuk marker user ─────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Pusat Surabaya (fallback jika GPS belum aktif) ────────────────────────
  static const ll.LatLng _surabayaCenter = ll.LatLng(-7.2575, 112.7521);

  // ── Draggable sheet ───────────────────────────────────────────────────────
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _sheetExpanded = false;

  @override
  void initState() {
    super.initState();

    // Animasi pulse untuk marker lokasi user
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-request GPS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BilliardProvider>();
      if (!bp.hasLocation) {
        bp.requestLocation().then((_) {
          if (bp.hasLocation && mounted) {
            bp.setFilter('Terdekat');
            _mapController.move(
              ll.LatLng(bp.userLat!, bp.userLng!),
              14,
            );
          }
        });
      } else {
        // Kalau GPS sudah ada, langsung set filter & center
        bp.setFilter('Terdekat');
        _mapController.move(
          ll.LatLng(bp.userLat!, bp.userLng!),
          14,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  ll.LatLng _userLatLng(BilliardProvider bp) {
    if (bp.hasLocation) return ll.LatLng(bp.userLat!, bp.userLng!);
    return _surabayaCenter;
  }

  /// Hitung radius dalam meter untuk CircleLayer
  double get _radiusMeters => _radiusKm * 1000;

  void _centerOnUser(BilliardProvider bp) {
    if (bp.hasLocation) {
      _mapController.move(ll.LatLng(bp.userLat!, bp.userLng!), 14);
    } else {
      bp.requestLocation().then((_) {
        if (bp.hasLocation && mounted) {
          bp.setFilter('Terdekat');
          _mapController.move(ll.LatLng(bp.userLat!, bp.userLng!), 14);
        }
      });
    }
  }

  void _selectPlace(BilliardPlace place) {
    setState(() => _selectedPlace = place);
    _mapController.move(ll.LatLng(place.latitude, place.longitude), 15);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<BilliardProvider>(
      builder: (context, bp, _) {
        final places = bp.filteredPlaces;
        final hasLoc = bp.hasLocation;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ═══ FLUTTER MAP ═══════════════════════════════════════════════
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: hasLoc ? _userLatLng(bp) : _surabayaCenter,
                  initialZoom: 13,
                  onTap: (_, __) => setState(() => _selectedPlace = null),
                ),
                children: [
                  // ── Dark Tiles (CartoDB Dark Matter) ────────────────────
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.billiard_surabaya',
                    retinaMode: true,
                  ),

                  // ── Radius Circle ──────────────────────────────────────
                  if (hasLoc)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _userLatLng(bp),
                          radius: _radiusMeters,
                          useRadiusInMeter: true,
                          color: AppColors.neonGreen.withOpacity(0.08),
                          borderColor: AppColors.neonGreen.withOpacity(0.4),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),

                  // ── User Location Marker (blue pulsing dot) ────────────
                  if (hasLoc)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return MarkerLayer(
                          markers: [
                            Marker(
                              point: _userLatLng(bp),
                              width: 60,
                              height: 60,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Pulse ring
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2196F3)
                                            .withOpacity(
                                                _pulseAnimation.value),
                                      ),
                                    ),
                                    // Inner dot
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2196F3),
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2196F3)
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // ── Place Markers ──────────────────────────────────────
                  MarkerLayer(
                    markers: places.map((p) {
                      final isSelected = _selectedPlace?.id == p.id;
                      // Cek apakah di dalam radius
                      final inRadius = !hasLoc || p.distanceKm <= _radiusKm;

                      return Marker(
                        point: ll.LatLng(p.latitude, p.longitude),
                        width: 130,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _selectPlace(p),
                          child: Opacity(
                            opacity: inRadius ? 1.0 : 0.35,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.neonGreen
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.neonGreen
                                          : AppColors.divider,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.neonGreen
                                                .withOpacity(0.5)
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
                                          color: isSelected
                                              ? Colors.black
                                              : AppColors.neonGreen),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          p.name.split(' ').first,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.black
                                                : AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Jarak kecil jika GPS aktif
                                      if (hasLoc) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p.distanceKm.toStringAsFixed(1)}km',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.black54
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Triangle pointer
                                CustomPaint(
                                  painter: _PointerPainter(
                                    color: isSelected
                                        ? AppColors.neonGreen
                                        : AppColors.surface,
                                  ),
                                  size: const Size(10, 5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Attribution ────────────────────────────────────────
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© CartoDB © OpenStreetMap',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),

              // ═══ TOP BAR ═══════════════════════════════════════════════════
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: _buildTopBar(bp),
              ),

              // ═══ RADIUS SELECTOR CHIPS ═════════════════════════════════════
              if (hasLoc)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 72,
                  left: 16,
                  child: _buildRadiusSelector(),
                ),

              // ═══ LOADING ═══════════════════════════════════════════════════
              if (bp.isLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.neonGreen)),

              // ═══ GPS STATUS BANNER ═════════════════════════════════════════
              if (bp.locationStatus == LocationStatus.loading)
                Positioned(
                  top: MediaQuery.of(context).padding.top +
                      (hasLoc ? 110 : 72),
                  left: 16,
                  right: 16,
                  child: _buildGpsLoadingBanner(),
                ),

              // ═══ FABs ══════════════════════════════════════════════════════
              Positioned(
                bottom: _selectedPlace != null
                    ? 240
                    : (_sheetExpanded ? 320 : 160),
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reset view
                    _buildSmallFAB(
                      icon: Icons.zoom_out_map_rounded,
                      tooltip: 'Lihat semua',
                      onTap: () => _mapController.move(_surabayaCenter, 12),
                    ),
                    const SizedBox(height: 10),
                    // Center on user
                    _buildMyLocationFAB(bp),
                  ],
                ),
              ),

              // ═══ BOTTOM SHEET (selected marker) ════════════════════════════
              if (_selectedPlace != null) _buildSelectedSheet(_selectedPlace!),

              // ═══ DRAGGABLE BOTTOM PANEL (nearest list) ═════════════════════
              if (_selectedPlace == null)
                _buildDraggablePanel(bp, places),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(BilliardProvider bp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bp.hasLocation
                  ? 'Menampilkan ${bp.filteredPlaces.length} tempat biliar'
                  : 'Cari di peta...',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          // GPS status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bp.hasLocation
                  ? AppColors.neonGreen.withOpacity(0.15)
                  : AppColors.closed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bp.hasLocation
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_off_rounded,
                  color: bp.hasLocation ? AppColors.neonGreen : AppColors.closed,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  bp.hasLocation ? 'GPS ON' : 'GPS OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: bp.hasLocation
                        ? AppColors.neonGreen
                        : AppColors.closed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 4),
            child: Icon(Icons.radar_rounded,
                size: 14, color: AppColors.neonGreen),
          ),
          ..._radiusOptions.map((r) {
            final isActive = _radiusKm == r;
            return GestureDetector(
              onTap: () => setState(() => _radiusKm = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.neonGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.toInt()}km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.black : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGpsLoadingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF2196F3)),
          ),
          SizedBox(width: 10),
          Text(
            'Mendeteksi lokasi GPS...',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallFAB({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1),
          ],
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }

  Widget _buildMyLocationFAB(BilliardProvider bp) {
    final isLoading = bp.locationStatus == LocationStatus.loading;
    return GestureDetector(
      onTap: isLoading ? null : () => _centerOnUser(bp),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.neonGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.neonGreen.withOpacity(0.4),
                blurRadius: 14,
                spreadRadius: 2),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.black),
              )
            : Icon(
                bp.hasLocation
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: Colors.black,
                size: 24),
      ),
    );
  }

  // ── SELECTED PLACE BOTTOM SHEET ───────────────────────────────────────────
  Widget _buildSelectedSheet(BilliardPlace p) {
    final bp = context.read<BilliardProvider>();
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: PlaceImage(
                        imagePath: p.imagePath,
                        imageUrl: p.imageUrl,
                        height: 72),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.rating, size: 14),
                          const SizedBox(width: 3),
                          Text(p.rating.toString(),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          if (bp.hasLocation) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.near_me_rounded,
                                color: AppColors.neonGreen, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '${p.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p.shortAddress,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (p.isCurrentlyOpen
                                      ? AppColors.open
                                      : AppColors.closed)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.isCurrentlyOpen ? 'Buka' : 'Tutup',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: p.isCurrentlyOpen
                                    ? AppColors.open
                                    : AppColors.closed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rp ${(p.pricePerHour / 1000).toStringAsFixed(0)}k/jam',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
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
                    onPressed: () =>
                        setState(() => _selectedPlace = null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailPage(place: p)),
                    ),
                    icon:
                        const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Lihat Detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  // ── DRAGGABLE BOTTOM PANEL (nearest list) ─────────────────────────────────
  Widget _buildDraggablePanel(
      BilliardProvider bp, List<BilliardPlace> places) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.15,
      minChildSize: 0.08,
      maxChildSize: 0.55,
      snap: true,
      snapSizes: const [0.15, 0.35, 0.55],
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            final expanded = notification.extent > 0.2;
            if (expanded != _sheetExpanded) {
              setState(() => _sheetExpanded = expanded);
            }
            return false;
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border:
                  const Border(top: BorderSide(color: AppColors.divider)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                // ── Handle + Header ──────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me_rounded,
                          color: AppColors.neonGreen, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Tempat Terdekat',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${places.length}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        bp.hasLocation
                            ? 'Radius ${_radiusKm.toInt()} km'
                            : 'GPS belum aktif',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── List Items ───────────────────────────────────────────
                ...places.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final inRadius =
                      !bp.hasLocation || p.distanceKm <= _radiusKm;

                  return Opacity(
                    opacity: inRadius ? 1.0 : 0.45,
                    child: InkWell(
                      onTap: () => _selectPlace(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.divider.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Ranking number
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: i < 3
                                    ? AppColors.neonGreen.withOpacity(0.15)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: i < 3
                                        ? AppColors.neonGreen
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: PlaceImage(
                                  imagePath: p.imagePath,
                                  imageUrl: p.imageUrl,
                                  height: 44,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.rating,
                                          size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        p.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1),
                                        decoration: BoxDecoration(
                                          color: (p.isCurrentlyOpen
                                                  ? AppColors.open
                                                  : AppColors.closed)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          p.isCurrentlyOpen ? 'Buka' : 'Tutup',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: p.isCurrentlyOpen
                                                ? AppColors.open
                                                : AppColors.closed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Distance
                            if (bp.hasLocation)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: inRadius
                                      ? AppColors.neonGreen
                                          .withOpacity(0.1)
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${p.distanceKm.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: inRadius
                                        ? AppColors.neonGreen
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═════════════════════════════════════════════════════════════════════════════

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
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