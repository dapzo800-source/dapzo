import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../state/app_state.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar.dart';

import '../product/product_detail_screen.dart';
import '../location/select_location_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../cart/cart_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartService>().itemCount;

    final pages = [
      const _HomeTab(),
      const CartScreen(embedded: true),
      const OrdersScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _navIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _CartIcon(count: cartCount, filled: false),
            activeIcon: _CartIcon(count: cartCount, filled: true),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CART ICON WITH BADGE
// ============================================================================

class _CartIcon extends StatelessWidget {
  final int count;
  final bool filled;

  const _CartIcon({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(filled ? Icons.shopping_cart : Icons.shopping_cart_outlined);

    if (count <= 0) return icon;

    return Badge(
      label: Text('$count'),
      child: icon,
    );
  }
}

// ============================================================================
// HOME TAB
// ============================================================================

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late final ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ==================================================================
          // LOCATION + SEARCH
          // ==================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SelectLocationScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appState.selectedAddress != null
                                ? '${appState.selectedAddress!.label} · ${appState.selectedAddress!.area}'
                                : 'Select delivery location',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('What are you craving?', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 10),
                  const DapzoSearchBar(readOnly: false),
                ],
              ),
            ),
          ),

          // ==================================================================
          // FOOD / MEAT MODE
          // ==================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Food',
                      icon: Icons.ramen_dining,
                      color: AppColors.foodOrange,
                      selected: appState.mode == 'food',
                      onTap: () => appState.setMode('food'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeButton(
                      label: 'Meat',
                      icon: Icons.set_meal,
                      color: AppColors.meatRed,
                      selected: appState.mode == 'meat',
                      onTap: () => appState.setMode('meat'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================================
          // OFFERS
          // ==================================================================
          SliverToBoxAdapter(
            child: _OffersBanner(mode: appState.mode, productService: _productService),
          ),

          // ==================================================================
          // CATEGORIES HEADER
          // ==================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories', style: AppTextStyles.sectionHeading),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryScreen(
                            mode: appState.mode,
                            categoryId: '',
                            categoryName: '',
                          ),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================================
          // CATEGORIES
          // ==================================================================
          SliverToBoxAdapter(
            child: _CategoryRow(mode: appState.mode, productService: _productService),
          ),

          // ==================================================================
          // POPULAR NEAR YOU HEADER
          // ==================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Popular Near You', style: AppTextStyles.sectionHeading),
            ),
          ),

          // ==================================================================
          // POPULAR PRODUCTS
          // ==================================================================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: StreamBuilder<List<ProductModel>>(
              stream: _productService.streamProducts(mode: appState.mode),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('======================================');
                  debugPrint('POPULAR PRODUCTS ERROR');
                  debugPrint(snapshot.error.toString());
                  debugPrint('======================================');

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load products',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.sectionHeading,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.supporting,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No products available yet', style: AppTextStyles.supporting),
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];

                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(productId: product.id),
                            ),
                          );
                        },
                        onAdd: () {
                          context.read<CartService>().addItem(
                                CartItemModel.fromProduct(product),
                              );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} added to cart')),
                          );
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                );
              },
            ),
          ),

          // ==================================================================
          // BOTTOM SPACE
          // ==================================================================
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ============================================================================
// MODE BUTTON
// ============================================================================

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// OFFERS BANNER
// ============================================================================

class _OffersBanner extends StatelessWidget {
  final String mode;
  final ProductService productService;

  const _OffersBanner({required this.mode, required this.productService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: productService.streamOffers(mode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('OFFERS ERROR: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 20);
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];

              return Container(
                width: 280,
                decoration: BoxDecoration(
                  color: AppColors.modeColor(mode).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      offer['title'] ?? 'Dapzo Offer',
                      style: AppTextStyles.sectionHeading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(offer['subtitle'] ?? '', style: AppTextStyles.supporting),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// CATEGORY ROW
// ============================================================================

class _CategoryRow extends StatelessWidget {
  final String mode;
  final ProductService productService;

  const _CategoryRow({required this.mode, required this.productService});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: productService.streamCategories(mode),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('======================================');
            debugPrint('CATEGORIES ERROR');
            debugPrint(snapshot.error.toString());
            debugPrint('======================================');

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Unable to load categories\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.supporting,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(child: Text('No categories yet', style: AppTextStyles.supporting));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryId = category['id']?.toString() ?? '';
              final categoryName = category['name']?.toString() ?? '';
              final imageUrl = category['imageUrl']?.toString() ?? '';

              return InkWell(
                onTap: categoryId.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(
                              mode: mode,
                              categoryId: categoryId,
                              categoryName: categoryName,
                            ),
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(40),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.background,
                        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.fastfood, color: AppColors.textSecondary)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}