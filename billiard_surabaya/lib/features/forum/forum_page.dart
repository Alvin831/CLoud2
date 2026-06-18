import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/forum_post.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import '../../core/providers/forum_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_page.dart';
import 'forum_detail_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postCtrl = TextEditingController();

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  void _showNewPostSheet(app_auth.AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Buat Post Baru',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Ajak mabar, share info, atau tanya seputar biliar.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _postCtrl,
              maxLines: 4,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tulis sesuatu... contoh: "Ada yang mau mabar di Billiard Planet sore ini?"',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _postCtrl.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Batal',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Consumer<app_auth.AuthProvider>(
                    builder: (_, auth2, __) => ElevatedButton(
                      onPressed: () async {
                        final user = auth2.currentUser;
                        if (user == null) return;
                        final ok = await context.read<ForumProvider>().createPost(
                          userId: user.uid,
                          userName: user.displayName ?? user.email ?? 'Pengguna',
                          userPhoto: user.photoURL,
                          content: _postCtrl.text,
                        );
                        if (ok && ctx.mounted) {
                          _postCtrl.clear();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Posting',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final isLoggedIn = auth.currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isLoggedIn, auth),
            // Post list (real-time)
            Expanded(child: _buildPostList(auth)),
          ],
        ),
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => _showNewPostSheet(auth),
              backgroundColor: AppColors.neonGreen,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Buat Post',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isLoggedIn, app_auth.AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.forum_rounded,
                color: AppColors.neonGreen, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Forum Komunitas',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('Ajak mabar & diskusi biliar',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (!isLoggedIn)
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginPage())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Login',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostList(app_auth.AuthProvider auth) {
    return StreamBuilder<List<ForumPost>>(
      stream: context.read<ForumProvider>().postsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonGreen),
          );
        }
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildPostCard(posts[i], auth),
        );
      },
    );
  }

  Widget _buildPostCard(ForumPost post, app_auth.AuthProvider auth) {
    final currentUid = auth.currentUser?.uid;
    final isLiked = currentUid != null && post.isLikedBy(currentUid);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ForumDetailPage(post: post)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User row
            Row(
              children: [
                _buildAvatar(post.userPhoto, post.userName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        _formatTime(post.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (currentUid == post.userId)
                  GestureDetector(
                    onTap: () => context
                        .read<ForumProvider>()
                        .deletePost(post.id),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.textMuted, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Konten
            Text(post.content,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),

            // Tag tempat
            if (post.placeName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.neonBlue.withValues(alpha: 0.3)),
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
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (currentUid == null) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));
                      return;
                    }
                    context
                        .read<ForumProvider>()
                        .toggleLike(post.id, currentUid);
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: isLiked ? Colors.redAccent : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likeCount}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 4),
                Text('${post.replyCount} balasan',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const Spacer(),
                const Text('Lihat detail →',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.neonGreen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.surfaceVariant,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonGreen),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined,
                color: AppColors.textMuted, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Belum Ada Post',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Jadilah yang pertama mengajak mabar!',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('d MMM, HH:mm').format(dt);
  }
}
