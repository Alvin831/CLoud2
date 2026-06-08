import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/data/place_service.dart';
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
  final PlaceService _placeService = PlaceService();

  int _bannerIndex = 0;
  String _selectedFilter = 'Semua';

  // ─── State Firebase (menggantikan dummyPlaces) ───────────────────────────
  List<BilliardPlace> _allPlaces = [];
  List<BilliardPlace> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;

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
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data Fetching ────────────────────────────────────────────────────────
  Future<void> _loadPlaces() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final places = await _placeService.fetchPlaces();

      setState(() {
        _allPlaces = places;
        _filtered = places;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data Firebase: ${e.message}';
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Koneksi internet terputus, gagal memuat data cloud.';
      });
    }
  }

  // ─── Filter & Search ──────────────────────────────────────────────────────
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Terdekat':
          _filtered = List.from(_allPlaces)
            ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          break;
        case 'Rating':
          _filtered = List.from(_allPlaces)
            ..sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Buka Sekarang':
          _filtered = _allPlaces.where((p) => p.isOpen).toList();
          break;
        default:
          _filtered = _allPlaces;
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _allPlaces;
        return;
      }
      _filtered = _allPlaces
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.shortAddress.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildBannerSection()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: _buildSectionHeader()),

            // ── Kondisi: Loading / Error / Data ──────────────────────────
            if (_isLoading)
              const SliverToBoxAdapter(child: _LoadingState())
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: _ErrorState(
                  message: _errorMessage!,
                  onRetry: _loadPlaces,
                ),
              )
            else if (_filtered.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => PlaceCard(
                      place: _filtered[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPage(place: _filtered[i]),
                        ),
                      ),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ─── Widgets (tidak ada perubahan dari versi temanmu) ─────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Row(
                children: const [
                  Icon(Icons.location_on_rounded, color: AppColors.neonGreen, size: 12),
                  SizedBox(width: 2),
                  Text(
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
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 26),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.neonGreen, shape: BoxShape.circle),
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
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonGreen
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.neonGreen : AppColors.divider,
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
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
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
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = 'Semua';
                _filtered = _allPlaces;
                _searchController.clear();
              });
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