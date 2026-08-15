import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';

/// Product detail page — built to mirror [ShopScreen]'s exact visual
/// language rather than invent a new one:
///  - Same 240px hero image + floating circle icon buttons.
///  - Same floating chip style used for "Pure Veg" (white pill, shadow,
///    icon + label) now used for the veg/non-veg indicator.
///  - Same typography scale: title 26/w800, rating badge identical,
///    supporting line 14/w500, feature chips identical to ShopScreen's
///    `_FeatureChip`.
///  - Same soft-shadow / 8px spacing rhythm throughout.
///
/// The "Add to cart" bar is a fixed bottom bar that slides up into view
/// (rather than appearing statically) once the product has loaded.
///
/// NOTE: relies on `ProductService.getProduct(id)` — confirmed to match
/// your actual service.
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late final ProductService _productService;
  late Future<ProductModel?> _productFuture;
  late final AnimationController _barController;
  late final Animation<Offset> _barSlide;

  int _quantity = 1;
  bool _barRevealed = false;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _productFuture = _productService.getProduct(widget.productId);

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _barSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  void _revealBarOnce() {
    if (_barRevealed) return;
    _barRevealed = true;
    // Let the first frame settle, then slide the bar up into view.
    WidgetsBinding.instance.addPostFrameCallback((_) => _barController.forward());
  }

  bool _isVeg(ProductModel product) =>
      product.mode == 'food' &&
      !product.name.toLowerCase().contains('chicken') &&
      !product.name.toLowerCase().contains('mutton') &&
      !product.name.toLowerCase().contains('beef') &&
      !product.name.toLowerCase().contains('prawn') &&
      !product.name.toLowerCase().contains('fish') &&
      !product.name.toLowerCase().contains('salmon');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ProductModel?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textDark,
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
                          'Unable to load product',
                          style: AppTextStyles.sectionHeading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (snapshot.hasError) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.supporting.copyWith(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final product = snapshot.data!;
          final isVeg = _isVeg(product);
          final highlyReordered = product.rating >= 4.0;

          _revealBarOnce();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Hero Image + Floating Icons (identical to ShopScreen) ──
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: Center(
                                      child: Icon(
                                        product.mode == 'meat'
                                            ? Icons.set_meal_outlined
                                            : Icons.restaurant_outlined,
                                        color: AppColors.textSecondary,
                                        size: 40,
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
                                      size: 40,
                                    ),
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
                                    _CircleIconButton(
                                      icon: Icons.share_rounded,
                                      onTap: () {
                                        Share.share(
                                          'Check out "${product.name}" on Dapzo for ₹${product.price.toStringAsFixed(0)}! Download Dapzo for fresh food and meat delivery.',
                                          subject: product.name,
                                        );
                                      },
                                    ),
                                    StreamBuilder<bool>(
                                      stream: FavoritesService().streamIsFavorite(
                                        FirebaseAuth.instance.currentUser?.uid ?? '',
                                        product.id,
                                      ),
                                      builder: (context, snapshot) {
                                        final isFav = snapshot.data ?? false;
                                        return _CircleIconButton(
                                          icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          iconColor: isFav ? AppColors.error : null,
                                          onTap: () async {
                                            final uid = FirebaseAuth.instance.currentUser?.uid;
                                            if (uid == null || uid.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Please sign in to add favorites')),
                                              );
                                              return;
                                            }
                                            await FavoritesService().toggleFavorite(uid, product.id);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Veg / Non-veg floating chip — same visual treatment
                        // as ShopScreen's "Pure Veg" chip.
                        Positioned(
                          bottom: 0,
                          left: 16,
                          child: Transform.translate(
                            offset: const Offset(0, 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.white,
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
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: isVeg ? AppColors.success : AppColors.error,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isVeg ? AppColors.success : AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isVeg ? 'Veg' : 'Non-Veg',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12.5,
                                      color: isVeg ? AppColors.success : AppColors.error,
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

                  // ── Product Info Block (mirrors ShopScreen's info block) ──
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
                                  product.name,
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    height: 1.15,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (product.rating > 0) ...[
                                const SizedBox(width: 12),
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
                                        product.rating.toStringAsFixed(1),
                                        style: AppTextStyles.badge.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(Icons.star_rounded, color: AppColors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (product.category.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              product.category,
                              style: AppTextStyles.supporting.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: AppTextStyles.price.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (highlyReordered)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _FeatureChip(label: 'Highly reordered', icon: Icons.star_rounded),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (product.description.isNotEmpty) ...[
                            Text(
                              'About this item',
                              style: AppTextStyles.sectionHeading.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.description,
                              style: AppTextStyles.supporting.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── More from this Shop ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'More from this Shop',
                              style: AppTextStyles.sectionHeading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: StreamBuilder<List<ProductModel>>(
                              stream: ProductService().streamProducts(
                                mode: product.mode,
                                shopId: product.shopId,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error loading products', style: AppTextStyles.supporting));
                                }
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                // Filter out current product
                                final products = snapshot.data!.where((p) => p.id != product.id).toList();
                                
                                if (products.isEmpty) {
                                  return Center(child: Text('No other items found', style: AppTextStyles.supporting));
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: products.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final p = products[index];
                                    return SizedBox(
                                      width: 160,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppColors.divider),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                child: Image.network(
                                                  p.imageUrl,
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    height: 120,
                                                    color: AppColors.surfaceVariant,
                                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      p.name,
                                                      style: AppTextStyles.productName.copyWith(fontSize: 14),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '₹${p.price.toStringAsFixed(0)}',
                                                      style: AppTextStyles.price.copyWith(fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),

              // ── Sticky Bottom Bar: slides up into view once loaded ──────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _barSlide,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _QuantityStepper(
                            quantity: _quantity,
                            onDecrement: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                            onIncrement: () => setState(() => _quantity++),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                final cartService = context.read<CartService>();
                                for (var i = 0; i < _quantity; i++) {
                                  cartService.addItem(CartItemModel.fromProduct(product));
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$_quantity item(s) added to cart'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text(
                                'Add to cart · ₹${(product.price * _quantity).toStringAsFixed(0)}',
                                style: AppTextStyles.badge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCLE ICON BUTTON — identical to ShopScreen's _CircleIconButton
// ─────────────────────────────────────────────────────────────────────────────

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
        child: Icon(icon, size: 19, color: iconColor ?? AppColors.textDark),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE CHIP — identical to ShopScreen's _FeatureChip, icon configurable
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureChip({required this.label, this.icon = Icons.check_circle_rounded});

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
          Icon(icon, size: 14, color: AppColors.success),
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

// ─────────────────────────────────────────────────────────────────────────────
// QUANTITY STEPPER
// ─────────────────────────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(Icons.remove, color: AppColors.primary, size: 18),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.badge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}