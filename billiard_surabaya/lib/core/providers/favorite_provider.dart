import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/billiard_place.dart';

/// FavoriteProvider: menyimpan favorit per user di Firestore.
/// Path: users/{uid}/favorites/{placeId}
///
/// Saat user login → loadFavorites() → ambil dari Firestore.
/// Saat toggle → simpan/hapus di Firestore + update lokal.
/// Saat logout → clearLocal().
class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<BilliardPlace> _favorites = [];
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;

  List<BilliardPlace> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  /// Cek apakah tempat sudah difavoritkan (cepat — pakai Set)
  bool isFavorite(String id) => _favoriteIds.contains(id);

  /// User ID saat ini. Null jika belum login.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Load favorites dari Firestore ─────────────────────────────────────────
  /// Panggil ini setiap kali user login atau app pertama kali dibuka.
  Future<void> loadFavorites() async {
    final uid = _uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .orderBy('savedAt', descending: true)
          .get();

      _favorites.clear();
      _favoriteIds.clear();

      for (final doc in snapshot.docs) {
        final place = BilliardPlace.fromFirestore(doc);
        _favorites.add(place);
        _favoriteIds.add(place.id);
      }
    } catch (e) {
      debugPrint('[FavoriteProvider] loadFavorites error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Toggle favorit (simpan / hapus) ───────────────────────────────────────
  Future<void> toggle(BilliardPlace place) async {
    final uid = _uid;
    if (uid == null) return; // Harus login dulu

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(place.id);

    if (isFavorite(place.id)) {
      // ── Hapus dari favorit ────────────────────────────────────────────────
      _favorites.removeWhere((p) => p.id == place.id);
      _favoriteIds.remove(place.id);
      notifyListeners();

      try {
        await docRef.delete();
      } catch (e) {
        // Rollback jika gagal
        _favorites.add(place);
        _favoriteIds.add(place.id);
        notifyListeners();
        debugPrint('[FavoriteProvider] delete error: $e');
      }
    } else {
      // ── Tambah ke favorit ─────────────────────────────────────────────────
      _favorites.insert(0, place); // Terbaru di atas
      _favoriteIds.add(place.id);
      notifyListeners();

      try {
        await docRef.set({
          // Simpan data tempat supaya bisa ditampilkan tanpa re-fetch
          'name': place.name,
          'address': place.fullAddress,
          'description': place.description,
          'rating': place.rating,
          'review_count': place.reviewCount,
          'image_url': place.imageUrl,
          'imagePath': place.imagePath,
          'gallery_images': place.galleryImages,
          'galleryImg': place.galleryImages,
          'is_open': place.isOpen,
          'operating_hours': place.operatingHours,
          'price_per_hour': place.pricePerHour,
          'lat': place.latitude,
          'lng': place.longitude,
          'facilities': place.facilities,
          'table_count': place.tableCount,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Rollback jika gagal
        _favorites.removeWhere((p) => p.id == place.id);
        _favoriteIds.remove(place.id);
        notifyListeners();
        debugPrint('[FavoriteProvider] save error: $e');
      }
    }
  }

  // ── Clear lokal (saat logout) ─────────────────────────────────────────────
  void clearLocal() {
    _favorites.clear();
    _favoriteIds.clear();
    notifyListeners();
  }
}
