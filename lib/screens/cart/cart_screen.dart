import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/cart_service.dart';
import '../../utils/constants.dart';
import 'checkout_screen.dart';

/// Cart screen — deliberately excludes Wallet and Refer & Earn per spec.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    final subtotal = cart.subtotal;
    const delivery = AppConstants.deliveryChargeDefault;
    const discount = 0.0;
    final tax = subtotal * AppConstants.taxRatePercent / 100;
    final total = subtotal + delivery - discount + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('Your cart is empty', style: AppTextStyles.supporting),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppColors.background,
                                child: const Icon(Icons.fastfood, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.selectedWeight != null
                                      ? '${item.name} · ${item.selectedWeight}'
                                      : item.name,
                                  style: AppTextStyles.productName,
                                ),
                                const SizedBox(height: 2),
                                Text('₹${item.unitPrice.toStringAsFixed(0)}', style: AppTextStyles.supporting),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _QtyBtn(
                                icon: Icons.remove,
                                onTap: () => context.read<CartService>().decrementQty(item.lineKey),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('${item.quantity}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              ),
                              _QtyBtn(
                                icon: Icons.add,
                                onTap: () => context.read<CartService>().incrementQty(item.lineKey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 32),
                _SummaryRow('Subtotal', subtotal),
                _SummaryRow('Delivery', delivery),
                _SummaryRow('Discount', -discount),
                _SummaryRow('Tax', tax),
                const Divider(height: 24),
                _SummaryRow('Total', total, bold: true),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ),
            ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.textDark),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 16)
        : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
