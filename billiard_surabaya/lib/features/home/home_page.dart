import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/data/dummy_data.dart';
import '../../core/models/billiard_place.dart';
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
  String _selectedFilter = 'Semua';
  List<BilliardPlace> _filtered = dummyPlaces;

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

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Terdekat':
          _filtered = List.from(dummyPlaces)..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          break;
        case 'Rating':
          _filtered = List.from(dummyPlaces)..sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Buka Sekarang':
          _filtered = dummyPlaces.where((p) => p.isOpen).toList();
          break;
        default:
          _filtered = dummyPlaces;
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = dummyPlaces
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.shortAddress.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverToBoxAdapter(child: _buildAppBar()),
            // Search
            SliverToBoxAdapter(child: _buildSearchBar()),
            // Banner
            SliverToBoxAdapter(child: _buildBannerSection()),
            // Filter chips
            SliverToBoxAdapter(child: _buildFilterChips()),
            // Section header
            SliverToBoxAdapter(child: _buildSectionHeader()),
            // Place list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => PlaceCard(
                    place: _filtered[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailPage(place: _filtered[i])),
                    ),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.neonGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_bar_rounded, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Billiard Surabaya',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.neonGreen, size: 12),
                  const SizedBox(width: 2),
                  const Text(
                    'Surabaya, Jawa Timur',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 26),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari tempat billiard...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.black, size: 18),
          ),
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
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle'] as String,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Selengkapnya →',
                              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(banner['icon'] as IconData, color: Colors.white.withOpacity(0.3), size: 64),
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isSelected = _selectedFilter == f;
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
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          const Text(
            'Tempat Billiard',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_filtered.length}',
              style: const TextStyle(fontSize: 11, color: AppColors.neonGreen, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.neonGreen)),
        ],
      ),
    );
  }
}
