import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Review> _placeReviews = [];
  List<Review> _userReviews = [];
  bool _isLoading = false;
  String? _error;

  List<Review> get placeReviews => List.unmodifiable(_placeReviews);
  List<Review> get userReviews => List.unmodifiable(_userReviews);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Ambil Ulasan untuk 1 Tempat (In-Memory Sort) ───────────────────────────
  Future<void> fetchReviewsForPlace(String placeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('reviews')
          .where('place_id', isEqualTo: placeId)
          .get();

      final list = snap.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();

      // Urutkan in-memory (terbaru di atas)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _placeReviews = list;
    } catch (e) {
      if (kDebugMode) {
        print('[ReviewProvider] fetchReviewsForPlace error: $e');
      }
      _error = 'Gagal memuat ulasan.';
      _placeReviews = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Ambil Ulasan yang Ditulis 1 User (In-Memory Sort) ──────────────────────
  Future<void> fetchReviewsForUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('reviews')
          .where('user_id', isEqualTo: userId)
          .get();

      final list = snap.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();

      // Urutkan in-memory (terbaru di atas)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _userReviews = list;
    } catch (e) {
      if (kDebugMode) {
        print('[ReviewProvider] fetchReviewsForUser error: $e');
      }
      _error = 'Gagal memuat ulasan Anda.';
      _userReviews = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Tambah Ulasan Baru (dengan Transaksi Firestore) ────────────────────────
  Future<bool> addReview({
    required String placeId,
    required String placeName,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reviewDocRef = _db.collection('reviews').doc();
      final placeDocRef = _db.collection('places').doc(placeId);

      final newReview = Review(
        id: '',
        placeId: placeId,
        placeName: placeName,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );

      // Gunakan transaksi agar penambahan ulasan dan kalkulasi rating rata-rata tempat berjalan atomic
      // Penting: Firestore mewajibkan seluruh operasi baca (READ) dilakukan SEBELUM operasi tulis (WRITE) di dalam transaksi.
      await _db.runTransaction((transaction) async {
        // 1. BACA DATA TERLEBIH DAHULU (READ)
        final placeSnapshot = await transaction.get(placeDocRef);
        
        double currentRating = 0.0;
        int currentReviewCount = 0;

        if (placeSnapshot.exists) {
          final placeData = placeSnapshot.data() as Map<String, dynamic>;
          currentRating = (placeData['rating'] as num?)?.toDouble() ?? 0.0;
          currentReviewCount = (placeData['review_count'] as num?)?.toInt() ?? 0;
        }

        // 2. KALKULASI RATING BARU
        final newReviewCount = currentReviewCount + 1;
        final newRating = ((currentRating * currentReviewCount) + rating) / newReviewCount;
        final double roundedRating = double.parse(newRating.toStringAsFixed(1));

        // 3. TULIS DATA (WRITE)
        transaction.set(reviewDocRef, newReview.toMap());
        
        if (placeSnapshot.exists) {
          transaction.update(placeDocRef, {
            'rating': roundedRating,
            'review_count': newReviewCount,
          });
        }
      });

      // 5. Refresh data lokal ulasan
      await fetchReviewsForPlace(placeId);
      await fetchReviewsForUser(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[ReviewProvider] addReview error: $e');
      }
      _error = 'Gagal mengirim ulasan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset data ulasan saat logout
  void clearLocal() {
    _placeReviews = [];
    _userReviews = [];
    _error = null;
    notifyListeners();
  }
}
