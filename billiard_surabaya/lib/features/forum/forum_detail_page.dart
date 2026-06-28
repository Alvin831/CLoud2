import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/forum_post.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import '../../core/providers/forum_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_page.dart';

class ForumDetailPage extends StatefulWidget {
  final ForumPost post;
  const ForumDetailPage({super.key, required this.post});

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  final TextEditingController _replyCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _replyCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendReply(app_auth.AuthProvider auth) async {
    final user = auth.currentUser;
    if (user == null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (_replyCtrl.text.trim().isEmpty) return;

    final ok = await context.read<ForumProvider>().sendReply(
      postId: widget.post.id,
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Pengguna',
      userPhoto: user.photoURL,
      content: _replyCtrl.text,
    );
    if (ok) {
      _replyCtrl.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final currentUid = auth.currentUser?.uid;
    final post = widget.post;
    final isLiked = currentUid != null && post.isLikedBy(currentUid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diskusi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Konten post + replies
          Expanded(
            child: StreamBuilder<List<ForumReply>>(
              stream:
                  context.read<ForumProvider>().repliesStream(post.id),
              builder: (context, snap) {
                final replies = snap.data ?? [];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Post utama
                    _buildOriginalPost(post, isLiked, currentUid, auth),
                    const SizedBox(height: 16),

                    // Header replies
                    if (replies.isNotEmpty) ...[
                      Text(
                        '${replies.length} Balasan',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Replies
                    ...replies.map((r) => _buildReplyCard(r)),
                  ],
                );
              },
            ),
          ),

          // Input reply
          _buildReplyInput(auth),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(
    ForumPost post,
    bool isLiked,
    String? currentUid,
    app_auth.AuthProvider auth,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              _buildAvatar(post.userPhoto, post.userName, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                      DateFormat('d MMM yyyy, HH:mm').format(post.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Konten
          Text(post.content,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6)),

          // Tag tempat
          if (post.placeName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.neonBlue, size: 12),
                  const SizedBox(width: 4),
                  Text(post.placeName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.neonBlue)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // Like
          GestureDetector(
            onTap: () {
              if (currentUid == null) return;
              context.read<ForumProvider>().toggleLike(post.id, currentUid);
            },
            child: Row(
              children: [
                Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: isLiked ? Colors.redAccent : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.likeCount} Suka',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(ForumReply reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(reply.userPhoto, reply.userName, size: 16),
              const SizedBox(width: 8),
              Text(reply.userName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text(
                _formatTime(reply.createdAt),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(reply.content,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildReplyInput(app_auth.AuthProvider auth) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyCtrl,
              focusNode: _focusNode,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: auth.currentUser != null
                    ? 'Tulis balasan...'
                    : 'Login untuk membalas...',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onTap: () {
                if (auth.currentUser == null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPage()));
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendReply(auth),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.neonGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String name, {required double size}) {
    return CircleAvatar(
      radius: size,
      backgroundColor: AppColors.surfaceVariant,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                  fontSize: size * 0.7,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonGreen),
            )
          : null,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return DateFormat('d MMM').format(dt);
  }
}
