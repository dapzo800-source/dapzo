import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

/// In-memory cart with ChangeNotifier so the UI reacts instantly.
/// Cart is NOT written to Firestore until checkout creates the order.
class CartService extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {}; // keyed by lineKey

  List<CartItemModel> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0, (sum, item) => sum + item.totalPrice);

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
