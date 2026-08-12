import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/address_model.dart';

/// Global app-level state.
///
/// Stores:
/// - Current user
/// - Current mode: food / meat
/// - Currently selected delivery address
/// - Serving shop ID
///
/// Cart is managed separately by CartService.
class AppState extends ChangeNotifier {
  UserModel? _user;

  String _mode = 'food';

  AddressModel? _selectedAddress;

  String? _servingShopId;

  bool _isDarkMode = false;

  // ============================================================
  // GETTERS
  // ============================================================

  UserModel? get user => _user;

  String get mode => _mode;

  AddressModel? get selectedAddress => _selectedAddress;

  String? get servingShopId => _servingShopId;

  bool get isDarkMode => _isDarkMode;

  // ============================================================
  // USER
  // ============================================================

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  // ============================================================
  // MODE
  // ============================================================

  void setMode(String mode) {
    if (mode != 'food' && mode != 'meat') {
      return;
    }

    if (_mode == mode) {
      return;
    }

    _mode = mode;
    notifyListeners();
  }

  // ============================================================
  // SELECTED ADDRESS
  // ============================================================

  void setSelectedAddress(AddressModel? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void clearSelectedAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  // ============================================================
  // SERVING SHOP
  // ============================================================

  void setServingShop(String? shopId) {
    _servingShopId = shopId;
    notifyListeners();
  }

  // ============================================================
  // THEME
  // ============================================================

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ============================================================
  // RESET
  // ============================================================

  void clearUserData() {
    _user = null;
    _selectedAddress = null;
    _servingShopId = null;

    notifyListeners();
  }
}