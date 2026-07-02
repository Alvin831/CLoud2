import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String placeId;
  final String placeName;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      placeId: d['place_id'] as String? ?? '',
      placeName: d['place_name'] as String? ?? '',
      userId: d['user_id'] as String? ?? '',
      userName: d['user_name'] as String? ?? 'Pengguna',
      rating: (d['rating'] as num?)?.toDouble() ?? 5.0,
      comment: d['comment'] as String? ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'place_id': placeId,
    'place_name': placeName,
    'user_id': userId,
    'user_name': userName,
    'rating': rating,
    'comment': comment,
    'created_at': Timestamp.fromDate(createdAt),
  };
}
