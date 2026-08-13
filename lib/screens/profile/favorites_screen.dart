import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/product_list_card.dart';
import '../product/product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final favoritesService = FavoritesService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: uid == null || uid.isEmpty
          ? Center(child: Text('Please sign in to view favorites', style: AppTextStyles.supporting))
          : StreamBuilder<List<String>>(
              stream: favoritesService.streamFavoriteIds(uid),
              builder: (context, favSnap) {
                final favIds = favSnap.data ?? [];
                if (favIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 56, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('No favorites added yet', style: AppTextStyles.supporting),
                      ],
                    ),
                  );
                }
                return FutureBuilder<List<ProductModel>>(
                  future: favoritesService.fetchFavoriteProducts(favIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Text('No active favorite items available', style: AppTextStyles.supporting),
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