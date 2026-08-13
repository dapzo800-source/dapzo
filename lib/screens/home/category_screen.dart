import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/product_list_card.dart';
import '../../widgets/animated_cart_bar.dart';
import '../product/product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String mode;
  final String categoryId;
  final String categoryName;
  final String? searchQuery;

  const CategoryScreen({
    super.key,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
    this.searchQuery,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {
  late final ProductService _productService;
  bool get _isSeaFoods => widget.categoryName.toLowerCase() == 'sea foods';
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    if (_isSeaFoods) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _getCategoryHeroImage(String name, String mode) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani') || lower.contains('biriyani')) {
      return 'assets/images/biryani_hero.png';
    }
    if (mode == 'meat' || lower.contains('meat') || lower.contains('chicken') || lower.contains('mutton')) {
      return 'assets/images/meat_hero.png';
    }
    return 'assets/images/food_hero.png';
  }

  String _getCravingTagline(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani') || lower.contains('biriyani')) {
      return 'Craving Authentic Biryani? 🍲\nAromatic spices & cooked to perfection.';
    }
    if (lower.contains('meat') || lower.contains('chicken') || lower.contains('mutton')) {
      return 'Craving Fresh Raw Cuts? 🥩\n100% fresh, tender & hygienically packed.';
    }
    if (lower.contains('pizza') || lower.contains('burger')) {
      return 'Craving Fast Food Treats? 🍕\nHot, cheesy & delivered super fast.';
    }
    return 'Craving Something Delicious? ✨\nFreshly prepared food delivered to your door.';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.categoryColor(widget.categoryName);
    final heroImage = _getCategoryHeroImage(widget.categoryName, widget.mode);
    final cravingTagline = _getCravingTagline(widget.categoryName);

    final titleText = widget.searchQuery != null && widget.searchQuery!.isNotEmpty
        ? 'Search: "${widget.searchQuery}"'
        : widget.categoryName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sliver App Bar with Craving Hero Banner ─────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Text(
                    titleText,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        const Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: accentColor,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 70,
                        right: 16,
                        child: Text(
                          cravingTagline,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            shadows: [
                              const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: _isSeaFoods
                    ? TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        tabs: const [
                          Tab(text: '🌊 Sea Fish'),
                          Tab(text: '🏞️ Lake Fish'),
                        ],
                      )
                    : null,
              ),

              // ── Products List ─────────────────────────────────────────────
              if (_isSeaFoods)
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProductList(
                        productService: _productService,
                        mode: widget.mode,
                        categoryId: widget.categoryId,
                        categoryName: widget.categoryName,
                        subCategory: 'Sea Fish',
                        searchQuery: widget.searchQuery,
                      ),
                      _ProductList(
                        productService: _productService,
                        mode: widget.mode,
                        categoryId: widget.categoryId,
                        categoryName: widget.categoryName,
                        subCategory: 'Lake Fish',
                        searchQuery: widget.searchQuery,
                      ),
                    ],
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: _ProductSliverList(
                    productService: _productService,
                    mode: widget.mode,
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                    searchQuery: widget.searchQuery,
                  ),
                ),
            ],
          ),
          const AnimatedCartBar(),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final ProductService productService;
  final String mode;
  final String categoryId;
  final String categoryName;
  final String subCategory;
  final String? searchQuery;

  const _ProductList({
    required this.productService,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
    required this.subCategory,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: productService.streamProducts(
        mode: mode,
        category: categoryId.isNotEmpty ? categoryName : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load products\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.supporting,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        var products = all
            .where((p) => p.subCategory.toLowerCase() == subCategory.toLowerCase())
            .toList();

        if (searchQuery != null && searchQuery!.isNotEmpty) {
          products = _filterByQuery(products, searchQuery!);
        }

        if (products.isEmpty) {
          return Center(
            child: Text(
              'No $subCategory items found.',
              textAlign: TextAlign.center,
              style: AppTextStyles.supporting,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductListCard(
              product: product,
              highlyReordered: product.rating >= 4.0,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
              ),
              onAdd: () => context.read<CartService>().addItem(CartItemModel.fromProduct(product)),
            );
          },
        );
      },
    );
  }
}

class _ProductSliverList extends StatelessWidget {
  final ProductService productService;
  final String mode;
  final String categoryId;
  final String categoryName;
  final String? searchQuery;

  const _ProductSliverList({
    required this.productService,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final stream = (categoryId.isEmpty && (searchQuery == null || searchQuery!.isEmpty))
        ? productService.streamProducts(mode: mode)
        : productService.streamProducts(
            mode: mode,
            category: categoryId.isNotEmpty ? categoryName : null,
          );

    return StreamBuilder<List<ProductModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load products.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.supporting,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var products = snapshot.data ?? [];

        if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
          products = _filterByQuery(products, searchQuery!);
        }

        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No products found matching your search.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.supporting,
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProductListCard(
                  product: product,
                  highlyReordered: product.rating >= 4.0,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  ),
                  onAdd: () {
                    context.read<CartService>().addItem(CartItemModel.fromProduct(product));
                  },
                ),
              );
            },
            childCount: products.length,
          ),
        );
      },
    );
  }
}

List<ProductModel> _filterByQuery(List<ProductModel> products, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return products;

  final isBiryaniSearch = q.contains('biriyani') || q.contains('biryani') || q.contains('briyani');

  return products.where((p) {
    final name = p.name.toLowerCase();
    final cat = p.category.toLowerCase();
    final sub = p.subCategory.toLowerCase();
    final desc = p.description.toLowerCase();

    if (isBiryaniSearch) {
      if (cat.contains('birya') || sub.contains('birya') || name.contains('birya') || desc.contains('birya') ||
          cat.contains('biriyani') || sub.contains('biriyani') || name.contains('biriyani')) {
        return true;
      }
    }

    return name.contains(q) || cat.contains(q) || sub.contains(q) || desc.contains(q);
  }).toList();
}