import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/reservation.dart';
import '../../core/providers/reservation_provider.dart';
import '../../core/theme/app_theme.dart';
import 'reservation_history_page.dart';

class ReceiptPage extends StatelessWidget {
  final String reservationId;
  const ReceiptPage({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resi Reservasi'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Selesai',
                style: TextStyle(color: AppColors.neonGreen)),
          ),
        ],
      ),
      body: FutureBuilder<Reservation?>(
        future: context
            .read<ReservationProvider>()
            .getReservationById(reservationId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.neonGreen));
          }
          final r = snap.data;
          if (r == null) {
            return const Center(
                child: Text('Reservasi tidak ditemukan.',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSuccessBanner(),
                const SizedBox(height: 24),
                _buildReceipt(r),
                const SizedBox(height: 24),
                _buildNote(),
                const SizedBox(height: 16),
                _buildHomeButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.neonGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.black, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reservasi Dikonfirmasi!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tunjukkan resi ini saat tiba di tempat.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt(Reservation r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header resi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RESI RESERVASI',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.status == 'confirmed'
                      ? AppColors.neonGreen.withValues(alpha: 0.15)
                      : AppColors.closed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: r.status == 'confirmed'
                          ? AppColors.neonGreen
                          : AppColors.closed),
                ),
                child: Text(
                  r.status == 'confirmed' ? 'Dikonfirmasi' : 'Dibatalkan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: r.status == 'confirmed'
                        ? AppColors.neonGreen
                        : AppColors.closed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kode resi — highlight utama
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Kode Reservasi',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  r.receiptCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonGreen,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Detail
          _receiptRow(Icons.sports_bar_rounded, 'Tempat', r.placeName),
          _receiptRow(Icons.location_on_rounded, 'Alamat', r.placeAddress),
          _receiptRow(
            Icons.calendar_today_rounded,
            'Tanggal',
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(r.date),
          ),
          _receiptRow(Icons.access_time_rounded, 'Waktu', r.timeSlot),
          _receiptRow(Icons.timer_rounded, 'Durasi', '${r.durationHours} jam'),
          _receiptRow(Icons.weekend_rounded, 'Tipe Meja', r.tableType),
          _receiptRow(Icons.person_rounded, 'Atas Nama', r.userName),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Biaya',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(r.totalPrice)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Footer
          Center(
            child: Text(
              'Dipesan pada ${DateFormat('d MMM yyyy, HH:mm').format(r.createdAt)}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.neonBlue, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pembayaran dilakukan langsung di tempat. Tunjukkan kode reservasi ini kepada kasir saat tiba.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text('Kembali ke Beranda',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReservationHistoryPage()),
              );
            },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Lihat Semua Riwayat',
                style: TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
