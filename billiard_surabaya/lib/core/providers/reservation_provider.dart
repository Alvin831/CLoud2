import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reservation.dart';

class ReservationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Reservation> _myReservations = [];
  bool _isLoading = false;
  String? _error;

  List<Reservation> get myReservations => List.unmodifiable(_myReservations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Buat Reservasi ─────────────────────────────────────────────────────────
  Future<String?> createReservation({
    required String userId,
    required String userName,
    required String placeId,
    required String placeName,
    required String placeAddress,
    required DateTime date,
    required String timeSlot,
    required int tableNumber,
    required String tableType,
    required int durationHours,
    required double pricePerHour,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final totalPrice = pricePerHour * durationHours;
      final receiptCode = _generateReceiptCode();

      final reservation = Reservation(
        id: '',
        userId: userId,
        userName: userName,
        placeId: placeId,
        placeName: placeName,
        placeAddress: placeAddress,
        date: date,
        timeSlot: timeSlot,
        tableNumber: tableNumber,
        tableType: tableType,
        durationHours: durationHours,
        totalPrice: totalPrice,
        status: 'confirmed',
        receiptCode: receiptCode,
        createdAt: DateTime.now(),
      );

      final ref = await _db
          .collection('reservations')
          .add(reservation.toMap());

      // Reload list
      await fetchMyReservations(userId);

      _isLoading = false;
      notifyListeners();
      return ref.id; // return id untuk navigasi ke halaman resi
    } catch (e) {
      _error = 'Gagal membuat reservasi. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── Ambil Reservasi User ───────────────────────────────────────────────────
  Future<void> fetchMyReservations(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('reservations')
          .where('user_id', isEqualTo: userId)
          .get();
      final list = snap.docs
          .map((doc) => Reservation.fromFirestore(doc))
          .toList();
      // Urutkan secara in-memory berdasarkan created_at descending (terbaru di atas)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _myReservations = list;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching reservations: $e');
      }
      _myReservations = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Ambil reservasi by ID (untuk halaman resi) ─────────────────────────────
  Future<Reservation?> getReservationById(String id) async {
    try {
      final doc = await _db.collection('reservations').doc(id).get();
      if (doc.exists) return Reservation.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting reservation by id: $e');
      }
    }
    return null;
  }

  // ── Batalkan Reservasi ─────────────────────────────────────────────────────
  Future<void> cancelReservation(String id, String userId) async {
    try {
      await _db.collection('reservations').doc(id).update({'status': 'cancelled'});
      await fetchMyReservations(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling reservation: $e');
      }
    }
  }

  // ── Generate kode resi unik ────────────────────────────────────────────────
  String _generateReceiptCode() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = (now.millisecondsSinceEpoch % 9000 + 1000).toString();
    return 'BLS-$date-$rand';
  }
}
