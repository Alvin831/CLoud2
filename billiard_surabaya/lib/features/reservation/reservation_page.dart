import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/billiard_place.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import '../../core/providers/reservation_provider.dart';
import '../../core/theme/app_theme.dart';
import 'receipt_page.dart';

class ReservationPage extends StatefulWidget {
  final BilliardPlace place;
  const ReservationPage({super.key, required this.place});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _startHour = 10;
  int _durationHours = 1;
  bool _isVip = false;

  static const int _minHour = 8;
  static const int _maxStartHour = 22;

  int get _endHour => _startHour + _durationHours;

  String get _timeSlotLabel =>
      '${_startHour.toString().padLeft(2, '0')}:00 – '
      '${_endHour.toString().padLeft(2, '0')}:00';

  double get _currentPrice => _isVip ? widget.place.priceVipPerHour : widget.place.pricePerHour;
  double get _totalPrice => _currentPrice * _durationHours;
  int get _maxDuration => 24 - _startHour;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonGreen,
            onPrimary: Colors.black,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirm() async {
    final auth = context.read<app_auth.AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final provider = context.read<ReservationProvider>();
    final id = await provider.createReservation(
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Pengguna',
      placeId: widget.place.id,
      placeName: widget.place.name,
      placeAddress: widget.place.fullAddress,
      date: _selectedDate,
      timeSlot: _timeSlotLabel,
      tableNumber: 0,
      tableType: _isVip ? 'VIP' : 'Reguler',
      durationHours: _durationHours,
      pricePerHour: _currentPrice,
    );

    if (!mounted) return;
    if (id != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReceiptPage(reservationId: id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal membuat reservasi.'),
          backgroundColor: AppColors.closed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reservasi Meja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceCard(place),
            const SizedBox(height: 24),

            _buildSectionTitle('Pilih Tanggal'),
            const SizedBox(height: 10),
            _buildDatePicker(),
            const SizedBox(height: 24),

            _buildSectionTitle('Tipe Meja'),
            const SizedBox(height: 10),
            _buildTableTypeSelector(),
            const SizedBox(height: 24),

            _buildSectionTitle('Waktu & Durasi'),
            const SizedBox(height: 4),
            const Text(
              'Pilih jam mulai lalu tentukan berapa jam kamu main.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildTimeAndDuration(),
            const SizedBox(height: 28),

            _buildSummaryCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Place card ─────────────────────────────────────────────────────────────
  Widget _buildPlaceCard(BilliardPlace place) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_bar_rounded,
                color: AppColors.neonGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(place.shortAddress,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'Rp ${(place.pricePerHour / 1000).toStringAsFixed(0)}k / jam',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );

  // ── Table Type Selector ──────────────────────────────────────────────────
  Widget _buildTableTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeCard(
            title: 'Reguler',
            price: widget.place.pricePerHour,
            isSelected: !_isVip,
            onTap: () => setState(() => _isVip = false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _typeCard(
            title: 'VIP',
            price: widget.place.priceVipPerHour,
            isSelected: _isVip,
            onTap: () => setState(() => _isVip = true),
          ),
        ),
      ],
    );
  }

  Widget _typeCard({
    required String title,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonGreen.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.neonGreen : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.neonGreen : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${(price / 1000).toInt()}k/jam',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.neonGreen, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Waktu & Durasi dalam 1 section ────────────────────────────────────────
  Widget _buildTimeAndDuration() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Baris jam mulai + durasi
          Row(
            children: [
              // Jam mulai
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jam Mulai',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    _buildHourStepper(
                      value: _startHour,
                      min: _minHour,
                      max: _maxStartHour,
                      onChanged: (v) => setState(() {
                        _startHour = v;
                        // Pastikan durasi tidak melewati tengah malam
                        if (_durationHours > _maxDuration) {
                          _durationHours = _maxDuration.clamp(1, 8);
                        }
                      }),
                    ),
                  ],
                ),
              ),

              // Divider vertikal
              Container(
                  width: 1,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.divider),

              // Durasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Durasi',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    _buildHourStepper(
                      value: _durationHours,
                      min: 1,
                      max: _maxDuration.clamp(1, 8),
                      onChanged: (v) => setState(() => _durationHours = v),
                      suffix: 'jam',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // Hasil: rentang waktu final
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded,
                  color: AppColors.neonGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                _timeSlotLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_durationHours jam',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stepper tombol − / nilai / + yang compact
  Widget _buildHourStepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    String? suffix,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value > min
                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                  : AppColors.divider,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded,
                size: 16,
                color:
                    value > min ? AppColors.neonGreen : AppColors.textMuted),
          ),
        ),
        Column(
          children: [
            Text(
              suffix == null
                  ? '${value.toString().padLeft(2, '0')}:00'
                  : '$value',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            if (suffix != null)
              Text(suffix,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value < max
                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                  : AppColors.divider,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded,
                size: 16,
                color:
                    value < max ? AppColors.neonGreen : AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Reservasi',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neonGreen)),
          const SizedBox(height: 12),
          _summaryRow('Tanggal',
              DateFormat('d MMM yyyy', 'id_ID').format(_selectedDate)),
          _summaryRow('Waktu', _timeSlotLabel),
          _summaryRow('Durasi', '$_durationHours jam'),
          const Divider(color: AppColors.divider, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(_totalPrice)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Consumer<ReservationProvider>(
      builder: (_, provider, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            // Harga preview di kiri
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(_totalPrice)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonGreen),
                ),
                Text(
                  '$_durationHours jam',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : _confirm,
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(
                    provider.isLoading ? 'Memproses...' : 'Konfirmasi',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
