import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// List-style product card — image on the left (square, rounded), details
/// on the right, with a veg/non-veg dot, an optional "Highly reordered"
/// badge, price, and an ADD control that turns into a live +/- quantity
/// stepper once the item is already in the cart.
///
/// Typography and spacing here are tuned deliberately:
///  - Name is the clear focal point (bold, tight letter-spacing).
///  - Description sits one visual step down (muted color, relaxed line-height).
///  - Price is the second focal point, bold and slightly larger than body text.
///  - A soft shadow replaces a hard border for a cleaner, calmer card edge.
class ProductListCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool highlyReordered;

  const ProductListCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.highlyReordered = false,
  });

  bool get _isVeg =>
      product.mode == 'food' &&
      !product.name.toLowerCase().contains('chicken') &&
      !product.name.toLowerCase().contains('mutton') &&
      !product.name.toLowerCase().contains('beef') &&
      !product.name.toLowerCase().contains('prawn') &&
      !product.name.toLowerCase().contains('fish') &&
      !product.name.toLowerCase().contains('salmon');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + veg dot ─────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imagePlaceholder(),
                      errorWidget: (_, __, ___) => _imageError(),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: _VegDot(isVeg: _isVeg),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // ── Details ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.productName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.2,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.description,
                    style: AppTextStyles.supporting.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (highlyReordered) ...[
                    const SizedBox(height: 7),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Highly reordered',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTextStyles.price.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppColors.textDark,
                        ),
                      ),
                      _CartControl(product: product, onAdd: onAdd),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _imageError() => Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(
            product.mode == 'meat' ? Icons.set_meal_outlined : Icons.restaurant_outlined,
            color: AppColors.textSecondary,
            size: 28,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CART CONTROL — shows "ADD +" when the item isn't in the cart yet, and a
// live "− qty +" stepper once it is. Reads CartService directly so it stays
// in sync no matter where the quantity changed (this card, the cart bar,
// the cart screen, product detail, etc).
// ─────────────────────────────────────────────────────────────────────────────

class _CartControl extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _CartControl({required this.product, required this.onAdd});

  /// Cards built from this widget never carry a `selectedWeight`, so the
  /// line key is always the product id with an empty weight segment —
  /// matching `CartItemModel.lineKey` (`'$productId::${selectedWeight ?? ''}'`).
  String get _lineKey => '${product.id}::';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final quantity = cart.items
        .where((item) => item.lineKey == _lineKey)
        .fold<int>(0, (sum, item) => sum + item.quantity);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: quantity <= 0
          ? _AddButtonOutlined(key: const ValueKey('add'), onTap: onAdd)
          : _QuantityStepperButton(
              key: const ValueKey('stepper'),
              quantity: quantity,
              onIncrement: () => context.read<CartService>().incrementQty(_lineKey),
              onDecrement: () => context.read<CartService>().decrementQty(_lineKey),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OUTLINED ADD BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _AddButtonOutlined extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButtonOutlined({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADD',
              style: AppTextStyles.badge.copyWith(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.add, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUANTITY STEPPER BUTTON — replaces ADD once the item is in the cart
// ─────────────────────────────────────────────────────────────────────────────

class _QuantityStepperButton extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepperButton({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIcon(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.badge.copyWith(
                fontSize: 14,
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepperIcon(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Icon(icon, color: AppColors.white, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VEG / NON-VEG DOT
// ─────────────────────────────────────────────────────────────────────────────

class _VegDot extends StatelessWidget {
  final bool isVeg;
  const _VegDot({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isVeg ? AppColors.success : AppColors.error,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}