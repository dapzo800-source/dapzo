import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Dynamic "Recommended for You" section using ONLY real Firestore products
/// from the existing `products` collection (`isActive == true` and `isAvailable == true`).
class RecommendedCombosSection extends StatelessWidget {
  final String? shopId;
  const RecommendedCombosSection({super.key, this.shopId});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    final appState = context.watch<AppState>();
    final mode = appState.mode;

    final targetShopId = shopId ?? (appState.servingShopId);

    return StreamBuilder<List<ProductModel>>(
      stream: productService.streamProducts(
        mode: mode,
        shopId: targetShopId,
        limit: 20,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no existing products match
        }

        var products = snapshot.data!;

        // Sort deterministically by rating/ratingCount if available
        products.sort((a, b) {
          if (b.rating != a.rating) {
            return b.rating.compareTo(a.rating);
          }
          return b.ratingCount.compareTo(a.ratingCount);
        });

        // Limit to top 8 recommendations
        final recommendedProducts = products.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended for You',
                      style: AppTextStyles.sectionHeading.copyWith(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = recommendedProducts[index];
                  return _RecommendedProductCard(product: product);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final ProductModel product;

  const _RecommendedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    final existingItem = cart.items.cast<CartItemModel?>().firstWhere(
          (item) => item?.productId == product.id,
          orElse: () => null,
        );

    final isInCart = existingItem != null;

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 95,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 95,
                      color: AppColors.surfaceVariant,
                      child: Icon(Icons.fastfood, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              if (product.rating >= 4.0)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star_rounded, color: AppColors.white, size: 10),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.productName.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.description.isNotEmpty ? product.description : product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.supporting.copyWith(fontSize: 11),
                  ),
                  const Spacer(),
                  // Price and Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: AppTextStyles.price.copyWith(fontSize: 13),
                        ),
                      ),
                      // Add Button
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInCart ? AppColors.success : AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (existingItem != null) {
                              cart.incrementQty(existingItem.lineKey);
                            } else {
                              cart.addItem(CartItemModel.fromProduct(product));
                            }
                          },
                          child: Text(
                            existingItem != null ? 'ADD (${existingItem.quantity})' : 'ADD',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
