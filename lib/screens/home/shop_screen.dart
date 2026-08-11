import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

/// Full shop page showing all products from a single shop,
/// grouped by category. Zomato restaurant-style menu layout.
class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopScreen({super.key, required this.shop});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ProductService _productService;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final shopId = shop['id'] as String;
    final mode = shop['mode'] as String? ?? 'food';
    final shopName = shop['name'] as String? ?? '';
    final tagline = shop['tagline'] as String? ?? '';
    final rating = (shop['rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = shop['ratingCount'] ?? 0;
    final deliveryMin = shop['deliveryTimeMin'] ?? 30;
    final deliveryMax = shop['deliveryTimeMax'] ?? 50;
    final deliveryFee = shop['deliveryFee'] ?? 0;
    final imageUrl = shop['imageUrl'] as String? ?? '';
    final modeColors = AppColors.modeGradient(mode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<ProductModel>>(
        stream: _productService.streamProducts(
          mode: mode,
          shopId: shopId,
          limit: 100,
        ),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];

          // Group products by category
          final Map<String, List<ProductModel>> grouped = {};
          for (final p in products) {
            grouped.putIfAbsent(p.category, () => []).add(p);
          }
          final categories = grouped.keys.toList();

          return CustomScrollView(
            slivers: [
              // ── Shop Hero App Bar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: modeColors),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: modeColors),
                          ),
                        ),
                      // Dark overlay
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x44000000),
                              Color(0xBB000000),
                            ],
                          ),
                        ),
                      ),
                      // Shop info at bottom of hero
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: AppTextStyles.shopName
                                  .copyWith(color: AppColors.white, fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tagline,
                              style: AppTextStyles.supporting
                                  .copyWith(color: AppColors.glassOverlay.withValues(alpha: 0.9)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.star_rounded,
                                  label:
                                      '${ rating.toStringAsFixed(1)} ($ratingCount)',
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.access_time_rounded,
                                  label: '$deliveryMin–$deliveryMax min',
                                  color: AppColors.glassDark,
                                ),
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.delivery_dining_rounded,
                                  label: deliveryFee == 0
                                      ? 'Free Delivery'
                                      : '₹$deliveryFee delivery',
                                  color: AppColors.glassDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Category Filter Tabs ──────────────────────────────────
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: _CategoryTabs(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelect: (cat) => setState(() {
                      _selectedCategory = cat == _selectedCategory ? '' : cat;
                    }),
                  ),
                ),

              // ── Loading ───────────────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // ── Empty ─────────────────────────────────────────────────
              if (!snapshot.hasData ||
                  (snapshot.hasData && products.isEmpty &&
                      snapshot.connectionState != ConnectionState.waiting))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'No products available yet',
                        style: AppTextStyles.supporting,
                      ),
                    ),
                  ),
                ),

              // ── Products by Category ───────────────────────────────────
              for (final category in categories) ...[
                if (_selectedCategory.isEmpty ||
                    _selectedCategory == category) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        category,
                        style: AppTextStyles.sectionHeading,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = grouped[category]![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ProductCard(
                              product: product,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                      productId: product.id),
                                ),
                              ),
                              onAdd: () {
                                context.read<CartService>().addItem(
                                      CartItemModel.fromProduct(product),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${product.name} added to cart'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: grouped[category]!.length,
                      ),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY TABS
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selected == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 13),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.badge.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
