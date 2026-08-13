import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_list_card.dart';
import '../../widgets/animated_cart_bar.dart';
import '../product/product_detail_screen.dart';

/// Full shop page showing all products from a single shop, grouped by category.
class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopScreen({super.key, required this.shop});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ProductService _productService;
  String _selectedCategory = '';
  bool _isFavorite = false;

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
    final cuisine = shop['tagline'] as String? ?? '';
    final rating = (shop['rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = shop['ratingCount'] ?? 0;
    final deliveryMin = shop['deliveryTimeMin'] ?? 30;
    final deliveryMax = shop['deliveryTimeMax'] ?? 50;
    final distanceKm = (shop['distanceKm'] as num?)?.toDouble();
    final imageUrl = shop['imageUrl'] as String? ?? '';
    final isPureVeg = shop['isVeg'] as bool? ?? false;
    final freeDeliveryAbove = shop['freeDeliveryThreshold'] ?? 49;
    final modeColors = AppColors.modeGradient(mode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          StreamBuilder<List<ProductModel>>(
            stream: _productService.streamProducts(
              mode: mode,
              shopId: shopId,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('streamProducts error for shopId=$shopId: ${snapshot.error}');
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textSecondary,
                      title: Text(
                        shopName,
                        style: AppTextStyles.shopName.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 40, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load products',
                              style: AppTextStyles.sectionHeading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.supporting.copyWith(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              final products = snapshot.data ?? [];

              final Map<String, List<ProductModel>> grouped = {};
              for (final p in products) {
                grouped.putIfAbsent(p.category, () => []).add(p);
              }
              final categories = grouped.keys.toList();

              final popular = [...products]..sort((a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000)));
              final popularItems = popular.take(8).toList();

              return CustomScrollView(
                slivers: [
                  // ── Hero Image + Floating Icons ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                          child: SizedBox(
                            height: 240,
                            width: double.infinity,
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      decoration: BoxDecoration(gradient: LinearGradient(colors: modeColors)),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(gradient: LinearGradient(colors: modeColors)),
                                  ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _CircleIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                                Row(
                                  children: [
                                    _CircleIconButton(icon: Icons.share_rounded, onTap: () {}),
                                    const SizedBox(width: 8),
                                    _CircleIconButton(
                                      icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      iconColor: _isFavorite ? AppColors.error : null,
                                      onTap: () => setState(() => _isFavorite = !_isFavorite),
                                    ),
                                    const SizedBox(width: 8),
                                    _CircleIconButton(icon: Icons.more_horiz_rounded, onTap: () {}),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isPureVeg)
                          Positioned(
                            bottom: 0,
                            left: 16,
                            child: Transform.translate(
                              offset: const Offset(0, 20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.10),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco_rounded, size: 15, color: AppColors.success),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pure Veg',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 12.5,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Shop Info Block ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  shopName,
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    height: 1.15,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (rating > 0) ...[
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: AppTextStyles.badge.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(Icons.star_rounded, color: AppColors.white, size: 14),
                                        ],
                                      ),
                                    ),
                                    if (ratingCount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatCount(ratingCount)} ratings',
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (cuisine.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              isPureVeg ? '$cuisine • Pure Veg' : cuisine,
                              style: AppTextStyles.supporting.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              if (distanceKm != null) ...[
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km',
                                  style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textMedium),
                                ),
                                const SizedBox(width: 10),
                                Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(width: 10),
                              ],
                              Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '$deliveryMin–$deliveryMax mins',
                                style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.textMedium),
                              ),
                              const SizedBox(width: 10),
                              Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(width: 10),
                              Text(
                                'Schedule for later',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FeatureChip(label: 'No packaging charges'),
                              _FeatureChip(label: 'Frequently reordered'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ── Free Delivery Banner ─────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Free Delivery above ₹$freeDeliveryAbove',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Offers',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ── Category Pill Tabs ──────────────────────────────────────
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

                  // ── Recommended For You ─────────────────────────────────────
                  if (_selectedCategory.isEmpty && popularItems.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                        child: Text(
                          'Recommended for you',
                          style: AppTextStyles.sectionHeading.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = popularItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ProductListCard(
                                product: product,
                                highlyReordered: product.rating >= 4.0,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(productId: product.id),
                                  ),
                                ),
                                onAdd: () {
                                  context.read<CartService>().addItem(
                                        CartItemModel.fromProduct(product, shopName: shopName),
                                      );
                                },
                              ),
                            );
                          },
                          childCount: popularItems.length,
                        ),
                      ),
                    ),
                  ],

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
                      (snapshot.hasData &&
                          products.isEmpty &&
                          snapshot.connectionState != ConnectionState.waiting))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text(
                            'No products available yet',
                            style: AppTextStyles.supporting.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ),

                  // ── Products by Category ───────────────────────────────────
                  for (final category in categories) ...[
                    if (_selectedCategory.isEmpty || _selectedCategory == category) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          child: Text(
                            category,
                            style: AppTextStyles.sectionHeading.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = grouped[category]![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ProductListCard(
                                  product: product,
                                  highlyReordered: product.rating >= 4.0,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(productId: product.id),
                                    ),
                                  ),
                                  onAdd: () {
                                    context.read<CartService>().addItem(
                                          CartItemModel.fromProduct(product, shopName: shopName),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
          const AnimatedCartBar(),
        ],
      ),
    );
  }

  String _formatCount(dynamic count) {
    final n = (count is num) ? count.toInt() : int.tryParse('$count') ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleIconButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppColors.textDark),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

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
      color: AppColors.surface,
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = index == 0 ? '' : categories[index - 1];
          final label = index == 0 ? 'Recommended' : cat;
          final isSelected = selected == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  width: 1.4,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: isSelected ? AppColors.white : AppColors.textMedium,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}