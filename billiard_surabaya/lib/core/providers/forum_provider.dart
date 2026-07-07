yimport 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/forum_post.dart';

class ForumProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isPosting = false;
  String? _error;

  bool get isPosting => _isPosting;
  String? get error => _error;

  // ── Stream semua post (real-time) ─────────────────────────────────────────
  Stream<List<ForumPost>> postsStream() {
    return _db
        .collection('forum_posts')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ForumPost.fromFirestore(d)).toList());
  }

  // ── Stream replies untuk 1 post (real-time) ───────────────────────────────
  Stream<List<ForumReply>> repliesStream(String postId) {
    return _db
        .collection('forum_posts')
        .doc(postId)
        .collection('replies')
        .orderBy('created_at')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ForumReply.fromFirestore(d)).toList());
  }

  // ── Buat post baru ────────────────────────────────────────────────────────
  Future<bool> createPost({
    required String userId,
    required String userName,
    String? userPhoto,
    required String content,
    String? placeId,
    String? placeName,
  }) async {
    if (content.trim().isEmpty) return false;
    _isPosting = true;
    _error = null;
    notifyListeners();

    try {
      final post = ForumPost(
        id: '',
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        content: content.trim(),
        placeId: placeId,
        placeName: placeName,
        likes: [],
        replyCount: 0,
        createdAt: DateTime.now(),
      );
      await _db.collection('forum_posts').add(post.toMap());
      _isPosting = false;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Gagal membuat post.';
      _isPosting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Toggle like ───────────────────────────────────────────────────────────
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final ref = _db.collection('forum_posts').doc(postId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final likes = List<String>.from(
          (snap.data() as Map<String, dynamic>)['likes'] ?? []);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      await ref.update({'likes': likes});
    } catch (_) {}
  }

  // ── Kirim reply ───────────────────────────────────────────────────────────
  Future<bool> sendReply({
    required String postId,
    required String userId,
    required String userName,
    String? userPhoto,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;
    try {
      final reply = ForumReply(
        id: '',
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        content: content.trim(),
        createdAt: DateTime.now(),
      );
      final batch = _db.batch();
      // Tambah reply
      final replyRef = _db
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .doc();
      batch.set(replyRef, reply.toMap());
      // Increment reply_count
      batch.update(
        _db.collection('forum_posts').doc(postId),
        {'reply_count': FieldValue.increment(1)},
      );
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Hapus post (hanya milik sendiri) ─────────────────────────────────────
  Future<void> deletePost(String postId) async {
    try {
      await _db.collection('forum_posts').doc(postId).delete();
    } catch (_) {}
  }
}
