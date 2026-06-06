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
    required this.galleryImages,
    required this.isOpen,
    required this.operatingHours,
    required this.pricePerHour,
    required this.latitude,
    required this.longitude,
    required this.facilities,
    required this.tableCount,
  });
}
