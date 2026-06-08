import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billiard_place.dart';

class PlaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Ambil semua places dari Firestore ──────────────────────────────────────
  Future<List<BilliardPlace>> fetchPlaces() async {
    final snapshot = await _db.collection('places').get();
    return snapshot.docs
        .map((doc) => BilliardPlace.fromFirestore(doc))
        .toList();
  }

  // ── Hitung jarak (Haversine), hasil dalam km ───────────────────────────────
  double calculateDistance(
    double userLat,
    double userLng,
    double placeLat,
    double placeLng,
  ) {
    const earthRadius = 6371.0;
    final dLat = _toRad(placeLat - userLat);
    final dLng = _toRad(placeLng - userLng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(userLat)) *
            cos(_toRad(placeLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ── Update distanceKm di semua places berdasarkan lokasi GPS user ──────────
  List<BilliardPlace> attachDistances(
    List<BilliardPlace> places,
    double userLat,
    double userLng,
  ) {
    return places.map((p) {
      final dist = calculateDistance(userLat, userLng, p.latitude, p.longitude);
      return p.copyWith(distanceKm: dist);
    }).toList();
  }
}