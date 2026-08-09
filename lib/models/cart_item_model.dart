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

  CartItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.mode,
    this.selectedWeight,
    required this.unitPrice,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => unitPrice * quantity;

  factory CartItemModel.fromProduct(
    ProductModel product, {
    String? selectedWeight,
    double? weightPrice,
    int quantity = 1,
    String? specialInstructions,
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
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'mode': mode,
        'selectedWeight': selectedWeight,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'specialInstructions': specialInstructions,
      };

  factory CartItemModel.fromMap(Map<String, dynamic> map) => CartItemModel(
        productId: map['productId'],
        name: map['name'],
        imageUrl: map['imageUrl'],
        mode: map['mode'],
        selectedWeight: map['selectedWeight'],
        unitPrice: (map['unitPrice'] ?? 0).toDouble(),
        quantity: map['quantity'] ?? 1,
        specialInstructions: map['specialInstructions'],
      );

  /// A cart line is unique per product + selected weight, so the same
  /// product with a different weight option is a separate line item.
  String get lineKey => '$productId::${selectedWeight ?? ''}';
}
