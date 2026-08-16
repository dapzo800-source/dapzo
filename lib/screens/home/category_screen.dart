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

class CategoryScreen extends StatefulWidget {
  final String mode;
  final String categoryId;
  final String categoryName;
  final String? searchQuery;

  const CategoryScreen({
    super.key,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
    this.searchQuery,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final ProductService _productService;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    // Default to the passed categoryName if it's not "All Categories"
    if (widget.categoryName.isNotEmpty &&
        widget.categoryName.toLowerCase() != 'all categories' &&
        widget.categoryName.toLowerCase() != 'all') {
      _selectedCategory = widget.categoryName;
    } else {
      _selectedCategory = '';
    }
  }

  String _getCategoryHeroImage(String name, String mode) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani') || lower.contains('biriyani')) {
      return 'assets/images/biryani_hero.png';
    }
    if (mode == 'meat' ||
        lower.contains('meat') ||
        lower.contains('chicken') ||
        lower.contains('mutton') ||
        lower.contains('prawn') ||
        lower.contains('fish')) {
      return 'assets/images/meat_hero.png';
    }
    return 'assets/images/food_hero.png';
  }

  String _getCravingTagline(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani') || lower.contains('biriyani')) {
      return 'Craving Authentic Biryani? 🍲\nAromatic spices & cooked to perfection.';
    }
    if (lower.contains('prawn') || lower.contains('fish') || lower.contains('sea')) {
      return 'Craving Fresh Seafood? 🦐\nCleaned, deveined & fresh from the catch.';
    }
    if (lower.contains('meat') || lower.contains('chicken') || lower.contains('mutton')) {
      return 'Craving Fresh Raw Cuts? 🥩\n100% fresh, tender & hygienically packed.';
    }
    return 'Craving Something Delicious? ✨\nFreshly prepared & delivered super fast.';
  }

  void _openProductBottomSheet(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (modalContext) => _ProductDetailsBottomSheet(
        product: product,
        shopName: product.category.isNotEmpty ? product.category : 'Dapzo Express',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.categoryColor(widget.categoryName);
    final heroImage = _getCategoryHeroImage(widget.categoryName, widget.mode);
    final cravingTagline = _getCravingTagline(widget.categoryName);

    final titleText = widget.searchQuery != null && widget.searchQuery!.isNotEmpty
        ? 'Search: "${widget.searchQuery}"'
        : (widget.categoryName.isNotEmpty ? widget.categoryName : 'Categories');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          StreamBuilder<List<ProductModel>>(
            stream: _productService.streamProducts(mode: widget.mode),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppColors.surface,
                      title: Text(titleText, style: AppTextStyles.heading.copyWith(fontSize: 18)),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                        child: Center(
                          child: Text(
                            'Unable to load products\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.supporting,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final allProducts = snapshot.data ?? [];

              // Extract all available categories from products
              final Set<String> categoriesSet = {};
              for (final p in allProducts) {
                if (p.category.isNotEmpty) categoriesSet.add(p.category);
                if (p.subCategory.isNotEmpty) categoriesSet.add(p.subCategory);
              }
              final categories = categoriesSet.toList()..sort();

              // Filter products according to search query and selected category
              var filteredProducts = allProducts.where((p) {
                if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
                  final q = widget.searchQuery!.trim().toLowerCase();
                  final match = p.name.toLowerCase().contains(q) ||
                      p.category.toLowerCase().contains(q) ||
                      p.subCategory.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q);
                  if (!match) return false;
                }

                if (_selectedCategory.isNotEmpty) {
                  final sel = _selectedCategory.toLowerCase();
                  final pCat = p.category.toLowerCase();
                  final pSub = p.subCategory.toLowerCase();
                  final pName = p.name.toLowerCase();

                  final matchCategory = pCat == sel ||
                      pSub == sel ||
                      pCat.contains(sel) ||
                      pSub.contains(sel) ||
                      pName.contains(sel);
                  if (!matchCategory) return false;
                }

                return true;
              }).toList();

              return CustomScrollView(
                slivers: [
                  // ── Hero Banner ──────────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 170,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    centerTitle: true,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 14),
                      title: Text(
                        titleText,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            heroImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: accentColor),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            top: 65,
                            right: 16,
                            child: Text(
                              cravingTagline,
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                shadows: const [
                                  Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Category Filter Pills Bar ────────────────────────────
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
                                count: allProducts.length,
                                isSelected: _selectedCategory.isEmpty,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategory = '');
                                },
                              ),
                              ...categories.map((cat) {
                                final count = allProducts.where((p) {
                                  final c = cat.toLowerCase();
                                  return p.category.toLowerCase().contains(c) ||
                                      p.subCategory.toLowerCase().contains(c) ||
                                      p.name.toLowerCase().contains(c);
                                }).length;

                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _CategoryFilterPill(
                                    label: cat,
                                    count: count,
                                    isSelected: _selectedCategory.toLowerCase() == cat.toLowerCase(),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedCategory = (_selectedCategory == cat) ? '' : cat;
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
                  if (filteredProducts.isEmpty &&
                      snapshot.connectionState != ConnectionState.waiting)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'No products found in ${_selectedCategory.isNotEmpty ? _selectedCategory : "this category"}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.supporting.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Product List ──────────────────────────────────────────
                  if (filteredProducts.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filteredProducts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProductListCard(
                                product: product,
                                highlyReordered: product.rating >= 4.0,
                                onTap: () => _openProductBottomSheet(context, product),
                                onAdd: () => _openProductBottomSheet(context, product),
                              ),
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // ── Bottom Cart Dock ──
          const AnimatedCartBar(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DETAILS SWIPE-UP BOTTOM SHEET (With Delivery & Cooking Preferences)
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
              // ── Drag Handle ──
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

                    // Full Product Name (untruncated)
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

                    // ── Active Delivery & Cooking Preferences ──
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

              // ── Pinned Bottom Bar ──
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