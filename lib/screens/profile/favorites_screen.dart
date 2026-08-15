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
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textDark,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Favorites',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      body: uid == null || uid.isEmpty
          ? Center(child: Text('Please sign in to view favorites', style: AppTextStyles.supporting))
          : StreamBuilder<List<String>>(
              stream: favoritesService.streamFavoriteIds(uid),
              builder: (context, favSnap) {
                final favIds = favSnap.data ?? [];
                if (favIds.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          Text('No favorites added yet', style: AppTextStyles.heading.copyWith(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Tap the heart icon on any dish to save your favorite dishes here for quick re-ordering.',
                              textAlign: TextAlign.center, style: AppTextStyles.supporting),
                        ],
                      ),
                    ),
                  );
                }
                return FutureBuilder<List<ProductModel>>(
                  future: favoritesService.fetchFavoriteProducts(favIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Text('No active favorite items available', style: AppTextStyles.supporting),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final cart = context.watch<CartService>();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProductListCard(
                            product: product,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: product.id),
                              ),
                            ),
                            onAdd: () => cart.addItem(
                              CartItemModel(
                                productId: product.id,
                                name: product.name,
                                imageUrl: product.imageUrl,
                                unitPrice: product.price,
                                mode: product.mode,
                                shopId: product.shopId,
                              ),
                            ),
                          ),
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