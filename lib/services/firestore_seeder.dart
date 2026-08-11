import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/demo_data.dart';

/// Seeds all demo shops, categories and products into Firestore.
/// Call [seedAll] once to populate the database.
class FirestoreSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Clears and re-seeds shops → categories → products.
  /// [onProgress] is called with a human-readable status string.
  Future<void> seedAll({void Function(String)? onProgress}) async {
    onProgress?.call('Clearing existing data…');
    await _clearCollections();

    onProgress?.call('Seeding shops…');
    await _seedShops();

    onProgress?.call('Seeding categories…');
    await _seedCategories();

    onProgress?.call('Seeding products…');
    await _seedProducts(onProgress: onProgress);

    onProgress?.call('Done! 🎉');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _clearCollections() async {
    for (final col in ['shops', 'categories', 'products']) {
      final snap = await _db.collection(col).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHOPS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedShops() async {
    final batch = _db.batch();
    for (final shop in demoShops) {
      final id = shop['id'] as String;
      final data = Map<String, dynamic>.from(shop)..remove('id');
      batch.set(_db.collection('shops').doc(id), data);
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedCategories() async {
    final batch = _db.batch();
    for (final cat in demoAllCategories) {
      final ref = _db.collection('categories').doc();
      batch.set(ref, cat);
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedProducts({void Function(String)? onProgress}) async {
    final products = demoAllProducts;
    int done = 0;

    // Write in batches of 20 (Firestore limit is 500 but keep it safe).
    const batchSize = 20;
    for (int i = 0; i < products.length; i += batchSize) {
      final chunk = products.sublist(
        i,
        (i + batchSize).clamp(0, products.length),
      );
      final batch = _db.batch();
      for (final product in chunk) {
        final ref = _db.collection('products').doc();
        final data = Map<String, dynamic>.from(product);

        // Ensure weightOptions are properly converted.
        if (data['weightOptions'] != null) {
          data['weightOptions'] = (data['weightOptions'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        // Add server timestamp.
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();

        batch.set(ref, data);
      }
      await batch.commit();
      done += chunk.length;
      onProgress?.call('Seeding products… $done/${products.length}');
    }
  }
}
