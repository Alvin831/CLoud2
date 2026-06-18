import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String content;
  final String? placeId;    // opsional — kalau nge-tag tempat tertentu
  final String? placeName;
  final List<String> likes; // list userId yang like
  final int replyCount;
  final DateTime createdAt;

  const ForumPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.content,
    this.placeId,
    this.placeName,
    required this.likes,
    required this.replyCount,
    required this.createdAt,
  });

  bool isLikedBy(String uid) => likes.contains(uid);
  int get likeCount => likes.length;

  factory ForumPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ForumPost(
      id: doc.id,
      userId: d['user_id'] as String? ?? '',
      userName: d['user_name'] as String? ?? 'Pengguna',
      userPhoto: d['user_photo'] as String?,
      content: d['content'] as String? ?? '',
      placeId: d['place_id'] as String?,
      placeName: d['place_name'] as String?,
      likes: List<String>.from(d['likes'] ?? []),
      replyCount: (d['reply_count'] as num?)?.toInt() ?? 0,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'user_name': userName,
    'user_photo': userPhoto,
    'content': content,
    'place_id': placeId,
    'place_name': placeName,
    'likes': likes,
    'reply_count': replyCount,
    'created_at': Timestamp.fromDate(createdAt),
  };
}

class ForumReply {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String content;
  final DateTime createdAt;

  const ForumReply({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.content,
    required this.createdAt,
  });

  factory ForumReply.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ForumReply(
      id: doc.id,
      userId: d['user_id'] as String? ?? '',
      userName: d['user_name'] as String? ?? 'Pengguna',
      userPhoto: d['user_photo'] as String?,
      content: d['content'] as String? ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'user_name': userName,
    'user_photo': userPhoto,
    'content': content,
    'created_at': Timestamp.fromDate(createdAt),
  };
}
