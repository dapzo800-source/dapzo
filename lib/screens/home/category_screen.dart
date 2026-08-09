import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class CategoryScreen extends StatelessWidget {
  final String mode;
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.streamProducts(
          mode: mode,
          categoryId: categoryId,
        ),
        builder: (context, snapshot) {
          // Show actual Firebase error
          if (snapshot.hasError) {
            debugPrint(
              'CATEGORY PRODUCTS ERROR: ${snapshot.error}',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load products.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.supporting,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products found',
                style: AppTextStyles.supporting,
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        productId: product.id,
                      ),
                    ),
                  );
                },
                onAdd: () {
                  context
                      .read<CartService>()
                      .addItem(
                        CartItemModel.fromProduct(product),
                      );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${product.name} added to cart',
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