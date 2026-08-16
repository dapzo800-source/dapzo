import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item_model.dart';

/// In-memory cart with ChangeNotifier so the UI reacts instantly.
/// Supports multi-shop cart items grouped by shop name.
/// Cart is persisted to SharedPreferences so it survives app restarts.
class CartService extends ChangeNotifier {
  static const _kCartKey = 'dapzo_cart_items';

  final Map<String, CartItemModel> _items = {}; // keyed by lineKey

  CartService() {
    _loadFromPrefs();
  }

  List<CartItemModel> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0, (sum, item) => sum + item.totalPrice);

  /// Returns items grouped by Shop Name for multi-shop cart display.
  Map<String, List<CartItemModel>> get itemsGroupedByShop {
    final Map<String, List<CartItemModel>> grouped = {};
    for (final item in _items.values) {
      final name = item.shopName.isNotEmpty ? item.shopName : 'Dapzo Partner Shop';
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(item);
    }
    return grouped;
  }

  /// Returns subtotal for a specific shop name
  double shopSubtotal(String shopName) {
    return _items.values
        .where((i) => (i.shopName.isNotEmpty ? i.shopName : 'Dapzo Partner Shop') == shopName)
        .fold(0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(CartItemModel item) {
    final key = item.lineKey;
    if (_items.containsKey(key)) {
      _items[key]!.quantity += item.quantity;
    } else {
      _items[key] = item;
    }
    notifyListeners();
    _saveToPrefs();
  }

  void incrementQty(String lineKey) {
    if (_items.containsKey(lineKey)) {
      _items[lineKey]!.quantity++;
      notifyListeners();
      _saveToPrefs();
    }
  }

  void decrementQty(String lineKey) {
    if (_items.containsKey(lineKey)) {
      final item = _items[lineKey]!;
      if (item.quantity <= 1) {
        _items.remove(lineKey);
      } else {
        item.quantity--;
      }
      notifyListeners();
      _saveToPrefs();
    }
  }

  void removeItem(String lineKey) {
    _items.remove(lineKey);
    notifyListeners();
    _saveToPrefs();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveToPrefs();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  /// Saves the current cart to SharedPreferences as a JSON list.
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.values.map((item) => item.toMap()).toList();
      await prefs.setString(_kCartKey, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('CartService: failed to save cart: $e');
    }
  }

  /// Loads the cart from SharedPreferences on startup.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartKey);
      if (raw == null || raw.isEmpty) return;

      final list = jsonDecode(raw) as List<dynamic>;
      _items.clear();
      for (final entry in list) {
        try {
          final item = CartItemModel.fromMap(Map<String, dynamic>.from(entry as Map));
          if (item.productId.isNotEmpty) {
            _items[item.lineKey] = item;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('CartService: failed to parse cart item: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('CartService: failed to load cart: $e');
    }
  }
}
