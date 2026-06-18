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
  final bool isOpen;
  final String operatingHours;
  final double pricePerHour;
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
    required this.isOpen,
    required this.operatingHours,
    required this.pricePerHour,
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
      galleryImages: List<String>.from(data['gallery_images'] ?? []),
      isOpen: data['is_open'] as bool? ?? true,
      operatingHours: data['operating_hours'] as String? ?? '10:00 – 24:00',
      pricePerHour: (data['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lng'] as num?)?.toDouble() ?? 0.0,
      facilities: List<String>.from(data['facilities'] ?? []),
      tableCount: (data['table_count'] as num?)?.toInt() ?? 0,
    );
  }

  // ── copyWith: dipakai untuk update distanceKm setelah GPS didapat ──────────
  BilliardPlace copyWith({double? distanceKm}) {
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
      isOpen: isOpen,
      operatingHours: operatingHours,
      pricePerHour: pricePerHour,
      latitude: latitude,
      longitude: longitude,
      facilities: facilities,
      tableCount: tableCount,
    );
  }
}
