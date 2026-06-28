import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final DateTime date;
  final String timeSlot;      // e.g. "14:00 – 16:00"
  final int tableNumber;
  final int durationHours;
  final double totalPrice;
  final String status;        // 'confirmed' | 'cancelled'
  final String receiptCode;   // kode unik resi, e.g. "BLS-20240617-001"
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.date,
    required this.timeSlot,
    required this.tableNumber,
    required this.durationHours,
    required this.totalPrice,
    required this.status,
    required this.receiptCode,
    required this.createdAt,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      userId: d['user_id'] as String? ?? '',
      userName: d['user_name'] as String? ?? 'Pengguna',
      placeId: d['place_id'] as String? ?? '',
      placeName: d['place_name'] as String? ?? '',
      placeAddress: d['place_address'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: d['time_slot'] as String? ?? '',
      tableNumber: (d['table_number'] as num?)?.toInt() ?? 1,
      durationHours: (d['duration_hours'] as num?)?.toInt() ?? 1,
      totalPrice: (d['total_price'] as num?)?.toDouble() ?? 0,
      status: d['status'] as String? ?? 'confirmed',
      receiptCode: d['receipt_code'] as String? ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'user_name': userName,
    'place_id': placeId,
    'place_name': placeName,
    'place_address': placeAddress,
    'date': Timestamp.fromDate(date),
    'time_slot': timeSlot,
    'table_number': tableNumber,
    'duration_hours': durationHours,
    'total_price': totalPrice,
    'status': status,
    'receipt_code': receiptCode,
    'created_at': Timestamp.fromDate(createdAt),
  };
}
