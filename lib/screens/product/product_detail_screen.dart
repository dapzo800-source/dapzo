import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productService = ProductService();
  int _quantity = 1;
  String? _selectedWeight;
  final _instructionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ProductModel?>(
        future: _productService.getProduct(widget.productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snapshot.data;
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          final hasWeights = product.weightOptions.isNotEmpty;
          final selectedWeightOption = hasWeights
              ? product.weightOptions.firstWhere(
                  (w) => w.label == _selectedWeight,
                  orElse: () => product.weightOptions.first,
                )
              : null;
          _selectedWeight ??= selectedWeightOption?.label;
          final unitPrice = selectedWeightOption?.price ?? product.price;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.textDark,
                expandedHeight: 260,
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background,
                      child: Icon(
                        product.mode == 'meat' ? Icons.set_meal_outlined : Icons.restaurant_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppTextStyles.heading.copyWith(fontSize: 22)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating.toStringAsFixed(1)} (${product.ratingCount})',
                            style: AppTextStyles.supporting,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(product.description, style: AppTextStyles.body),
                      if (hasWeights) ...[
                        const SizedBox(height: 20),
                        Text('Available Weight / Size', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: product.weightOptions.map((w) {
                            final selected = w.label == _selectedWeight;
                            return ChoiceChip(
                              label: Text('${w.label} · ₹${w.price.toStringAsFixed(0)}'),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedWeight = w.label),
                              selectedColor: AppColors.primary.withOpacity(0.12),
                              labelStyle: AppTextStyles.body.copyWith(
                                color: selected ? AppColors.primary : AppColors.textDark,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${unitPrice.toStringAsFixed(0)}${hasWeights ? '' : ' / ${product.unit}'}',
                            style: AppTextStyles.heading.copyWith(fontSize: 20, color: AppColors.primary),
                          ),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () => setState(() {
                                  if (_quantity > 1) _quantity--;
                                }),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text('$_quantity', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              ),
                              _QtyButton(icon: Icons.add, onTap: () => setState(() => _quantity++)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Special Instructions', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _instructionsController,
                        maxLines: 2,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(hintText: 'E.g. less spicy, no onions'),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<ProductModel?>(
            future: _productService.getProduct(widget.productId),
            builder: (context, snapshot) {
              final product = snapshot.data;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: product == null
                      ? null
                      : () {
                          final selectedOption = product.weightOptions.isNotEmpty
                              ? product.weightOptions.firstWhere(
                                  (w) => w.label == _selectedWeight,
                                  orElse: () => product.weightOptions.first,
                                )
                              : null;

                          context.read<CartService>().addItem(
                                CartItemModel.fromProduct(
                                  product,
                                  selectedWeight: selectedOption?.label,
                                  weightPrice: selectedOption?.price,
                                  quantity: _quantity,
                                  specialInstructions: _instructionsController.text.trim().isEmpty
                                      ? null
                                      : _instructionsController.text.trim(),
                                ),
                              );

                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                  child: const Text('Add to Cart'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textDark),
      ),
    );
  }
}
