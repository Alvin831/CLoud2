class BilliardPlace {
  final String id;
  final String name;
  final String address;
  final String shortAddress; // Dibutuhkan oleh fitur Search di HomePage
  final double rating;
  final double lat;
  final double lng;
  final int categoryId;
  
  // Dua variabel ini wajib ada karena UI temanmu memanggilnya
  final double distanceKm;
  final bool isOpen;

  BilliardPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.shortAddress,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.categoryId,
    required this.distanceKm,
    required this.isOpen,
  });

  // Fungsi Penerjemah dari Firebase ke format Flutter
  factory BilliardPlace.fromFirestore(Map<String, dynamic> json, String id) {
    return BilliardPlace(
      id: id,
      name: json['name'] ?? 'Tanpa Nama',
      address: json['address'] ?? 'Tanpa Alamat',
      
      // Karena Firebase-mu tidak punya 'shortAddress', kita isi saja menggunakan data 'address'
      shortAddress: json['address'] ?? 'Tanpa Alamat', 
      
      // Pakai 'num?' agar aman meskipun di Firebase ratingnya kamu ketik angka bulat seperti 4 (int)
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      
      // Koordinat & Kategori
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      
      // KARENA 2 DATA INI TIDAK ADA DI FIREBASE, kita kasih nilai default (palsu sementara)
      // agar tampilan UI kartu di aplikasi tidak mogok/crash.
      distanceKm: 0.0, // Anggap jaraknya 0 km semua untuk sementara
      isOpen: true,    // Anggap tempat biliarnya selalu buka
    );
  }
}