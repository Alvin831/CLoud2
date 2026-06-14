import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import '../../core/providers/favorite_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildProfileHeader(context),
              const SizedBox(height: 24),
              _buildStatsRow(context),
              const SizedBox(height: 24),
              _buildMenuSection('Akun', [
                _MenuItemData(Icons.person_outline_rounded, 'Edit Profil', null),
                _MenuItemData(Icons.card_membership_rounded, 'Keanggotaan Premium', AppColors.neonGreen),
                _MenuItemData(Icons.history_rounded, 'Riwayat Kunjungan', null),
              ]),
              const SizedBox(height: 16),
              _buildMenuSection('Pengaturan', [
                _MenuItemData(Icons.notifications_outlined, 'Notifikasi', null),
                _MenuItemData(Icons.location_on_outlined, 'Lokasi', null),
                _MenuItemData(Icons.language_rounded, 'Bahasa', null),
              ]),
              const SizedBox(height: 16),
              _buildMenuSection('Lainnya', [
                _MenuItemData(Icons.help_outline_rounded, 'Pusat Bantuan', null),
                _MenuItemData(Icons.star_outline_rounded, 'Beri Rating Aplikasi', null),
                _MenuItemData(Icons.info_outline_rounded, 'Tentang Aplikasi', null),
              ]),
              const SizedBox(height: 20),
              _buildLogoutButton(context),
              const SizedBox(height: 20),
              const Text(
                'v1.0.0 · Billiard Surabaya',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        final displayName = user?.displayName ?? 'Pengguna';
        final email = user?.email ?? '';
        final photoUrl = user?.photoURL;

        return Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonGreen, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonGreen,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        color: AppColors.neonGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.black, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.neonGreen, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    user?.emailVerified == true ? 'Member Terverifikasi' : 'Member Regular',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favorites, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              _buildStat('0', 'Kunjungan'),
              _buildStatDivider(),
              _buildStat('${favorites.favorites.length}', 'Favorit'),
              _buildStatDivider(),
              _buildStat('0', 'Ulasan'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.neonGreen),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Widget _buildMenuSection(String title, List<_MenuItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (item.accentColor ?? AppColors.textMuted).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon,
                          color: item.accentColor ?? AppColors.textSecondary,
                          size: 18),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.accentColor ?? AppColors.textPrimary,
                        fontWeight: item.accentColor != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 18),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    dense: true,
                    onTap: () {},
                  ),
                  if (i < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading
                ? null
                : () => _confirmLogout(context, auth),
            icon: auth.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.closed),
                  )
                : const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.closed),
            label: const Text('Keluar',
                style: TextStyle(
                    color: AppColors.closed, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.closed),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      },
    );
  }

  /// Tampilkan dialog konfirmasi sebelum logout
  void _confirmLogout(
      BuildContext context, app_auth.AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Kamu akan keluar dari akun ini.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
              // AuthGate di main.dart akan otomatis redirect ke LoginPage
            },
            child: const Text('Keluar',
                style: TextStyle(
                    color: AppColors.closed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final Color? accentColor;
  const _MenuItemData(this.icon, this.title, this.accentColor);
}
