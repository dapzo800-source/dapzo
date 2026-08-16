import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Modern, interactive list-style product card with tactile touch animations.
/// Designed for maximum engagement:
///  - Smooth spring press micro-interaction on tap
///  - Full product name displayed clearly with zero truncation
///  - Veg / Non-Veg badge with crisp indicator
///  - Animated ADD / Stepper button with haptic feedback
class ProductListCard extends StatefulWidget {
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

  @override
  State<ProductListCard> createState() => _ProductListCardState();
}

class _ProductListCardState extends State<ProductListCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
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

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Image with Veg Badge ─────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _imagePlaceholder(),
                              errorWidget: (_, __, ___) => _imageError(),
                            )
                          : _imageError(),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _VegBadge(isVeg: _isVeg),
                  ),
                  if (widget.highlyReordered)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.star_rounded, size: 11, color: AppColors.warning),
                            SizedBox(width: 2),
                            Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Details ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full product name — wraps naturally with zero ellipsis truncation
                    Text(
                      product.name,
                      style: AppTextStyles.productName.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.25,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: AppTextStyles.supporting.copyWith(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Price + Add / Stepper control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: AppTextStyles.price.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: AppColors.textDark,
                          ),
                        ),
                        _CartControl(
                          product: product,
                          onAdd: widget.onAdd,
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
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );

  Widget _imageError() => Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(
            widget.product.mode == 'meat' ? Icons.set_meal_outlined : Icons.restaurant_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CART CONTROL — shows "ADD +" with haptic tap or active live stepper
// ─────────────────────────────────────────────────────────────────────────────

class _CartControl extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _CartControl({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final matchingItems = cart.items.where((item) => item.productId == product.id).toList();
    final quantity = matchingItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: quantity <= 0
          ? _AddButtonOutlined(
              key: const ValueKey('add'),
              onTap: () {
                HapticFeedback.lightImpact();
                onAdd();
              },
            )
          : _QuantityStepperButton(
              key: const ValueKey('stepper'),
              quantity: quantity,
              onIncrement: () {
                HapticFeedback.selectionClick();
                if (matchingItems.isNotEmpty) {
                  context.read<CartService>().incrementQty(matchingItems.first.lineKey);
                } else {
                  onAdd();
                }
              },
              onDecrement: () {
                HapticFeedback.selectionClick();
                if (matchingItems.isNotEmpty) {
                  context.read<CartService>().decrementQty(matchingItems.first.lineKey);
                }
              },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADD',
                style: AppTextStyles.badge.copyWith(
                  fontSize: 12.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.add_rounded, color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUANTITY STEPPER BUTTON
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIcon(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.badge.copyWith(
                fontSize: 13.5,
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepperIcon(icon: Icons.add_rounded, onTap: onIncrement),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: AppColors.white, size: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VEG / NON-VEG BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _VegBadge extends StatelessWidget {
  final bool isVeg;
  const _VegBadge({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isVeg ? AppColors.success : AppColors.error,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
