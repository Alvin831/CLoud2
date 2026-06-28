import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/models/billiard_place.dart';
import '../../core/providers/billiard_provider.dart';
import '../../core/theme/app_theme.dart';

/// Halaman rute in-app: menggambar polyline rute jalan dari lokasi GPS user
/// ke tempat biliar tujuan. Pakai OSRM (Open Source Routing Machine) untuk
/// mendapatkan geometry rute sebenarnya (mengikuti jalan).
class RoutePage extends StatefulWidget {
  final BilliardPlace place;
  const RoutePage({super.key, required this.place});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  List<ll.LatLng> _routePoints = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Info rute
  double _distanceKm = 0;
  double _durationMin = 0;

  // Pulse animation untuk marker
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRoute());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Fetch route dari OSRM ─────────────────────────────────────────────────
  Future<void> _fetchRoute() async {
    final bp = context.read<BilliardProvider>();
    if (!bp.hasLocation) {
      // Coba request GPS dulu
      await bp.requestLocation();
      if (!bp.hasLocation) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lokasi GPS tidak tersedia. Aktifkan GPS terlebih dahulu.';
        });
        return;
      }
    }

    final originLat = bp.userLat!;
    final originLng = bp.userLng!;
    final destLat = widget.place.latitude;
    final destLng = widget.place.longitude;

    // OSRM API: driving route
    // Format: /route/v1/driving/{lng1},{lat1};{lng2},{lat2}
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$originLng,$originLat;$destLng,$destLat'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry'];
          final coords = geometry['coordinates'] as List;

          // OSRM returns [lng, lat] → convert to LatLng
          final points = coords
              .map<ll.LatLng>((c) => ll.LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();

          final distance = (route['distance'] as num).toDouble() / 1000; // meters → km
          final duration = (route['duration'] as num).toDouble() / 60; // seconds → min

          setState(() {
            _routePoints = points;
            _distanceKm = distance;
            _durationMin = duration;
            _isLoading = false;
          });

          // Fit peta ke bounds rute
          _fitRouteBounds(originLat, originLng, destLat, destLng);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Rute tidak ditemukan.';
          });
          // Fallback: garis lurus
          _fallbackStraightLine(originLat, originLng, destLat, destLng);
        }
      } else {
        // Fallback: garis lurus
        _fallbackStraightLine(originLat, originLng, destLat, destLng);
      }
    } catch (_) {
      // Fallback: garis lurus kalau offline / error
      _fallbackStraightLine(
        bp.userLat!, bp.userLng!,
        widget.place.latitude, widget.place.longitude,
      );
    }
  }

  void _fallbackStraightLine(
    double originLat, double originLng,
    double destLat, double destLng,
  ) {
    // Hitung jarak lurus pakai Haversine
    final distance = const ll.Distance().as(
      ll.LengthUnit.Kilometer,
      ll.LatLng(originLat, originLng),
      ll.LatLng(destLat, destLng),
    );

    setState(() {
      _routePoints = [
        ll.LatLng(originLat, originLng),
        ll.LatLng(destLat, destLng),
      ];
      _distanceKm = distance;
      _durationMin = distance * 3; // estimasi kasar: ~20 km/jam
      _isLoading = false;
      _errorMessage = 'Menggunakan garis lurus (offline mode).';
    });
    _fitRouteBounds(originLat, originLng, destLat, destLng);
  }

  void _fitRouteBounds(
    double originLat, double originLng,
    double destLat, double destLng,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final bounds = LatLngBounds(
          ll.LatLng(
            originLat < destLat ? originLat : destLat,
            originLng < destLng ? originLng : destLng,
          ),
          ll.LatLng(
            originLat > destLat ? originLat : destLat,
            originLng > destLng ? originLng : destLng,
          ),
        );
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(60),
          ),
        );
      } catch (_) {
        // MapController belum ready, abaikan
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BilliardProvider>();
    final place = widget.place;

    final ll.LatLng origin = bp.hasLocation
        ? ll.LatLng(bp.userLat!, bp.userLng!)
        : ll.LatLng(-7.2575, 112.7521);
    final ll.LatLng destination = ll.LatLng(place.latitude, place.longitude);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ═══ MAP ═══════════════════════════════════════════════════════════
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: destination,
              initialZoom: 14,
            ),
            children: [
              // Dark tiles
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.billiard_surabaya',
                retinaMode: true,
              ),

              // ── Polyline rute ──────────────────────────────────────────
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Glow effect (wider, transparent)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 10,
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                    ),
                    // Main route line
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF2196F3),
                      borderColor: const Color(0xFF1565C0),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),

              // ── User marker (origin - blue pulse) ─────────────────────
              if (bp.hasLocation)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: origin,
                          width: 60,
                          height: 60,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2196F3)
                                        .withOpacity(_pulseAnimation.value),
                                  ),
                                ),
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

              // ── Destination marker (neon green) ───────────────────────
              MarkerLayer(
                markers: [
                  Marker(
                    point: destination,
                    width: 140,
                    height: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.neonGreen.withOpacity(0.5),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_bar_rounded,
                                  size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  place.name.split(' ').first,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          painter: _PointerPainter(color: AppColors.neonGreen),
                          size: const Size(12, 6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Attribution
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© CartoDB © OpenStreetMap © OSRM',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // ═══ TOP BAR (back + title) ════════════════════════════════════════
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.divider.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_rounded,
                            color: Color(0xFF2196F3), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rute ke ${place.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══ LOADING ═══════════════════════════════════════════════════════
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2196F3)),
                    SizedBox(height: 14),
                    Text(
                      'Menghitung rute...',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // ═══ FABs ══════════════════════════════════════════════════════════
          if (!_isLoading)
            Positioned(
              bottom: 200,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fit route bounds
                  GestureDetector(
                    onTap: () {
                      if (bp.hasLocation) {
                        _fitRouteBounds(
                          bp.userLat!, bp.userLng!,
                          place.latitude, place.longitude,
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.zoom_out_map_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Center on user
                  GestureDetector(
                    onTap: () {
                      if (bp.hasLocation) {
                        _mapController.move(origin, 15);
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color:
                                  const Color(0xFF2196F3).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

          // ═══ BOTTOM INFO CARD ══════════════════════════════════════════════
          if (!_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCard(place, bp),
            ),
        ],
      ),
    );
  }

  // ── Bottom card info rute ─────────────────────────────────────────────────
  Widget _buildBottomCard(BilliardPlace place, BilliardProvider bp) {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Route info chips
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.straighten_rounded,
                label: '${_distanceKm.toStringAsFixed(1)} km',
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 10),
              _buildInfoChip(
                icon: Icons.access_time_rounded,
                label: '~${_durationMin.toStringAsFixed(0)} menit',
                color: AppColors.neonGreen,
              ),
              const SizedBox(width: 10),
              _buildInfoChip(
                icon: Icons.directions_rounded,
                label: 'Berkendara',
                color: AppColors.rating,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Error message (if any)
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.rating.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.rating.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.rating, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.rating),
                    ),
                  ),
                ],
              ),
            ),

          // Destination info
          Row(
            children: [
              // Origin indicator
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2196F3),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: const Color(0xFF2196F3).withOpacity(0.4),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonGreen,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Origin & destination text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi Saya',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      bp.hasLocation
                          ? '${bp.userLat!.toStringAsFixed(4)}, ${bp.userLng!.toStringAsFixed(4)}'
                          : 'GPS tidak aktif',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      place.shortAddress,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
