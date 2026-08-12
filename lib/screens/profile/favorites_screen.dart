import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_list_card.dart';
import '../product/product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: uid == null
          ? const SizedBox.shrink()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('favorites')
                  .snapshots(),
              builder: (context, favSnap) {
                final favIds = favSnap.data?.docs.map((d) => d.id).toList() ?? [];
                if (favIds.isEmpty) {
                  return Center(
                    child: Text('No favorites yet', style: AppTextStyles.supporting),
                  );
                }
                return FutureBuilder<List<ProductModel>>(
                  future: Future.wait(favIds.map((id) async {
                    final doc = await FirebaseFirestore.instance.collection('products').doc(id).get();
                    return doc.exists ? ProductModel.fromFirestore(doc) : null;
                  })).then((list) => list.whereType<ProductModel>().toList()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data!;
                    if (products.isEmpty) {
                      return Center(
                        child: Text('No favorites yet', style: AppTextStyles.supporting),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductListCard(
                          product: product,
                          highlyReordered: product.rating >= 4.0,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
                          ),
                          onAdd: () => context.read<CartService>().addItem(CartItemModel.fromProduct(product)),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}