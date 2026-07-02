import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/billiard_place.dart';
import '../../core/models/review.dart';
import '../../core/providers/favorite_provider.dart';
import '../../core/providers/billiard_provider.dart';
import '../../core/providers/review_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchReviewsForPlace(widget.place.id);
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
    final p = context.watch<BilliardProvider>().allPlaces.firstWhere(
          (place) => place.id == widget.place.id,
          orElse: () => widget.place,
        );
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
                      _buildCloudinaryGallery(p),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildFacilities(p),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildReviewsSection(p),
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
              imagePath: _selectedImageIndex == 0 ? p.imagePath : null,
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
                        '${p.formattedDistance} dari lokasi Anda',
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

  Widget _buildCloudinaryGallery(BilliardPlace p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Galeri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (p.galleryImg.isEmpty)
          const Text('Belum ada galeri.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: p.galleryImg.length,
              itemBuilder: (context, i) {
                final imageUrl = p.galleryImg[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImagePage(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.neonGreen,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
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

  Widget _buildReviewsSection(BilliardPlace p) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.placeReviews;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ulasan Pengguna',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${p.reviewCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showWriteReviewSheet(context, p),
                  icon: const Icon(Icons.rate_review_rounded, size: 16, color: AppColors.neonGreen),
                  label: const Text(
                    'Tulis Ulasan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviewProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppColors.neonGreen),
                ),
              )
            else if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.star_outline_rounded, color: AppColors.textMuted, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada ulasan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Jadilah yang pertama memberikan ulasan tempat ini!',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: reviews.map((r) => _buildReviewCard(r)).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Review r) {
    final initials = r.userName.isNotEmpty ? r.userName[0].toUpperCase() : 'P';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.neonGreen.withOpacity(0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < r.rating.floor()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.rating,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(r.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.comment,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWriteReviewSheet(BuildContext context, BilliardPlace p) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    double selectedRating = 5.0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stContext, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(stContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Berikan Ulasan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Bagaimana pengalaman Anda?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final starRating = index + 1.0;
                            final isSelected = starRating <= selectedRating;
                            return GestureDetector(
                              onTap: isSubmitting
                                  ? null
                                  : () => setState(() => selectedRating = starRating),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: AppColors.rating,
                                  size: 38,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    maxLength: 250,
                    enabled: !isSubmitting,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Bagikan detail pengalaman Anda tentang meja, pelayanan, atau fasilitas tempat biliar ini...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      fillColor: AppColors.surfaceVariant,
                      filled: true,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.neonGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final comment = commentController.text;
                              setState(() => isSubmitting = true);
                              
                              final reviewProvider = context.read<ReviewProvider>();
                              final billiardProvider = context.read<BilliardProvider>();
                              
                              final success = await reviewProvider.addReview(
                                placeId: p.id,
                                placeName: p.name,
                                userId: user.uid,
                                userName: user.displayName ?? 'Pengguna',
                                rating: selectedRating,
                                comment: comment,
                              );
                              
                              if (success) {
                                await billiardProvider.refresh();
                                if (stContext.mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ulasan Anda berhasil dikirim! Terima kasih.'),
                                      backgroundColor: AppColors.open,
                                    ),
                                  );
                                }
                              } else {
                                setState(() => isSubmitting = false);
                                if (stContext.mounted) {
                                  ScaffoldMessenger.of(stContext).showSnackBar(
                                    SnackBar(
                                      content: Text(reviewProvider.error ?? 'Gagal mengirim ulasan.'),
                                      backgroundColor: AppColors.closed,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kirim Ulasan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.divider, height: 1);
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: AppColors.neonGreen);
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_rounded, color: Colors.white, size: 50);
            },
          ),
        ),
      ),
    );
  }
}
