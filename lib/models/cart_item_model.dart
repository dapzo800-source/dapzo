import 'product_model.dart';

class CartItemModel {
  final String productId;
  final String name;
  final String imageUrl;
  final String mode;
  final String? selectedWeight; // e.g. "500g", null for food items without weight options
  final double unitPrice;
  int quantity;
  final String? specialInstructions;
  final String shopId;
  final String shopName;
  final String categoryId;
  final String subcategoryId;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.mode,
    this.selectedWeight,
    required this.unitPrice,
    this.quantity = 1,
    this.specialInstructions,
    this.shopId = '',
    this.shopName = 'Dapzo Partner Shop',
    this.categoryId = '',
    this.subcategoryId = '',
  });

  double get totalPrice => unitPrice * quantity;

  factory CartItemModel.fromProduct(
    ProductModel product, {
    String? selectedWeight,
    double? weightPrice,
    int quantity = 1,
    String? specialInstructions,
    String? shopName,
  }) {
    return CartItemModel(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      mode: product.mode,
      selectedWeight: selectedWeight,
      unitPrice: weightPrice ?? product.price,
      quantity: quantity,
      specialInstructions: specialInstructions,
      shopId: product.shopId,
      shopName: shopName ?? 'Dapzo Partner Shop',
      categoryId: product.category,
      subcategoryId: product.subCategory,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'mode': mode,
        'selectedWeight': selectedWeight,
        'unitPrice': unitPrice,
        'price': unitPrice,
        'quantity': quantity,
        'specialInstructions': specialInstructions,
        'shopId': shopId,
        'shopName': shopName,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
      };

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      if (val is String) {
        final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
        return parsed ?? fallback;
      }
      return fallback;
    }

    int parseInt(dynamic val, [int fallback = 1]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) {
        final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
        return parsed ?? fallback;
      }
      return fallback;
    }

    String parseString(dynamic val, [String fallback = '']) {
      if (val == null) return fallback;
      return val.toString().trim();
    }

    final rawQty = parseInt(
      map['quantity'] ?? map['qty'] ?? map['count'] ?? map['itemCount'],
      1,
    );
    final quantity = rawQty > 0 ? rawQty : 1;

    double unitPrice = parseDouble(
      map['unitPrice'] ??
          map['price'] ??
          map['unit_price'] ??
          map['itemPrice'] ??
          map['productPrice'] ??
          map['rate'] ??
          map['cost'],
      0.0,
    );

    // If unitPrice is 0, attempt to derive from totalPrice or total if present
    if (unitPrice <= 0.0) {
      final lineTotal = parseDouble(
        map['totalPrice'] ?? map['total'] ?? map['itemTotal'] ?? map['lineTotal'],
        0.0,
      );
      if (lineTotal > 0.0 && quantity > 0) {
        unitPrice = lineTotal / quantity;
      }
    }

    final productId = parseString(
      map['productId'] ?? map['id'] ?? map['product_id'] ?? map['_id'],
    );

    final name = parseString(
      map['name'] ??
          map['productName'] ??
          map['title'] ??
          map['product_name'] ??
          map['itemName'] ??
          map['item_name'],
      'Product',
    );

    final imageUrl = parseString(
      map['imageUrl'] ??
          map['image'] ??
          map['productImage'] ??
          map['img'] ??
          map['product_image'] ??
          map['image_url'] ??
          map['photoUrl'] ??
          map['picture'] ??
          map['thumbnail'] ??
          map['productImg'] ??
          map['product_img'] ??
          map['imgUrl'],
    );

    final mode = parseString(
      map['mode'] ?? map['type'] ?? map['categoryMode'],
      'food',
    );

    final rawWeight = map['selectedWeight'] ??
        map['weight'] ??
        map['unit'] ??
        map['variant'] ??
        map['selectedUnit'] ??
        map['weightUnit'] ??
        map['size'] ??
        map['option'] ??
        map['packetSize'];

    final selectedWeight =
        rawWeight != null && rawWeight.toString().trim().isNotEmpty
            ? rawWeight.toString().trim()
            : null;

    final specialInstructions = map['specialInstructions'] != null
        ? parseString(map['specialInstructions'])
        : (map['instructions'] != null
            ? parseString(map['instructions'])
            : (map['notes'] != null ? parseString(map['notes']) : null));

    final shopId = parseString(
      map['shopId'] ?? map['storeId'] ?? map['shop_id'] ?? map['vendorId'],
    );

    final shopName = parseString(
      map['shopName'] ??
          map['storeName'] ??
          map['shop_name'] ??
          map['vendorName'] ??
          map['merchantName'],
      'Dapzo Partner Shop',
    );

    final categoryId = parseString(
      map['categoryId'] ??
          map['category'] ??
          map['categoryName'] ??
          map['category_id'],
    );

    final subcategoryId = parseString(
      map['subcategoryId'] ??
          map['subCategory'] ??
          map['subCategoryId'] ??
          map['subcategory_id'],
    );

    return CartItemModel(
      productId: productId,
      name: name,
      imageUrl: imageUrl,
      mode: mode,
      selectedWeight: selectedWeight,
      unitPrice: unitPrice,
      quantity: quantity,
      specialInstructions: specialInstructions,
      shopId: shopId,
      shopName: shopName,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    );
  }

  /// A cart line is unique per product + selected weight + shopId, so items from
  /// different shops or with different weight options exist as separate lines.
  String get lineKey => '$productId::$shopId::${selectedWeight ?? ''}';
}