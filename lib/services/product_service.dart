import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

/// Product and category data are loaded dynamically from Firestore.
/// No static or hard-coded product catalog is used.
class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // PRODUCTS
  // ============================================================

  /// Streams active and available products.
  ///
  /// mode:
  ///   food
  ///   meat
  ///
  /// categoryId:
  ///   Optional Firestore category document ID.
  ///
  /// shopId:
  ///   Optional shop document ID.
  Stream<List<ProductModel>> streamProducts({
    required String mode,
    String? category,
    String? shopId,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where(
          'mode',
          isEqualTo: mode,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .where(
          'isAvailable',
          isEqualTo: true,
        );

    // ------------------------------------------------------------
    // CATEGORY FILTER
    // ------------------------------------------------------------

    if (category != null && category.isNotEmpty) {
      query = query.where(
        'category',
        isEqualTo: category,
      );
    }

    // ------------------------------------------------------------
    // SHOP FILTER
    // ------------------------------------------------------------

    if (shopId != null && shopId.isNotEmpty) {
      query = query.where(
        'shopId',
        isEqualTo: shopId,
      );
    }

    return query
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  (document) =>
                      ProductModel.fromFirestore(document),
                )
                .toList();
          },
        );
  }

  // ============================================================
  // SINGLE PRODUCT
  // ============================================================

  Future<ProductModel?> getProduct(
    String productId,
  ) async {
    final document = await _db
        .collection('products')
        .doc(productId)
        .get();

    if (!document.exists) {
      return null;
    }

    return ProductModel.fromFirestore(document);
  }

  // ============================================================
  // SEARCH PRODUCTS
  // ============================================================

  /// Searches products using nameLowercase.
  ///
  /// Example:
  /// "chicken" → Chicken Biryani, Chicken 65, etc.
  Stream<List<ProductModel>> searchProducts(
    String searchQuery, {
    String? mode,
  }) {
    final text = searchQuery.trim().toLowerCase();

    // No search text.
    if (text.isEmpty) {
      return Stream.value(<ProductModel>[]);
    }

    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where(
          'isActive',
          isEqualTo: true,
        )
        .where(
          'isAvailable',
          isEqualTo: true,
        )
        .where(
          'nameLowercase',
          isGreaterThanOrEqualTo: text,
        )
        .where(
          'nameLowercase',
          isLessThanOrEqualTo: '$text\uf8ff',
        );

    // Optional Food / Meat filter.
    if (mode != null && mode.isNotEmpty) {
      query = query.where(
        'mode',
        isEqualTo: mode,
      );
    }

    return query
        .limit(20)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  (document) =>
                      ProductModel.fromFirestore(document),
                )
                .toList();
          },
        );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  /// Streams active categories for Food or Meat.
  ///
  /// IMPORTANT:
  /// We do NOT use Firestore orderBy() here.
  /// Categories are sorted locally using the "order" field.
  ///
  /// Example:
  ///
  /// mode = food
  ///
  /// Biryani
  /// Meals
  /// Rice
  /// Snacks
  ///
  Stream<List<Map<String, dynamic>>> streamCategories(
    String mode,
  ) {
    return _db
        .collection('categories')
        .where(
          'mode',
          isEqualTo: mode,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            final categories = snapshot.docs.map(
              (document) {
                return <String, dynamic>{
                  'id': document.id,
                  ...document.data(),
                };
              },
            ).toList();

            // ------------------------------------------------------
            // SORT LOCALLY
            // ------------------------------------------------------

            categories.sort(
              (a, b) {
                final orderA =
                    (a['order'] as num?)?.toInt() ?? 999;

                final orderB =
                    (b['order'] as num?)?.toInt() ?? 999;

                return orderA.compareTo(orderB);
              },
            );

            return categories;
          },
        );
  }

  // ============================================================
  // OFFERS
  // ============================================================

  Stream<List<Map<String, dynamic>>> streamOffers(
    String mode,
  ) {
    return _db
        .collection('offers')
        .where(
          'mode',
          isEqualTo: mode,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (document) {
                return <String, dynamic>{
                  'id': document.id,
                  ...document.data(),
                };
              },
            ).toList();
          },
        );
  }
}