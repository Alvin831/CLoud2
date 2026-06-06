# Billiard Surabaya 🎱

Aplikasi mobile Flutter untuk menemukan tempat billiard di Surabaya.

## Struktur Project

```
lib/
├── main.dart
├── core/
│   ├── theme/app_theme.dart        # Warna, font, Material Design 3
│   ├── models/billiard_place.dart  # Model data tempat billiard
│   ├── data/dummy_data.dart        # Data dummy 5 tempat billiard
│   ├── providers/favorite_provider.dart
│   └── widgets/place_card.dart     # Reusable card widget
└── features/
    ├── main/main_shell.dart        # Bottom Nav Shell
    ├── home/home_page.dart         # Home + Search + Banner + List
    ├── detail/detail_page.dart     # Detail lengkap tempat
    ├── map/map_page.dart           # Google Maps full screen
    ├── favorite/favorite_page.dart # Daftar favorit
    └── profile/profile_page.dart   # Profil pengguna
```

## Cara Menjalankan

1. Install dependencies:
```bash
flutter pub get
```

2. Tambahkan Google Maps API Key di:
   - `android/app/src/main/AndroidManifest.xml` → ganti `YOUR_GOOGLE_MAPS_API_KEY`

3. Jalankan:
```bash
flutter run
```

## Fitur

- **Home**: Search bar, banner promo carousel, filter chip, list tempat dengan card
- **Detail**: Foto galeri, info fasilitas, tombol Buka Rute & Simpan Favorit
- **Map**: Google Maps dark mode, marker seluruh tempat, bottom sheet preview
- **Favorit**: Swipe to delete, empty state
- **Profil**: Stats, menu pengaturan

## Dependencies

- `google_maps_flutter` - Peta interaktif
- `google_fonts` - Font Inter
- `provider` - State management favorit
- `carousel_slider` - Banner promo
- `url_launcher` - Buka Google Maps navigasi
- `cached_network_image` - Cache gambar
