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
/// - Food-mode filters (veg, price, rating)
///
/// Cart is managed separately by CartService.
class AppState extends ChangeNotifier {
  UserModel? _user;

  String _mode = 'food';

  AddressModel? _selectedAddress;

  String? _servingShopId;

  bool _isDarkMode = false;

  // ── Food-mode filters ──────────────────────────────────────────
  bool _isVegMode = false;
  bool _isUnder199 = false;
  bool _isRating4Plus = false;
  bool _isNearAndFast = false;

  String? _selectedCategory;

  // ============================================================
  // GETTERS
  // ============================================================

  UserModel? get user => _user;

  String get mode => _mode;

  String? get selectedCategory => _selectedCategory;

  AddressModel? get selectedAddress => _selectedAddress;

  String? get servingShopId => _servingShopId;

  bool get isDarkMode => _isDarkMode;

  bool get isVegMode => _isVegMode;
  bool get isUnder199 => _isUnder199;
  bool get isRating4Plus => _isRating4Plus;
  bool get isNearAndFast => _isNearAndFast;

  /// True when any food-mode filter is active.
  bool get hasActiveFilters => _isVegMode || _isUnder199 || _isRating4Plus || _isNearAndFast;

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
    _selectedCategory = null; // reset category on mode change for immediate fresh listings

    // Reset food-mode filters when switching to meat
    if (mode == 'meat') {
      _isVegMode = false;
      _isUnder199 = false;
      _isRating4Plus = false;
      _isNearAndFast = false;
    }

    notifyListeners();
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  void setSelectedCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null; // toggle off if already selected
    } else {
      _selectedCategory = category;
    }
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
  // FOOD-MODE FILTERS
  // ============================================================

  void toggleVegMode() {
    _isVegMode = !_isVegMode;
    notifyListeners();
  }

  void toggleUnder199() {
    _isUnder199 = !_isUnder199;
    notifyListeners();
  }

  void toggleRating4Plus() {
    _isRating4Plus = !_isRating4Plus;
    notifyListeners();
  }

  void toggleNearAndFast() {
    _isNearAndFast = !_isNearAndFast;
    notifyListeners();
  }

  void clearFilters() {
    _isVegMode = false;
    _isUnder199 = false;
    _isRating4Plus = false;
    _isNearAndFast = false;
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