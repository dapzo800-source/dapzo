import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams whether a specific product is favorited by user.
  Stream<bool> streamIsFavorite(String userId, String productId) {
    if (userId.isEmpty || productId.isEmpty) return Stream.value(false);
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Streams user favorite product IDs from users/{userId}/favorites.
  Stream<List<String>> streamFavoriteIds(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  /// Toggles favorite state for a product under users/{userId}/favorites/{productId}.
  Future<bool> toggleFavorite(String userId, String productId) async {
    if (userId.isEmpty || productId.isEmpty) return false;
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      return false; // Now unfavorited
    } else {
      await docRef.set({
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true; // Now favorited
    }
  }

  /// Fetches actual product models for a list of favorite product IDs.
  /// Gracefully skips deleted, inactive, or unavailable products.
  Future<List<ProductModel>> fetchFavoriteProducts(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final futures = productIds.map((id) async {
      try {
        final doc = await _db.collection('products').doc(id).get();
        if (!doc.exists) return null;
        final product = ProductModel.fromFirestore(doc);
        if (!product.isActive || !product.isAvailable) return null;
        return product;
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    return results.whereType<ProductModel>().toList();
  }
}
