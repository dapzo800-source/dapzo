import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

/// In-memory cart with ChangeNotifier so the UI reacts instantly.
/// Supports multi-shop cart items grouped by shop name.
class CartService extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {}; // keyed by lineKey

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
  }

  void incrementQty(String lineKey) {
    if (_items.containsKey(lineKey)) {
      _items[lineKey]!.quantity++;
      notifyListeners();
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
    }
  }

  void removeItem(String lineKey) {
    _items.remove(lineKey);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
