import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/reservation.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import '../../core/providers/reservation_provider.dart';
import '../../core/theme/app_theme.dart';
import 'receipt_page.dart';

class ReservationHistoryPage extends StatefulWidget {
  const ReservationHistoryPage({super.key});

  @override
  State<ReservationHistoryPage> createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Fetch saat halaman pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<app_auth.AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<ReservationProvider>().fetchMyReservations(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Riwayat Reservasi'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.neonGreen,
            labelColor: AppColors.neonGreen,
            unselectedLabelColor: AppColors.textMuted,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.divider,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Selesai & Batal'),
            ],
          ),
        ),
        body: Consumer<ReservationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.neonGreen),
              );
            }

            final allReservations = provider.myReservations;
            final activeReservations = allReservations
                .where((r) => r.status == 'confirmed' && !r.isPast)
                .toList();
            final pastReservations = allReservations
                .where((r) => r.status == 'cancelled' || r.isPast)
                .toList();

            return TabBarView(
              children: [
                _buildReservationList(context, activeReservations, provider, 'aktif'),
                _buildReservationList(context, pastReservations, provider, 'riwayat'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReservationList(
    BuildContext context,
    List<Reservation> reservations,
    ReservationProvider provider,
    String type,
  ) {
    if (reservations.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      color: AppColors.neonGreen,
      backgroundColor: AppColors.card,
      onRefresh: () async {
        final uid =
            context.read<app_auth.AuthProvider>().currentUser?.uid;
        if (uid != null) {
          await provider.fetchMyReservations(uid);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _buildReservationCard(context, reservations[i], provider),
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    Reservation r,
    ReservationProvider provider,
  ) {
    final isCancelled = r.status == 'cancelled';
    final isPast = r.isPast;

    final Color statusColor;
    final String statusText;
    if (isCancelled) {
      statusColor = AppColors.closed;
      statusText = 'Dibatalkan';
    } else if (isPast) {
      statusColor = AppColors.neonBlue;
      statusText = 'Selesai';
    } else {
      statusColor = AppColors.neonGreen;
      statusText = 'Dikonfirmasi';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header strip warna status
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tempat + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.placeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Info grid
                Row(
                  children: [
                    _infoChip(
                      Icons.calendar_today_rounded,
                      DateFormat('d MMM yyyy', 'id_ID').format(r.date),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(Icons.access_time_rounded, r.timeSlot),
                    const SizedBox(width: 8),
                    _infoChip(Icons.timer_rounded, '${r.durationHours} jam'),
                  ],
                ),
                const SizedBox(height: 12),

                // Kode resi + total
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kode Reservasi',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            r.receiptCode,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonGreen,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(r.totalPrice)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    // Lihat resi
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReceiptPage(reservationId: r.id, fromHistory: true),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded,
                            size: 16),
                        label: const Text('Lihat Resi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.neonGreen,
                          side:
                              const BorderSide(color: AppColors.neonGreen),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),

                    // Batalkan (hanya kalau confirmed & belum lewat)
                    if (r.status == 'confirmed' && !isPast) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _confirmCancel(context, r, provider),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Batalkan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.closed,
                            side:
                                const BorderSide(color: AppColors.closed),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    Reservation r,
    ReservationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Reservasi?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${r.placeName} · ${DateFormat('d MMM yyyy').format(r.date)}\n${r.timeSlot}',
          style:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = context
                  .read<app_auth.AuthProvider>()
                  .currentUser
                  ?.uid;
              if (uid != null) {
                await provider.cancelReservation(r.id, uid);
              }
            },
            child: const Text('Batalkan',
                style: TextStyle(
                    color: AppColors.closed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final isAktif = type == 'aktif';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAktif ? Icons.calendar_today_outlined : Icons.history_rounded,
              color: AppColors.textMuted,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isAktif ? 'Belum Ada Reservasi Aktif' : 'Belum Ada Riwayat',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isAktif
                  ? 'Kamu tidak memiliki reservasi aktif saat ini. Yuk buat reservasi baru!'
                  : 'Semua riwayat reservasi selesai atau batal akan muncul di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
