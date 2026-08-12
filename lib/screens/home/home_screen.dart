import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/product_service.dart';
import '../../services/shop_service.dart';
import '../../state/app_state.dart';
import '../../services/cart_service.dart';
import '../../widgets/search_bar.dart';

import '../location/select_location_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../cart/cart_screen.dart';
import 'category_screen.dart';
import '../auth/profile_setup_screen.dart';
import 'shop_screen.dart';

// ============================================================================
// HOME SCREEN (Bottom Nav Host)
// ============================================================================

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
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        cartCount: cartCount,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ============================================================================
// BOTTOM NAV
// ============================================================================

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          elevation: 0,
          onTap: onTap,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _CartIcon(count: cartCount, filled: false),
              activeIcon: _CartIcon(count: cartCount, filled: true),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  final int count;
  final bool filled;
  const _CartIcon({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(filled
        ? Icons.shopping_cart_rounded
        : Icons.shopping_cart_outlined);
    if (count <= 0) return icon;
    return Badge(label: Text('$count'), child: icon);
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
  late final ShopService _shopService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _shopService = ShopService();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final mode = appState.mode;

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, appState),
          ),

          // ── Mode Toggle ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ModeToggle(
              selected: mode,
              onChanged: appState.setMode,
            ),
          ),

          // ── Offers ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _OffersBanner(mode: mode, productService: _productService),
          ),

          // ── Categories Header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Categories',
              onSeeAll: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CategoryScreen(
                  mode: mode,
                  categoryId: '',
                  categoryName: 'All Categories',
                ),
              )),
            ),
          ),

          // ── Category Row ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CategoryRow(mode: mode, productService: _productService),
          ),

          // ── Popular Shops ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Popular Shops', onSeeAll: null),
          ),

          // ── Popular Shops List (from Firestore) ─────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _shopService.streamShops(mode),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: _ErrorBox(error: snapshot.error.toString()),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final popularShops = snapshot.data ?? [];
                if (popularShops.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No shops yet.\nAdd shops in Firestore to populate this list.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }

                // Highest-rated shops first.
                final sorted = [...popularShops]..sort((a, b) {
                    final ra = (a['rating'] as num?)?.toDouble() ?? 0.0;
                    final rb = (b['rating'] as num?)?.toDouble() ?? 0.0;
                    return rb.compareTo(ra);
                  });

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shop = sorted[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PopularShopCard(
                          shop: shop,
                          selectedAddress: appState.selectedAddress,
                          shopService: _shopService,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShopScreen(shop: shop),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // Mode-specific hero images (Craving focused)
  static const _foodHeroUrl =
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=90'; // Gourmet Burger
  static const _meatHeroUrl =
      'https://images.unsplash.com/photo-1544025162-d76694265947?w=1200&q=90'; // Sizzling Steak


  Widget _buildHeader(BuildContext context, AppState appState) {
    final mode = appState.mode;
    final heroUrl = mode == 'meat' ? _meatHeroUrl : _foodHeroUrl;

    return Stack(
      children: [
        // ── Background hero image ─────────────────────────────────────────
        CachedNetworkImage(
          imageUrl: heroUrl,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 280,
            color: mode == 'meat'
                ? const Color(0xFF7F1D1D)
                : const Color(0xFFFF6B35),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 280,
            color: mode == 'meat'
                ? const Color(0xFF7F1D1D)
                : const Color(0xFFFF6B35),
          ),
        ),

        // ── Warm gradient overlay (bottom-heavy for text readability) ─────
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 1.0],
              colors: mode == 'meat'
                  ? [
                      const Color(0x88000000),
                      const Color(0x55000000),
                      const Color(0xEE7F1D1D),
                    ]
                  : [
                      const Color(0x88000000),
                      const Color(0x44000000),
                      const Color(0xEEE8472A),
                    ],
            ),
          ),
        ),

        // ── Content on top of image ───────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: location + avatar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SelectLocationScreen()),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: AppColors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deliver to',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    appState.selectedAddress != null
                                        ? '${appState.selectedAddress!.label} · ${appState.selectedAddress!.area}'
                                        : 'Select delivery location',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const ProfileSetupScreen(isEditing: true),
                      )),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            appState.user?.name.isNotEmpty == true
                                ? appState.user!.name[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero text
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 120, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's your",
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.white,
                        fontSize: 26,
                        height: 1.1,
                        shadows: [
                          const Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 2),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                    Text(
                      mode == 'meat'
                          ? 'meat craving? 🥩'
                          : 'ultimate craving? 🍔',
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        shadows: [
                          const Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 2),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode == 'meat'
                          ? 'Fresh cuts, delivered to your door'
                          : 'Order from the best restaurants near you',
                      style: AppTextStyles.supporting.copyWith(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const DapzoSearchBar(readOnly: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

// ============================================================================
// MODE TOGGLE
// ============================================================================

class _ModeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ModeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _ModeChip(
              label: '🍽️  Food',
              selected: selected == 'food',
              color: AppColors.foodOrange,
              onTap: () => onChanged('food'),
            ),
            const SizedBox(width: 4),
            _ModeChip(
              label: '🥩  Meat',
              selected: selected == 'meat',
              color: AppColors.meatRed,
              onTap: () => onChanged('meat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: selected ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.sectionHeading),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all',
                style: AppTextStyles.tag,
              ),
            ),
        ],
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
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final offers = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text('🎉 Offers for You',
                  style: AppTextStyles.sectionHeading),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  final colors = AppColors.modeGradient(mode);
                  return Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors[0].withValues(alpha: 0.15),
                          colors[1].withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors[0].withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer['title'] ?? 'Dapzo Offer',
                          style: AppTextStyles.sectionHeading
                              .copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer['subtitle'] ?? '',
                          style: AppTextStyles.supporting,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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
      height: 105,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: productService.streamCategories(mode),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load categories',
                style: AppTextStyles.supporting,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text('No categories yet', style: AppTextStyles.supporting),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final categoryName = cat['name']?.toString() ?? '';
              final categoryId = cat['id']?.toString() ?? '';
              final imageUrl = cat['imageUrl']?.toString() ?? '';
              final accentColor =
                  AppColors.categoryColor(categoryName);

              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CategoryScreen(
                    mode: mode,
                    categoryId: categoryId,
                    categoryName: categoryName,
                  ),
                )),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withValues(alpha: 0.2),
                              accentColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.restaurant_rounded,
                                    color: accentColor,
                                    size: 26,
                                  ),
                                )
                              : Icon(
                                  Icons.restaurant_rounded,
                                  color: accentColor,
                                  size: 26,
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categoryName,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
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

// ============================================================================
// POPULAR SHOP CARD
// ============================================================================

/// Full-width shop card used in the "Popular Shops" section — shows the
/// shop image, name, rating, delivery time, live distance (when a delivery
/// address is selected), and an offer badge if the shop has one.
class _PopularShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final dynamic selectedAddress; // AddressModel? — kept dynamic to avoid a new import cycle here
  final ShopService shopService;
  final VoidCallback onTap;

  const _PopularShopCard({
    required this.shop,
    required this.selectedAddress,
    required this.shopService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = shop['name'] as String? ?? '';
    final tagline = shop['tagline'] as String? ?? '';
    final imageUrl = shop['imageUrl'] as String? ?? '';
    final rating = (shop['rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = shop['ratingCount'] ?? 0;
    final deliveryMin = shop['deliveryTimeMin'] ?? 30;
    final deliveryMax = shop['deliveryTimeMax'] ?? 50;
    final deliveryFee = shop['deliveryFee'] ?? 0;
    final offerText = (shop['offerText'] ?? shop['offer']) as String?;
    final mode = shop['mode'] as String? ?? 'food';

    // Live distance — only computed when we have both the shop's and the
    // user's coordinates.
    String? distanceLabel;
    final shopLat = (shop['latitude'] as num?)?.toDouble();
    final shopLng = (shop['longitude'] as num?)?.toDouble();
    if (shopLat != null &&
        shopLng != null &&
        selectedAddress != null &&
        selectedAddress.latitude != null &&
        selectedAddress.longitude != null) {
      final km = shopService.distanceInKm(
        selectedAddress.latitude,
        selectedAddress.longitude,
        shopLat,
        shopLng,
      );
      distanceLabel = '${km.toStringAsFixed(1)} km';
    }

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
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Shop Image ────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.surfaceVariant,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.modeGradient(mode),
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.storefront_rounded,
                                    color: AppColors.white, size: 36),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.modeGradient(mode),
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.storefront_rounded,
                                  color: AppColors.white, size: 36),
                            ),
                          ),
                  ),
                ),

                // Offer badge — top left
                if (offerText != null && offerText.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              color: AppColors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(offerText, style: AppTextStyles.badge.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                // Rating badge — top right
                if (rating > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.white, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            ratingCount > 0
                                ? '${rating.toStringAsFixed(1)} ($ratingCount)'
                                : rating.toStringAsFixed(1),
                            style: AppTextStyles.badge.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info Section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.shopName.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tagline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tagline,
                      style: AppTextStyles.supporting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('$deliveryMin–$deliveryMax min',
                          style: AppTextStyles.caption),
                      if (distanceLabel != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.near_me_rounded,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(distanceLabel, style: AppTextStyles.caption),
                      ],
                      const SizedBox(width: 10),
                      Icon(Icons.delivery_dining_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        deliveryFee == 0 ? 'Free delivery' : '₹$deliveryFee delivery',
                        style: AppTextStyles.caption,
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

// ============================================================================
// ERROR BOX
// ============================================================================

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Unable to load products',
            style: AppTextStyles.sectionHeading.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTextStyles.supporting,
          ),
        ],
      ),
    );
  }
}