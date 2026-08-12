import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Data model for recommended items & combo deals in the cart screen.
class RecommendedOption {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final bool isCombo;
  final String? badgeText;
  final List<String>? includedItems;

  const RecommendedOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.isCombo = false,
    this.badgeText,
    this.includedItems,
  });
}

class RecommendedCombosSection extends StatelessWidget {
  const RecommendedCombosSection({super.key});

  static const List<RecommendedOption> _options = [
    // Combo Options
    RecommendedOption(
      id: 'combo_biryani_meal',
      title: 'Mega Biryani Combo',
      subtitle: 'Biryani + Drink + Dessert',
      price: 349,
      originalPrice: 420,
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500',
      isCombo: true,
      badgeText: 'SAVE ₹71',
      includedItems: ['Chicken Biryani (1 Plate)', 'Thums Up (500ml)', 'Gulab Jamun (2 pcs)'],
    ),
    RecommendedOption(
      id: 'combo_meat_feast',
      title: 'Meat Feast Combo',
      subtitle: 'Chicken + Mutton Pack',
      price: 699,
      originalPrice: 799,
      imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=500',
      isCombo: true,
      badgeText: 'SAVE ₹100',
      includedItems: ['500g Fresh Chicken', '500g Mutton Curry Cut', 'Biryani Masala Pack'],
    ),
    RecommendedOption(
      id: 'combo_starter_pack',
      title: 'Starter & Drink Combo',
      subtitle: 'Kabab + Dip + Cold Drink',
      price: 279,
      originalPrice: 330,
      imageUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=500',
      isCombo: true,
      badgeText: 'POPULAR',
      includedItems: ['Chicken Tikka (8 pcs)', 'Garlic Dip', 'Coca-Cola (500ml)'],
    ),
    // Recommended Single Items
    RecommendedOption(
      id: 'rec_thumsup',
      title: 'Thums Up (500ml)',
      subtitle: 'Chilled soft drink',
      price: 40,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500',
      isCombo: false,
    ),
    RecommendedOption(
      id: 'rec_raita_extra',
      title: 'Extra Raita & Salan',
      subtitle: 'Perfect biryani pairing',
      price: 30,
      imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500',
      isCombo: false,
    ),
    RecommendedOption(
      id: 'rec_gulab_jamun',
      title: 'Gulab Jamun (2 Pcs)',
      subtitle: 'Hot & soft dessert',
      price: 60,
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=500',
      isCombo: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Recommended for You',
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 17),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Combos & Add-ons',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final option = _options[index];
              return _RecommendedCard(option: option);
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final RecommendedOption option;

  const _RecommendedCard({required this.option});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    // Check if this item/combo is already in cart
    final existingItem = cart.items.cast<CartItemModel?>().firstWhere(
          (item) => item?.productId == option.id,
          orElse: () => null,
        );

    final isInCart = existingItem != null;

    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: option.isCombo ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
          width: option.isCombo ? 1.5 : 1.0,
        ),
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
          // Image Header with Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: Image.network(
                  option.imageUrl,
                  height: 95,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 95,
                    color: AppColors.surfaceVariant,
                    child: Icon(Icons.fastfood, color: AppColors.textSecondary),
                  ),
                ),
              ),
              if (option.badgeText != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: option.isCombo ? AppColors.primary : AppColors.textDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option.badgeText!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
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
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.productName.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.supporting.copyWith(fontSize: 11),
                  ),
                  const Spacer(),
                  // Price and Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (option.originalPrice != null)
                            Text(
                              '₹${option.originalPrice!.toStringAsFixed(0)}',
                              style: AppTextStyles.caption.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
                            ),
                          Text(
                            '₹${option.price.toStringAsFixed(0)}',
                            style: AppTextStyles.price.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      // Add Button
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInCart ? AppColors.success : AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (isInCart) {
                              cart.incrementQty(existingItem.lineKey);
                            } else {
                              final newItem = CartItemModel(
                                productId: option.id,
                                name: option.title,
                                imageUrl: option.imageUrl,
                                mode: option.isCombo ? 'combo' : 'food',
                                unitPrice: option.price,
                                quantity: 1,
                              );
                              cart.addItem(newItem);
                            }

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${option.title}" to cart!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.textDark,
                              ),
                            );
                          },
                          child: Text(
                            isInCart ? 'ADDED (${existingItem.quantity})' : 'ADD',
                            style: const TextStyle(
                              fontSize: 11,
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
