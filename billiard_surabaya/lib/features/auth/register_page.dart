import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      _showSnackbar('Kamu perlu menyetujui syarat & ketentuan.');
      return;
    }
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.registerWithEmail(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      // Kembali ke root agar AuthGate tampilkan MainShell
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showSnackbar(auth.errorMessage ?? 'Pendaftaran gagal.');
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.neonGreen : AppColors.closed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 36),
              _buildForm(),
              const SizedBox(height: 16),
              _buildTermsCheckbox(),
              const SizedBox(height: 28),
              _buildRegisterButton(),
              const SizedBox(height: 32),
              _buildLoginLink(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        // Logo
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.neonGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.sports_bar_rounded,
              color: Colors.black, size: 28),
        ),
        const SizedBox(height: 20),
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Daftar untuk mulai menjelajahi tempat\nbilliard terbaik di Surabaya.',
          style: TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nama Lengkap
          TextFormField(
            controller: _nameCtrl,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            decoration: const InputDecoration(
              hintText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nama wajib diisi.';
              if (v.trim().length < 2) return 'Nama minimal 2 karakter.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email_outlined,
                  color: AppColors.textMuted, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi.';
              if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
                return 'Format email tidak valid.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi.';
              if (v.length < 6) return 'Password minimal 6 karakter.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Konfirmasi Password
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Konfirmasi Password',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi.';
              if (v != _passwordCtrl.text) return 'Password tidak cocok.';
              return null;
            },
          ),

          // Password strength indicator
          const SizedBox(height: 8),
          _buildPasswordStrength(),
        ],
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordCtrl.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(password)) strength++;

    final labels = ['', 'Sangat Lemah', 'Lemah', 'Cukup', 'Kuat', 'Sangat Kuat'];
    final colors = [
      Colors.transparent,
      AppColors.closed,
      Colors.orange,
      Colors.yellow,
      AppColors.neonGreen,
      AppColors.neonGreen,
    ];

    return Row(
      children: [
        ...List.generate(5, (i) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < strength ? colors[strength] : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          labels[strength],
          style: TextStyle(
            fontSize: 11,
            color: colors[strength],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _agreeToTerms,
              onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
              activeColor: AppColors.neonGreen,
              checkColor: Colors.black,
              side: const BorderSide(color: AppColors.textMuted),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                children: [
                  TextSpan(text: 'Saya menyetujui '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: TextStyle(
                        color: AppColors.neonGreen, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' dan '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: TextStyle(
                        color: AppColors.neonGreen, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' Billiard Surabaya.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.neonGreen.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Buat Akun',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Sudah punya akun? ',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Masuk',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neonGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
