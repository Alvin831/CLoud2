import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/place_service.dart';
import '../models/billiard_place.dart';

/// Status pemuatan data biliar
enum BilliardLoadStatus { initial, loading, loaded, error }

/// Provider untuk mengelola 15 data biliar dari Firestore.
/// Menyediakan filter, search, dan sorting yang bisa dikonsumsi
/// oleh widget mana pun yang membutuhkan data tempat biliar.
class BilliardProvider extends ChangeNotifier {
  final PlaceService _service = PlaceService();

  BilliardLoadStatus _status = BilliardLoadStatus.initial;
  List<BilliardPlace> _allPlaces = [];
  List<BilliardPlace> _filteredPlaces = [];
  String _activeFilter = 'Semua';
  String _searchQuery = '';
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────

  BilliardLoadStatus get status => _status;
  List<BilliardPlace> get filteredPlaces => List.unmodifiable(_filteredPlaces);
  List<BilliardPlace> get allPlaces => List.unmodifiable(_allPlaces);
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == BilliardLoadStatus.loading;
  bool get hasError => _status == BilliardLoadStatus.error;
  bool get isLoaded => _status == BilliardLoadStatus.loaded;
  int get totalCount => _allPlaces.length;
  int get filteredCount => _filteredPlaces.length;

  static const List<String> filterOptions = [
    'Semua',
    'Terdekat',
    'Rating',
    'Buka Sekarang',
  ];

  // ── Fetch Data ─────────────────────────────────────────────────────────────

  /// Ambil data biliar dari Firestore.
  /// Dipanggil pertama kali saat HomePage/BilliardProvider diinisialisasi.
  Future<void> fetchPlaces() async {
    // Cegah fetch berulang jika data sudah ada
    if (_status == BilliardLoadStatus.loaded && _allPlaces.isNotEmpty) return;

    _status = BilliardLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final places = await _service.fetchPlaces();
      _allPlaces = places;
      _applyFiltersAndSearch();
      _status = BilliardLoadStatus.loaded;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal memuat data: ${e.message ?? e.code}';
      _status = BilliardLoadStatus.error;
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah. Periksa internet dan coba lagi.';
      _status = BilliardLoadStatus.error;
    }

    notifyListeners();
  }

  /// Paksa refresh data dari Firestore meskipun sudah di-load sebelumnya.
  Future<void> refresh() async {
    _status = BilliardLoadStatus.initial;
    await fetchPlaces();
  }

  // ── Filter & Search ────────────────────────────────────────────────────────

  /// Ubah filter aktif dan terapkan ke data.
  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _applyFiltersAndSearch();
    notifyListeners();
  }

  /// Perbarui query pencarian dan terapkan ke data.
  void setSearch(String query) {
    _searchQuery = query;
    _applyFiltersAndSearch();
    notifyListeners();
  }

  /// Reset filter dan search ke kondisi awal.
  void resetFilters() {
    _activeFilter = 'Semua';
    _searchQuery = '';
    _filteredPlaces = List.from(_allPlaces);
    notifyListeners();
  }

  /// Perbarui jarak semua tempat berdasarkan koordinat GPS user.
  void attachUserLocation(double userLat, double userLng) {
    _allPlaces = _service.attachDistances(_allPlaces, userLat, userLng);
    _applyFiltersAndSearch();
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// Terapkan filter aktif DAN query search secara bersamaan.
  void _applyFiltersAndSearch() {
    // 1. Terapkan filter sorting
    List<BilliardPlace> result;
    switch (_activeFilter) {
      case 'Terdekat':
        result = List.from(_allPlaces)
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case 'Rating':
        result = List.from(_allPlaces)
          ..sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Buka Sekarang':
        result = _allPlaces.where((p) => p.isOpen).toList();
        break;
      default: // 'Semua'
        result = List.from(_allPlaces);
    }

    // 2. Terapkan query search di atas hasil filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.shortAddress.toLowerCase().contains(q) ||
              p.fullAddress.toLowerCase().contains(q))
          .toList();
    }

    _filteredPlaces = result;
  }
}
