import 'package:cloud_firestore/cloud_firestore.dart';

class BilliardPlace {
  final String id;
  final String name;
  final String shortAddress;
  final String fullAddress;
  final String description;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String imageUrl;
  final String? imagePath; // nama file lokal, e.g. "zuper.jpg"
  final List<String> galleryImages;
  final List<String> galleryImg;
  final bool isOpen;
  final String operatingHours;
  final double pricePerHour;
  final double priceVipPerHour;
  final double latitude;
  final double longitude;
  final List<String> facilities;
  final int tableCount;

  const BilliardPlace({
    required this.id,
    required this.name,
    required this.shortAddress,
    required this.fullAddress,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.imageUrl,
    this.imagePath,
    required this.galleryImages,
    this.galleryImg = const [],
    required this.isOpen,
    required this.operatingHours,
    required this.pricePerHour,
    required this.priceVipPerHour,
    required this.latitude,
    required this.longitude,
    required this.facilities,
    required this.tableCount,
  });

  // ── Factory: konversi Firestore DocumentSnapshot → BilliardPlace ───────────
  factory BilliardPlace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final address = data['address'] as String? ?? 'Surabaya';
    // Potong shortAddress maksimal 40 karakter agar muat di card
    final shortAddr =
        address.length > 40 ? '${address.substring(0, 40)}...' : address;

    return BilliardPlace(
      id: doc.id,
      name: data['name'] as String? ?? 'Tanpa Nama',
      shortAddress: shortAddr,
      fullAddress: address,

      // Field berikut opsional di Firestore — pakai default jika tidak ada
      description: data['description'] as String? ??
          'Tempat billiard terbaik di Surabaya.',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      distanceKm: 0.0, // akan diisi ulang oleh PlaceService.attachDistances()
      imageUrl: data['image_url'] as String? ?? '',
      imagePath: data['imagePath'] as String?,
      galleryImages: List<String>.from(data['galleryImg'] ?? data['gallery_images'] ?? []),
      galleryImg: List<String>.from(data['galleryImg'] ?? data['gallery_images'] ?? []),
      isOpen: data['is_open'] as bool? ?? true,
      operatingHours: data['operating_hours'] as String? ?? '10:00 – 24:00',
      pricePerHour: (data['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      priceVipPerHour: (data['price_vip_per_hour'] as num?)?.toDouble() ??
          (((data['price_per_hour'] as num?)?.toDouble() ?? 0.0) + 20000.0),
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lng'] as num?)?.toDouble() ?? 0.0,
      facilities: List<String>.from(data['facilities'] ?? []),
      tableCount: (data['table_count'] as num?)?.toInt() ?? 0,
    );
  }

  // ── copyWith: dipakai untuk update distanceKm setelah GPS didapat ──────────
  BilliardPlace copyWith({double? distanceKm, List<String>? galleryImg}) {
    return BilliardPlace(
      id: id,
      name: name,
      shortAddress: shortAddress,
      fullAddress: fullAddress,
      description: description,
      rating: rating,
      reviewCount: reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      imageUrl: imageUrl,
      imagePath: imagePath,
      galleryImages: galleryImages,
      galleryImg: galleryImg ?? this.galleryImg,
      isOpen: isOpen,
      operatingHours: operatingHours,
      pricePerHour: pricePerHour,
      priceVipPerHour: priceVipPerHour,
      latitude: latitude,
      longitude: longitude,
      facilities: facilities,
      tableCount: tableCount,
    );
  }

  // ── Getter: Cek otomatis apakah buka berdasarkan jam saat ini ──────────
  bool get isCurrentlyOpen {
    try {
      if (operatingHours.isEmpty || !operatingHours.contains('-')) return isOpen;
      
      // Bersihkan string dari karakter aneh jika ada (misal en-dash)
      final cleanHours = operatingHours.replaceAll('–', '-');
      final parts = cleanHours.split('-');
      if (parts.length != 2) return isOpen;
      
      final openTimeParts = parts[0].trim().split(':');
      final closeTimeParts = parts[1].trim().split(':');
      
      if (openTimeParts.length < 2 || closeTimeParts.length < 2) return isOpen;
      
      final openHour = int.parse(openTimeParts[0]);
      final openMin = int.parse(openTimeParts[1]);
      
      final closeHour = int.parse(closeTimeParts[0]);
      final closeMin = int.parse(closeTimeParts[1]);
      
      final now = DateTime.now();
      final nowMins = now.hour * 60 + now.minute;
      final openMins = openHour * 60 + openMin;
      final closeMins = closeHour * 60 + closeMin;
      
      if (closeMins <= openMins) {
        // Buka lewat tengah malam (misal 11:00 sampai 03:00 besoknya)
        return nowMins >= openMins || nowMins <= closeMins;
      } else {
        // Buka di hari yang sama (misal 10:00 sampai 22:00)
        return nowMins >= openMins && nowMins <= closeMins;
      }
    } catch (e) {
      return isOpen; // Fallback ke manual dari Firebase jika error parsing
    }
  }

  /// Jarak terformat untuk tampilan yang lebih ramah pengguna (contoh: "3,4 km")
  String get formattedDistance =>
      '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
}

