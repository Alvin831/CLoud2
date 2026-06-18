import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/place_service.dart';
import '../models/billiard_place.dart';

enum BilliardLoadStatus { initial, loading, loaded, error }
enum LocationStatus { idle, loading, granted, denied }

class BilliardProvider extends ChangeNotifier {
  final PlaceService _service = PlaceService();

  BilliardLoadStatus _status = BilliardLoadStatus.initial;
  LocationStatus _locationStatus = LocationStatus.idle;

  List<BilliardPlace> _allPlaces = [];
  List<BilliardPlace> _filteredPlaces = [];

  String _activeFilter = 'Semua';
  String _searchQuery = '';
  String? _errorMessage;

  // ── Filter harga ───────────────────────────────────────────────────────────
  double _minPrice = 0;
  double _maxPrice = 100000;
  bool _priceFilterActive = false;

  // ── GPS ────────────────────────────────────────────────────────────────────
  double? _userLat;
  double? _userLng;

  // ── Getters ────────────────────────────────────────────────────────────────
  BilliardLoadStatus get status => _status;
  LocationStatus get locationStatus => _locationStatus;
  List<BilliardPlace> get filteredPlaces => List.unmodifiable(_filteredPlaces);
  List<BilliardPlace> get allPlaces => List.unmodifiable(_allPlaces);
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == BilliardLoadStatus.loading;
  bool get hasError => _status == BilliardLoadStatus.error;
  bool get isLoaded => _status == BilliardLoadStatus.loaded;
  bool get hasLocation => _userLat != null && _userLng != null;
  bool get priceFilterActive => _priceFilterActive;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double? get userLat => _userLat;
  double? get userLng => _userLng;

  static const List<String> filterOptions = [
    'Semua', 'Terdekat', 'Rating', 'Buka Sekarang',
  ];

  // ── Fetch Data ─────────────────────────────────────────────────────────────
  Future<void> fetchPlaces() async {
    if (_status == BilliardLoadStatus.loaded && _allPlaces.isNotEmpty) return;
    _status = BilliardLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final places = await _service.fetchPlaces();
      _allPlaces = places;
      // Kalau GPS sudah ada, langsung attach jarak
      if (hasLocation) {
        _allPlaces = _service.attachDistances(_allPlaces, _userLat!, _userLng!);
      }
      _applyAll();
      _status = BilliardLoadStatus.loaded;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal memuat data: ${e.message ?? e.code}';
      _status = BilliardLoadStatus.error;
    } catch (_) {
      _errorMessage = 'Koneksi bermasalah. Coba lagi.';
      _status = BilliardLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    _status = BilliardLoadStatus.initial;
    await fetchPlaces();
  }

  // ── GPS Location ──────────────────────────────────────────────────────────
  /// Minta izin GPS dan ambil koordinat user. Update jarak semua tempat.
  Future<void> requestLocation() async {
    _locationStatus = LocationStatus.loading;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationStatus = LocationStatus.denied;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _locationStatus = LocationStatus.denied;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _userLat = pos.latitude;
      _userLng = pos.longitude;
      _locationStatus = LocationStatus.granted;

      // Attach jarak ke semua places
      if (_allPlaces.isNotEmpty) {
        _allPlaces = _service.attachDistances(_allPlaces, _userLat!, _userLng!);
        _applyAll();
      }
    } catch (_) {
      _locationStatus = LocationStatus.denied;
    }
    notifyListeners();
  }

  // ── Filter & Search ────────────────────────────────────────────────────────
  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _applyAll();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applyAll();
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _priceFilterActive = true;
    _applyAll();
    notifyListeners();
  }

  void clearPriceFilter() {
    _minPrice = 0;
    _maxPrice = 100000;
    _priceFilterActive = false;
    _applyAll();
    notifyListeners();
  }

  void resetFilters() {
    _activeFilter = 'Semua';
    _searchQuery = '';
    _priceFilterActive = false;
    _minPrice = 0;
    _maxPrice = 100000;
    _filteredPlaces = List.from(_allPlaces);
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────
  void _applyAll() {
    List<BilliardPlace> result;

    // 1. Sort / filter berdasarkan chip aktif
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
      default:
        result = List.from(_allPlaces);
    }

    // 2. Filter harga
    if (_priceFilterActive) {
      result = result
          .where((p) => p.pricePerHour >= _minPrice && p.pricePerHour <= _maxPrice)
          .toList();
    }

    // 3. Search query
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
