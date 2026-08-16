import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Clean, modern Shop Screen showing store details, categorized product list,
/// interactive swipe-up product bottom sheet with delivery preferences, and live bottom cart bar.
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
    final shopId = shop['id'] as String? ?? '';
    final mode = shop['mode'] as String? ?? 'food';
    final shopName = shop['name'] as String? ?? 'Shop';
    final cuisine = shop['tagline'] as String? ?? '';
    final rating = (shop['rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = shop['ratingCount'] ?? 0;
    final deliveryMin = shop['deliveryTimeMin'] ?? 25;
    final deliveryMax = shop['deliveryTimeMax'] ?? 40;
    final distanceKm = (shop['distanceKm'] as num?)?.toDouble();
    final imageUrl = shop['imageUrl'] as String? ?? '';
    final isPureVeg = shop['isVeg'] as bool? ?? false;
    final modeColors = AppColors.modeGradient(mode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          StreamBuilder<List<ProductModel>>(
            stream: _productService.streamShopProducts(shopId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textDark,
                      title: Text(
                        shopName,
                        style: AppTextStyles.heading.copyWith(fontSize: 18),
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
                            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load products',
                              style: AppTextStyles.heading.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.supporting.copyWith(fontSize: 13),
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
                grouped.putIfAbsent(p.category.isNotEmpty ? p.category : 'Menu', () => []).add(p);
              }
              final categories = grouped.keys.toList();

              final popular = [...products]..sort((a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000)));
              final popularItems = popular.take(8).toList();

              return CustomScrollView(
                slivers: [
                  // ── Hero Banner + Navigation ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    decoration: BoxDecoration(gradient: LinearGradient(colors: modeColors)),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    decoration: BoxDecoration(gradient: LinearGradient(colors: modeColors)),
                                    child: const Center(
                                      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 48),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(gradient: LinearGradient(colors: modeColors)),
                                  child: const Center(
                                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: 48),
                                  ),
                                ),
                        ),
                        // Dark top overlay for icon contrast
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _CircleIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                                _CircleIconButton(
                                  icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  iconColor: _isFavorite ? AppColors.error : null,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _isFavorite = !_isFavorite);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Pure Veg Floating Badge
                        if (isPureVeg)
                          Positioned(
                            bottom: 12,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.eco_rounded, size: 15, color: AppColors.success),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Pure Veg',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Clean Shop Info Card ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.divider.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                      ),
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (rating > 0) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (cuisine.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              isPureVeg ? '$cuisine • Pure Veg' : cuisine,
                              style: AppTextStyles.supporting.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Delivery distance & time info row
                          Row(
                            children: [
                              if (distanceKm != null) ...[
                                const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('•', style: TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(width: 10),
                              ],
                              Icon(Icons.access_time_filled_rounded, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '$deliveryMin–$deliveryMax mins delivery',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (ratingCount > 0) ...[
                                const SizedBox(width: 10),
                                Text('•', style: TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(width: 10),
                                Text(
                                  '${_formatCount(ratingCount)} ratings',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _FeatureChip(label: 'No packaging charges'),
                              _FeatureChip(label: 'Fresh & Hygienic'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Category Filter Tabs (Interactive across all categories) ──
                  if (categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _CategoryFilterPill(
                                label: 'All Items',
                                count: products.length,
                                isSelected: _selectedCategory.isEmpty,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategory = '');
                                },
                              ),
                              ...categories.map((cat) {
                                final count = grouped[cat]?.length ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _CategoryFilterPill(
                                    label: cat,
                                    count: count,
                                    isSelected: _selectedCategory == cat,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedCategory = cat;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Recommended Section ──────────────────────────────────
                  if (_selectedCategory.isEmpty && popularItems.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'Recommended for you',
                              style: AppTextStyles.sectionHeading.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${popularItems.length}',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = popularItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProductListCard(
                                product: product,
                                highlyReordered: product.rating >= 4.0,
                                onTap: () => _openProductBottomSheet(context, product, shopName),
                                onAdd: () => _openProductBottomSheet(context, product, shopName),
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
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                    ),

                  // ── Empty State ───────────────────────────────────────────
                  if (!snapshot.hasData ||
                      (snapshot.hasData &&
                          products.isEmpty &&
                          snapshot.connectionState != ConnectionState.waiting))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text(
                            'No products available in this store yet',
                            style: AppTextStyles.supporting.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ),

                  // ── Products Grouped by Category ──────────────────────────
                  for (final category in categories) ...[
                    if (_selectedCategory.isEmpty || _selectedCategory == category) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            children: [
                              Text(
                                category,
                                style: AppTextStyles.sectionHeading.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${grouped[category]!.length}',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
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
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ProductListCard(
                                  product: product,
                                  highlyReordered: product.rating >= 4.0,
                                  onTap: () => _openProductBottomSheet(context, product, shopName),
                                  onAdd: () => _openProductBottomSheet(context, product, shopName),
                                ),
                              );
                            },
                            childCount: grouped[category]!.length,
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Bottom spacer so all content is scrollable above the floating cart dock
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              );
            },
          ),

          // ── Bottom Floating Cart Section ──
          const AnimatedCartBar(),
        ],
      ),
    );
  }

  void _openProductBottomSheet(BuildContext context, ProductModel product, String shopName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (modalContext) => _ProductDetailsBottomSheet(
        product: product,
        shopName: shopName,
      ),
    );
  }

  String _formatCount(dynamic count) {
    final n = (count is num) ? count.toInt() : int.tryParse('$count') ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DETAILS SWIPE-UP BOTTOM SHEET (With Delivery & Cooking Instructions)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductDetailsBottomSheet extends StatefulWidget {
  final ProductModel product;
  final String shopName;

  const _ProductDetailsBottomSheet({
    required this.product,
    required this.shopName,
  });

  @override
  State<_ProductDetailsBottomSheet> createState() => _ProductDetailsBottomSheetState();
}

class _ProductDetailsBottomSheetState extends State<_ProductDetailsBottomSheet> {
  int _quantity = 1;
  final TextEditingController _instructionsController = TextEditingController();
  final Set<String> _selectedPreferences = {};

  static const List<String> _preferenceOptions = [
    'Leave at door 🚪',
    'Don\'t ring bell 🔕',
    'Avoid cutlery 🍴',
    'Extra spicy 🌶️',
    'Less spicy 🥬',
    'Extra sauce / chutney 🥣',
    'Extra napkins 🧻',
    'Contactless delivery 📦',
  ];

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  bool get _isVeg =>
      widget.product.mode == 'food' &&
      !widget.product.name.toLowerCase().contains('chicken') &&
      !widget.product.name.toLowerCase().contains('mutton') &&
      !widget.product.name.toLowerCase().contains('beef') &&
      !widget.product.name.toLowerCase().contains('prawn') &&
      !widget.product.name.toLowerCase().contains('fish') &&
      !widget.product.name.toLowerCase().contains('salmon');

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag Handle (Swipe up to expand, down to collapse) ──
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              // ── Scrollable Content ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  children: [
                    // Product Image with Veg/Non-Veg Tag
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            height: 190,
                            width: double.infinity,
                            child: product.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceVariant,
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: Center(
                                        child: Icon(
                                          product.mode == 'meat'
                                              ? Icons.set_meal_outlined
                                              : Icons.restaurant_outlined,
                                          color: AppColors.textSecondary,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.surfaceVariant,
                                    child: Center(
                                      child: Icon(
                                        product.mode == 'meat'
                                            ? Icons.set_meal_outlined
                                            : Icons.restaurant_outlined,
                                        color: AppColors.textSecondary,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: _isVeg ? AppColors.success : AppColors.error,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _isVeg ? AppColors.success : AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isVeg ? 'Veg' : 'Non-Veg',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _isVeg ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Full Product Name (wraps naturally without truncation)
                    Text(
                      product.name,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Category & Store row
                    Row(
                      children: [
                        if (product.category.isNotEmpty) ...[
                          Text(
                            product.category,
                            style: AppTextStyles.supporting.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.shopName,
                          style: AppTextStyles.supporting.copyWith(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Price
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),

                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Description',
                        style: AppTextStyles.sectionHeading.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: AppTextStyles.supporting.copyWith(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Active Delivery & Cooking Instructions ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Delivery & Cooking Preferences',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Quick Options (tap to select):',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Selectable Preference Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _preferenceOptions.map((pref) {
                              final isSelected = _selectedPreferences.contains(pref);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPreferences.remove(pref);
                                    } else {
                                      _selectedPreferences.add(pref);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.divider,
                                      width: 1.2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        pref,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          // Custom Notes Input Field
                          TextField(
                            controller: _instructionsController,
                            maxLines: 2,
                            maxLength: 140,
                            style: AppTextStyles.body.copyWith(fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Add custom notes (e.g. less oil, extra chutney, gate code)...',
                              hintStyle: AppTextStyles.supporting.copyWith(
                                fontSize: 12.5,
                                color: AppColors.textHint,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              counterStyle: AppTextStyles.caption.copyWith(fontSize: 10.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Pinned Bottom Bar: Stepper & Add to Cart ──
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Quantity Stepper
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              color: AppColors.textDark,
                              splashRadius: 18,
                            ),
                            SizedBox(
                              width: 26,
                              child: Text(
                                '$_quantity',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.badge.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _quantity++);
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              color: AppColors.primary,
                              splashRadius: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Add to Cart Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              // Build final combined instruction string
                              final parts = <String>[];
                              if (_selectedPreferences.isNotEmpty) {
                                parts.add(_selectedPreferences.join(', '));
                              }
                              final customNote = _instructionsController.text.trim();
                              if (customNote.isNotEmpty) {
                                parts.add(customNote);
                              }
                              final finalInstructions = parts.isNotEmpty ? parts.join(' | ') : null;

                              final cartService = context.read<CartService>();
                              cartService.addItem(
                                CartItemModel(
                                  productId: product.id,
                                  name: product.name,
                                  imageUrl: product.imageUrl,
                                  mode: product.mode,
                                  unitPrice: product.price,
                                  quantity: _quantity,
                                  specialInstructions: finalInstructions,
                                  shopId: product.shopId,
                                  shopName: widget.shopName,
                                  categoryId: product.category,
                                  subcategoryId: product.subCategory,
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Add to Cart  •  ₹${(product.price * _quantity).toStringAsFixed(0)}',
                                style: AppTextStyles.badge.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCLE ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor ?? AppColors.textDark),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY FILTER PILL
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryFilterPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterPill({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.divider.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}