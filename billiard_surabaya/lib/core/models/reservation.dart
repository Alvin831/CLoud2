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
  final String tableType;     // "Reguler" atau "VIP"
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
    required this.tableType,
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
      tableType: d['table_type'] as String? ?? 'Reguler',
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
    'table_type': tableType,
    'duration_hours': durationHours,
    'total_price': totalPrice,
    'status': status,
    'receipt_code': receiptCode,
    'created_at': Timestamp.fromDate(createdAt),
  };

  /// Cek apakah reservasi ini sudah lewat waktunya
  bool get isPast {
    try {
      final parts = timeSlot.split('–');
      if (parts.length == 2) {
        final endPart = parts[1].trim(); // e.g. "16:00"
        final hourStr = endPart.split(':')[0]; // "16"
        final endHour = int.parse(hourStr);
        final endDateTime = DateTime(date.year, date.month, date.day, endHour);
        return endDateTime.isBefore(DateTime.now());
      }
    } catch (_) {}
    // Fallback: cek berdasarkan tanggal saja
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayDate);
  }
}
