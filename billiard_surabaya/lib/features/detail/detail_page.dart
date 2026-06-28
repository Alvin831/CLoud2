import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/billiard_place.dart';
import '../../core/providers/favorite_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/place_image.dart';
import '../reservation/reservation_page.dart';
import '../auth/login_page.dart';
import '../map/route_page.dart';

class DetailPage extends StatefulWidget {
  final BilliardPlace place;
  const DetailPage({super.key, required this.place});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _isScrolled = _scrollController.offset > 200);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutePage(place: widget.place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(p),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(p),
                      const SizedBox(height: 16),
                      _buildStatusRow(p),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildAddressSection(p),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildDescription(p),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildFacilities(p),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildGallery(p),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActions(p),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BilliardPlace p) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      actions: [
        Consumer<FavoriteProvider>(
          builder: (_, favProvider, __) {
            final isFav = favProvider.isFavorite(p.id);
            return GestureDetector(
              onTap: () => favProvider.toggle(p),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: isFav ? Colors.red : Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PlaceImage(
              imagePath: p.imagePath,
              imageUrl: p.galleryImages.isNotEmpty
                  ? p.galleryImages[_selectedImageIndex]
                  : p.imageUrl,
              height: 280,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BilliardPlace p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.rating, size: 18),
            const SizedBox(width: 4),
            Text(
              p.rating.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            Text(
              '(${p.reviewCount} ulasan)',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
              ),
              child: Text(
                'Rp ${(p.pricePerHour / 1000).toStringAsFixed(0)}k/jam',
                style: const TextStyle(fontSize: 12, color: AppColors.neonGreen, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(BilliardPlace p) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (p.isOpen ? AppColors.open : AppColors.closed).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (p.isOpen ? AppColors.open : AppColors.closed).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p.isCurrentlyOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: p.isCurrentlyOpen ? AppColors.open : AppColors.closed,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                p.isCurrentlyOpen ? 'Buka Sekarang' : 'Tutup',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.isCurrentlyOpen ? AppColors.open : AppColors.closed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Text(p.operatingHours, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        const Icon(Icons.table_bar_rounded, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Text('${p.tableCount} meja', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAddressSection(BilliardPlace p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alamat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded, color: AppColors.neonGreen, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullAddress, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded, color: AppColors.neonGreen, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${p.distanceKm} km dari lokasi Anda',
                        style: const TextStyle(fontSize: 11, color: AppColors.neonGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(BilliardPlace p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deskripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(p.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
      ],
    );
  }

  Widget _buildFacilities(BilliardPlace p) {
    final facilityIcons = {
      'AC': Icons.ac_unit_rounded,
      'WiFi': Icons.wifi_rounded,
      'Cafe': Icons.local_cafe_rounded,
      'Parkir': Icons.local_parking_rounded,
      'Toilet': Icons.wc_rounded,
      'VIP Room': Icons.king_bed_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fasilitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: p.facilities.map((f) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(facilityIcons[f] ?? Icons.check_circle_outline_rounded, color: AppColors.neonGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(f, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGallery(BilliardPlace p) {
    if (p.galleryImages.length <= 1) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Galeri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: p.galleryImages.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _selectedImageIndex = i),
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedImageIndex == i ? AppColors.neonGreen : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: PlaceImage(
                    imagePath: p.imagePath,
                    imageUrl: p.galleryImages[i],
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BilliardPlace p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openRoute,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Rute'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                    side: const BorderSide(color: AppColors.neonGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Consumer<FavoriteProvider>(
                  builder: (_, favProvider, __) {
                    final isFav = favProvider.isFavorite(p.id);
                    return OutlinedButton.icon(
                      onPressed: () => favProvider.toggle(p),
                      icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 18),
                      label: Text(isFav ? 'Disimpan' : 'Simpan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isFav ? Colors.redAccent : AppColors.textSecondary,
                        side: BorderSide(
                            color: isFav
                                ? Colors.redAccent
                                : AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tombol Reservasi — full width
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginPage()));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ReservationPage(place: p)),
                );
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Reservasi Meja',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.divider, height: 1);
  }
}
