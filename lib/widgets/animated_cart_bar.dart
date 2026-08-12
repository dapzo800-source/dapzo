import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../screens/cart/cart_screen.dart';

/// Floating cart-summary bar shown while browsing a menu.
///
/// Drop it as the LAST child of a [Stack] that wraps a screen's scrollable
/// body so it floats above the content and stays pinned to the bottom:
///
/// ```dart
/// Scaffold(
///   body: Stack(
///     children: [
///       CustomScrollView(...),      // the menu / product list
///       const AnimatedCartBar(),    // always last, so it draws on top
///     ],
///   ),
/// )
/// ```
///
/// It listens to [CartService] and animates itself in with a slide-up +
/// fade whenever the cart goes from empty → non-empty, and slides back
/// down when the cart is cleared. Tapping it opens [CartScreen].
class AnimatedCartBar extends StatefulWidget {
  const AnimatedCartBar({super.key});

  @override
  State<AnimatedCartBar> createState() => _AnimatedCartBarState();
}

class _AnimatedCartBarState extends State<AnimatedCartBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // If the cart already has items when this screen mounts (e.g. the user
    // came back from another tab), show the bar immediately without
    // animating from scratch.
    if (!context.read<CartService>().isEmpty) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Consumer<CartService>(
        builder: (context, cart, _) {
          // Drive the animation off cart state. Calling forward()/reverse()
          // repeatedly is safe — it's a no-op once the target is reached.
          if (cart.isEmpty) {
            _controller.reverse();
          } else {
            _controller.forward();
          }

          return IgnorePointer(
            ignoring: cart.isEmpty,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _CartBarContent(cart: cart),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BAR CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _CartBarContent extends StatelessWidget {
  final CartService cart;
  const _CartBarContent({required this.cart});

  @override
  Widget build(BuildContext context) {
    // Guard against building with a stale (empty) cart while the bar is
    // still animating out.
    final itemCount = cart.itemCount;
    final subtotal = cart.subtotal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Bag icon with item-count badge ──────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.white,
                      size: 19,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$itemCount',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Item count + subtotal ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$itemCount ${itemCount == 1 ? 'Item' : 'Items'}  |  ₹${subtotal.toStringAsFixed(0)}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Extra charges may apply',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── View Cart button ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Cart',
                      style: AppTextStyles.badge.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.white,
                      size: 15,
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
}