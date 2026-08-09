import 'package:cloud_firestore/cloud_firestore.dart';

/// A single weight/size option for a product, e.g. 250g -> price.
class WeightOption {
  final String label; // "250g", "500g", "1kg"
  final double price;

  WeightOption({required this.label, required this.price});

  factory WeightOption.fromMap(Map<String, dynamic> map) {
    return WeightOption(
      label: map['label'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'label': label, 'price': price};
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String subCategory;
  final String mode; // "food" | "meat"
  final double price;
  final String unit; // "plate", "kg", "piece" etc.
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final List<WeightOption> weightOptions;
  final String shopId;
  final bool isAvailable;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.mode,
    required this.price,
    required this.unit,
    required this.imageUrl,
    this.rating = 0,
    this.ratingCount = 0,
    this.weightOptions = const [],
    required this.shopId,
    this.isAvailable = true,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      mode: data['mode'] ?? 'food',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      ratingCount: (data['ratingCount'] ?? 0),
      weightOptions: (data['weightOptions'] as List<dynamic>? ?? [])
          .map((e) => WeightOption.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      shopId: data['shopId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'mode': mode,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'weightOptions': weightOptions.map((e) => e.toMap()).toList(),
      'shopId': shopId,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
