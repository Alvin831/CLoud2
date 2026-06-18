import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget gambar tempat billiard.
/// Prioritas: imagePath (assets lokal) → imageUrl (network) → fallback icon.
class PlaceImage extends StatelessWidget {
  final String? imagePath; // e.g. "zuper.jpg" → assets/images/zuper.jpg
  final String imageUrl;   // fallback URL
  final double height;
  final BoxFit fit;

  const PlaceImage({
    super.key,
    required this.imagePath,
    required this.imageUrl,
    this.height = 160,
    this.fit = BoxFit.cover,
  });

  Widget _fallback() => Container(
        height: height,
        width: double.infinity,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 48),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Pakai asset lokal jika imagePath tersedia dan tidak kosong
    final path = imagePath?.trim();
    if (path != null && path.isNotEmpty) {
      return Image.asset(
        'assets/images/$path',
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    // Fallback ke network URL
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }
}
