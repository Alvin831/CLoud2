import 'package:flutter/foundation.dart';
import '../models/billiard_place.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<BilliardPlace> _favorites = [];

  List<BilliardPlace> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) => _favorites.any((p) => p.id == id);

  void toggle(BilliardPlace place) {
    if (isFavorite(place.id)) {
      _favorites.removeWhere((p) => p.id == place.id);
    } else {
      _favorites.add(place);
    }
    notifyListeners();
  }
}
