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

  factory CartItemModel.fromMap(Map<String, dynamic> map) => CartItemModel(
        productId: map['productId'] ?? map['id'] ?? '',
        name: map['name'] ?? map['productName'] ?? '',
        imageUrl: map['imageUrl'] ?? map['image'] ?? '',
        mode: map['mode'] ?? 'food',
        selectedWeight: map['selectedWeight'] ?? map['weight'],
        unitPrice: (map['unitPrice'] ?? map['price'] ?? 0).toDouble(),
        quantity: map['quantity'] ?? map['qty'] ?? 1,
        specialInstructions: map['specialInstructions'],
        shopId: map['shopId'] ?? '',
        shopName: map['shopName'] ?? 'Dapzo Partner Shop',
        categoryId: map['categoryId'] ?? map['category'] ?? map['categoryName'] ?? '',
        subcategoryId: map['subcategoryId'] ?? map['subCategory'] ?? map['subCategoryId'] ?? '',
      );

  /// A cart line is unique per product + selected weight + shopId, so items from
  /// different shops or with different weight options exist as separate lines.
  String get lineKey => '$productId::$shopId::${selectedWeight ?? ''}';
}