import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Status autentikasi untuk mengontrol UI (loading spinner, error, dll.)
enum AuthStatus { idle, loading, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // clientId wajib diisi untuk platform web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '682530664863-jo15uq0st25k4sogk0noke0thrio9jpg.apps.googleusercontent.com'
        : null,
  );

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────

  /// User yang sedang login. Null jika belum login.
  User? get currentUser => _auth.currentUser;

  /// Stream perubahan status login — dipakai oleh StreamBuilder di main.dart
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isLoggedIn => currentUser != null;

  // ── Register (Email / Password) ────────────────────────────────────────────

  /// Daftar akun baru dengan email, password, dan nama tampilan.
  /// Melempar [AuthException] jika gagal agar UI bisa menampilkan pesan.
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Simpan nama tampilan ke profil Firebase
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
      _setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan. Coba lagi.');
      return false;
    }
  }

  // ── Login (Email / Password) ───────────────────────────────────────────────

  /// Masuk dengan email dan password yang sudah terdaftar.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan. Coba lagi.');
      return false;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Masuk menggunakan akun Google.
  /// Di web pakai signInWithPopup, di mobile pakai google_sign_in flow biasa.
  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      if (kIsWeb) {
        // ── Web: popup flow via Firebase Auth langsung ──────────────────────
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await _auth.signInWithPopup(googleProvider);
      } else {
        // ── Mobile: google_sign_in package flow ─────────────────────────────
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        // User membatalkan dialog Google — bukan error sebenarnya
        if (googleUser == null) {
          _setIdle();
          return false;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
      _setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      // popup-closed-by-user bukan error — user sengaja tutup
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        _setIdle();
        return false;
      }
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (_) {
      _setError('Login Google gagal. Coba lagi.');
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _setLoading();
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (_) {
      // Abaikan error saat logout
    } finally {
      _setIdle();
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────

  /// Kirim email reset password ke alamat yang diberikan.
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setIdle();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (_) {
      _setError('Gagal mengirim email reset. Coba lagi.');
      return false;
    }
  }

  // ── Helpers (private) ──────────────────────────────────────────────────────

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setIdle() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Hapus pesan error secara manual (misalnya ketika user mulai mengetik ulang)
  void clearError() {
    if (_status == AuthStatus.error) {
      _status = AuthStatus.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Terjemahkan kode error Firebase ke pesan bahasa Indonesia yang ramah pengguna.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan.';
      default:
        return 'Terjadi kesalahan ($code). Coba lagi.';
    }
  }
}
