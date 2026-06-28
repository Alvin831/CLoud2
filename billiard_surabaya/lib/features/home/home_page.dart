import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/providers/billiard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/place_card.dart';
import '../detail/detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  int _bannerIndex = 0;

  final List<String> _filters = ['Semua', 'Terdekat', 'Rating', 'Buka Sekarang'];

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Promo Weekend!\n50% OFF Jam Pertama',
      'subtitle': 'Berlaku Sabtu & Minggu',
      'color': const LinearGradient(
        colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.local_offer_rounded,
    },
    {
      'title': 'Turnamen Billiard\nSurabaya Open 2024',
      'subtitle': 'Daftar sekarang, hadiah jutaan rupiah',
      'color': const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF00B0FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.emoji_events_rounded,
    },
    {
      'title': 'Member Premium\nGratis 2 Jam/Bulan',
      'subtitle': 'Bergabung sekarang mulai Rp 50k/bulan',
      'color': const LinearGradient(
        colors: [Color(0xFF4A148C), Color(0xFFE040FB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.card_membership_rounded,
    },
  ];

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Filter & Search (delegasi ke BilliardProvider) ───────────────────────
  void _applyFilter(String filter) {
    context.read<BilliardProvider>().setFilter(filter);
  }

  void _onSearch(String query) {
    context.read<BilliardProvider>().setSearch(query);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<BilliardProvider>(
      builder: (context, bp, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar()),
                SliverToBoxAdapter(child: _buildSearchBar(bp)),
                SliverToBoxAdapter(child: _buildBannerSection()),
                SliverToBoxAdapter(child: _buildFilterChips(bp)),
                SliverToBoxAdapter(child: _buildSectionHeader(bp)),
                if (bp.isLoading)
                  const SliverToBoxAdapter(child: _LoadingState())
                else if (bp.hasError)
                  SliverToBoxAdapter(
                    child: _ErrorState(
                      message: bp.errorMessage ?? 'Terjadi kesalahan.',
                      onRetry: bp.refresh,
                    ),
                  )
                else if (bp.filteredPlaces.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => PlaceCard(
                          place: bp.filteredPlaces[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailPage(place: bp.filteredPlaces[i]),
                            ),
                          ),
                        ),
                        childCount: bp.filteredPlaces.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Widgets (tidak ada perubahan dari versi temanmu) ─────────────────────
  Widget _buildAppBar() {
    return Consumer<BilliardProvider>(
      builder: (context, bp, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 38,
                height: 38,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Billiard Surabaya',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: bp.hasLocation
                              ? AppColors.neonGreen
                              : AppColors.textMuted,
                          size: 12),
                      const SizedBox(width: 2),
                      Text(
                        bp.hasLocation
                            ? 'Lokasi aktif'
                            : 'Surabaya, Jawa Timur',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Tombol filter harga
              GestureDetector(
                onTap: () => _showPriceFilter(context, bp),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bp.priceFilterActive
                        ? AppColors.neonGreen.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: bp.priceFilterActive
                          ? AppColors.neonGreen
                          : AppColors.divider,
                    ),
                  ),
                  child: Icon(Icons.tune_rounded,
                      color: bp.priceFilterActive
                          ? AppColors.neonGreen
                          : AppColors.textMuted,
                      size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol GPS
              GestureDetector(
                onTap: bp.locationStatus == LocationStatus.loading
                    ? null
                    : () => bp.requestLocation(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bp.hasLocation
                        ? AppColors.neonGreen.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: bp.hasLocation
                          ? AppColors.neonGreen
                          : AppColors.divider,
                    ),
                  ),
                  child: bp.locationStatus == LocationStatus.loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neonGreen))
                      : Icon(Icons.my_location_rounded,
                          color: bp.hasLocation
                              ? AppColors.neonGreen
                              : AppColors.textMuted,
                          size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriceFilter(BuildContext context, BilliardProvider bp) {
    double tempMin = bp.minPrice;
    double tempMax = bp.maxPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Filter Rentang Harga',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Rp ${(tempMin / 1000).toStringAsFixed(0)}k  –  Rp ${(tempMax / 1000).toStringAsFixed(0)}k / jam',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neonGreen),
              ),
              const SizedBox(height: 16),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 0,
                max: 100000,
                divisions: 20,
                activeColor: AppColors.neonGreen,
                inactiveColor: AppColors.divider,
                onChanged: (v) => setModalState(() {
                  tempMin = v.start;
                  tempMax = v.end;
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        bp.clearPriceFilter();
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        bp.setPriceRange(tempMin, tempMax);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BilliardProvider bp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Cari tempat billiard...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: _banners.length,
            options: CarouselOptions(
              height: 140,
              viewportFraction: 0.9,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              enlargeCenterPage: true,
              onPageChanged: (i, _) => setState(() => _bannerIndex = i),
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = _banners[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: banner['color'] as LinearGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle'] as String,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Selengkapnya →',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(banner['icon'] as IconData,
                        color: Colors.white.withOpacity(0.3), size: 64),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          AnimatedSmoothIndicator(
            activeIndex: _bannerIndex,
            count: _banners.length,
            effect: const ExpandingDotsEffect(
              activeDotColor: AppColors.neonGreen,
              dotColor: AppColors.divider,
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BilliardProvider bp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: BilliardProvider.filterOptions.map((f) {
            final isSelected = bp.activeFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _applyFilter(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.neonGreen : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.neonGreen : AppColors.divider,
                    ),
                  ),
                  child: Text(f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BilliardProvider bp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          const Text('Tempat Billiard',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${bp.filteredPlaces.length}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _searchController.clear();
              bp.resetFilters();
            },
            child: const Text('Lihat Semua',
                style: TextStyle(fontSize: 12, color: AppColors.neonGreen)),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.neonGreen),
          SizedBox(height: 16),
          Text(
            'Memuat data dari cloud...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Tempat tidak ditemukan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}