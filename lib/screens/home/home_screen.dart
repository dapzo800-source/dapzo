import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/product_service.dart';
import '../../services/shop_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../../services/cart_service.dart';
import '../../widgets/search_bar.dart';

import '../location/select_location_screen.dart';
import '../orders/orders_screen.dart';
import '../orders/order_tracking_screen.dart';
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
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _isNavVisible = true;
  Timer? _scrollIdleTimer;
  late final AnimationController _navAnimController;
  late final Animation<Offset> _navSlideAnim;

  void goToTab(int index) {
    if (mounted) {
      setState(() => _navIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _navSlideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.2),
    ).animate(CurvedAnimation(
      parent: _navAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scrollIdleTimer?.cancel();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      // Hide nav on scroll
      if (_isNavVisible) {
        setState(() => _isNavVisible = false);
        _navAnimController.forward();
      }
      // Reset idle timer
      _scrollIdleTimer?.cancel();
      _scrollIdleTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !_isNavVisible) {
          setState(() => _isNavVisible = true);
          _navAnimController.reverse();
        }
      });
    } else if (notification is ScrollEndNotification) {
      _scrollIdleTimer?.cancel();
      _scrollIdleTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && !_isNavVisible) {
          setState(() => _isNavVisible = true);
          _navAnimController.reverse();
        }
      });
    }
  }

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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScrollNotification(notification);
          return false;
        },
        child: IndexedStack(index: _navIndex, children: pages),
      ),
      extendBody: true,
      bottomNavigationBar: SlideTransition(
        position: _navSlideAnim,
        child: _BottomNav(
          currentIndex: _navIndex,
          cartCount: cartCount,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM NAV — Floating pill design
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppColors.isDarkMode ? 0.3 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
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
  late final OrderService _orderService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _shopService = ShopService();
    _orderService = OrderService();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final mode = appState.mode;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? appState.user?.uid ?? '';

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, appState),
          ),

          // ── Active Order Tracker Banner (If customer has active order) ───
          if (currentUid.isNotEmpty)
            SliverToBoxAdapter(
              child: _ActiveOrderBanner(
                userId: currentUid,
                orderService: _orderService,
              ),
            ),

          // ── Mode Toggle ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ModeToggle(
              selected: mode,
              onChanged: appState.setMode,
            ),
          ),

          // ── Filter Chips ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterChips(appState: appState),
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
                  return SliverToBoxAdapter(
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

                // Filter & Sort Shops
                var sorted = [...popularShops];
                if (appState.isNearAndFast) {
                  sorted = sorted.where((s) {
                    final time = (s['deliveryTime'] as num?)?.toInt() ?? 999;
                    return time <= 30; // Assuming <=30 mins is fast
                  }).toList();
                }
                sorted.sort((a, b) {
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

          // Extra bottom padding for floating nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // Mode-specific hero images (Craving focused)
  static const _foodHeroUrl = 'assets/images/biryani_hero.png';
  static const _meatHeroUrl = 'assets/images/meat_hero.png';


  Widget _buildHeader(BuildContext context, AppState appState) {
    final mode = appState.mode;
    final heroUrl = mode == 'meat' ? _meatHeroUrl : _foodHeroUrl;

    return Stack(
      children: [
        // ── Background hero image ─────────────────────────────────────────
        Image.asset(
          heroUrl,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
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
                              child: Icon(Icons.location_on_rounded,
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: DapzoSearchBar(
                    readOnly: false,
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(
                              mode: mode,
                              categoryId: '',
                              categoryName: query.toLowerCase().contains('birya') ? 'Biryani' : 'Search Results',
                              searchQuery: query,
                            ),
                          ),
                        );
                      }
                    },
                  ),
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
// FILTER CHIPS
// ============================================================================

class _FilterChips extends StatelessWidget {
  final AppState appState;

  const _FilterChips({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isFood = appState.mode == 'food';
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          if (isFood) ...[
            _FilterChip(
              icon: Icons.eco_rounded,
              label: 'Veg Mode',
              isActive: appState.isVegMode,
              activeColor: const Color(0xFF16A34A),
              onTap: appState.toggleVegMode,
            ),
            const SizedBox(width: 8),
          ],
          _FilterChip(
            icon: Icons.currency_rupee_rounded,
            label: 'Under ₹199',
            isActive: appState.isUnder199,
            activeColor: Colors.amber.shade700,
            onTap: appState.toggleUnder199,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.star_rounded,
            label: 'Rating 4.0+',
            isActive: appState.isRating4Plus,
            activeColor: const Color(0xFFF59E0B),
            onTap: appState.toggleRating4Plus,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.timer_rounded,
            label: 'Near & Fast',
            isActive: appState.isNearAndFast,
            activeColor: const Color(0xFFEF4444),
            onTap: appState.toggleNearAndFast,
          ),
          if (appState.hasActiveFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: appState.clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : AppColors.divider,
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeChip(
            label: 'FOOD CRAVINGS',
            imagePath: 'assets/images/food_hero.png',
            selected: selected == 'food',
            color: Colors.amber.shade700,
            onTap: () => onChanged('food'),
          ),
          const SizedBox(width: 16),
          _ModeChip(
            label: 'MEAT CRAVINGS',
            imagePath: 'assets/images/meat_hero.png',
            selected: selected == 'meat',
            color: AppColors.meatRed,
            onTap: () => onChanged('meat'),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final String imagePath;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.imagePath,
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
        height: 100,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: selected ? 2.5 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? color.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      label,
                      style: AppTextStyles.heading.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        shadows: [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
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
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          color: AppColors.surface,
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
                          Icon(Icons.local_offer_rounded,
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
                          Icon(Icons.star_rounded,
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
                      Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('$deliveryMin–$deliveryMax min',
                          style: AppTextStyles.caption),
                      if (distanceLabel != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.near_me_rounded,
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
          Icon(Icons.error_outline, size: 40, color: AppColors.textSecondary),
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

// ============================================================================
// ACTIVE ORDER BANNER (Interactive Live Status on Home Tab)
// ============================================================================

class _ActiveOrderBanner extends StatelessWidget {
  final String userId;
  final OrderService orderService;

  const _ActiveOrderBanner({
    required this.userId,
    required this.orderService,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.streamUserOrders(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final activeOrders = (snapshot.data ?? []).where((order) {
          return order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled;
        }).toList();

        if (activeOrders.isEmpty) return const SizedBox.shrink();

        final activeOrder = activeOrders.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(orderId: activeOrder.id),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.92),
                      const Color(0xFFE8472A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${activeOrder.orderCode}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activeOrder.status.label.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeOrder.shopName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Track',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}