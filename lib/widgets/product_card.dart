import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Zomato-style full-image product card used in home screen listings.
/// Full-width card with a large hero image, gradient overlay,
/// product name, description snippet, and price + ADD button below.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final String? shopName;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Image ───────────────────────────────────────────────
            _buildHeroImage(),
            // ── Info Section ─────────────────────────────────────────────
            _buildInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _imagePlaceholder(),
              errorWidget: (_, __, ___) => _imageError(),
            ),
          ),
        ),

        // Gradient overlay at bottom of image
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Rating badge — top right
        Positioned(
          top: 10,
          right: 10,
          child: _RatingBadge(rating: product.rating),
        ),

        // Shop badge — top center (if provided)
        if (shopName != null)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: _ShopBadge(name: shopName!),
            ),
          ),

        // Veg / Non-veg dot — bottom left of image
        Positioned(
          bottom: 10,
          left: 12,
          child: _VegDot(isVeg: product.mode == 'food' &&
              !product.name.toLowerCase().contains('chicken') &&
              !product.name.toLowerCase().contains('mutton') &&
              !product.name.toLowerCase().contains('beef') &&
              !product.name.toLowerCase().contains('prawn') &&
              !product.name.toLowerCase().contains('fish') &&
              !product.name.toLowerCase().contains('salmon')),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            product.name,
            style: AppTextStyles.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            product.description,
            style: AppTextStyles.supporting,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Price + Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: AppTextStyles.price,
                  ),
                  Text(
                    'per ${product.unit}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              _AddButton(onTap: onAdd),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _imageError() => Container(
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
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT HORIZONTAL CARD (for popular section)
// ─────────────────────────────────────────────────────────────────────────────

class ProductCardHorizontal extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceVariant,
                    child: Icon(Icons.restaurant_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.productName.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTextStyles.priceSmall,
                      ),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('ADD', style: AppTextStyles.badge),
                        ),
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.white, size: 16),
            const SizedBox(width: 4),
            Text('ADD', style: AppTextStyles.badge),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.badge.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ShopBadge extends StatelessWidget {
  final String name;
  const _ShopBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: AppTextStyles.badge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(3),
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
