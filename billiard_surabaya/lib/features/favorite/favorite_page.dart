import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/favorite_provider.dart';
import '../../core/theme/app_theme.dart';
import '../detail/detail_page.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Favorit',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tempat billiard yang kamu simpan',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Consumer<FavoriteProvider>(
              builder: (_, favProvider, __) {
                final favorites = favProvider.favorites;

                if (favorites.isEmpty) {
                  return Expanded(child: _buildEmptyState());
                }

                return Expanded(
                  child: Column(
                    children: [
                      // Count badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${favorites.length} tempat tersimpan',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: favorites.length,
                          itemBuilder: (_, i) {
                            final p = favorites[i];
                            return Dismissible(
                              key: ValueKey(p.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.closed.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: AppColors.closed, size: 24),
                              ),
                              onDismissed: (_) => favProvider.toggle(p),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DetailPage(place: p)),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Row(
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          p.imageUrl,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 72,
                                            height: 72,
                                            color: AppColors.surfaceVariant,
                                            child: const Icon(Icons.image_not_supported, color: AppColors.textMuted),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: AppColors.rating, size: 13),
                                                const SizedBox(width: 3),
                                                Text(
                                                  p.rating.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 12),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: Text(
                                                    p.shortAddress,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (p.isOpen ? AppColors.open : AppColors.closed).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.isOpen ? 'Buka' : 'Tutup',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: p.isOpen ? AppColors.open : AppColors.closed,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_outline_rounded, color: AppColors.textMuted, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Favorit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simpan tempat billiard favoritmu\nagar mudah ditemukan kembali',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
