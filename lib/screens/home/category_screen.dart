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

  const CategoryScreen({
    super.key,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.categoryColor(widget.categoryName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          // ── Sliver App Bar ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: Text(
                widget.categoryName,
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 17),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.12),
                      accentColor.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 80,
                      color: accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
            // Sea Foods sub-tabs
            bottom: _isSeaFoods
                ? TabBar(
                    controller: _tabController,
                    labelColor: accentColor,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: accentColor,
                    indicatorWeight: 2.5,
                    labelStyle: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: '🌊  Sea Fish'),
                      Tab(text: '🏞️  Lake Fish'),
                    ],
                  )
                : null,
          ),

          // ── Products ──────────────────────────────────────────────────
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
                  ),
                  _ProductList(
                    productService: _productService,
                    mode: widget.mode,
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                    subCategory: 'Lake Fish',
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

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT LIST (for SeaFoods sub-tabs inside TabBarView)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductList extends StatelessWidget {
  final ProductService productService;
  final String mode;
  final String categoryId;
  final String categoryName;
  final String subCategory;

  const _ProductList({
    required this.productService,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
    required this.subCategory,
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
        final products = all
            .where((p) =>
                p.subCategory.toLowerCase() == subCategory.toLowerCase())
            .toList();

        if (products.isEmpty) {
          return Center(
            child: Text(
              'No $subCategory items available yet.\nSeed demo data from Profile.',
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
              onTap: () => _openDetail(context, product.id),
              onAdd: () => _addToCart(context, product),
            );
          },
        );
      },
    );
  }

  void _openDetail(BuildContext context, String productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  void _addToCart(BuildContext context, ProductModel product) {
    context.read<CartService>().addItem(CartItemModel.fromProduct(product));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT SLIVER LIST (regular categories)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductSliverList extends StatelessWidget {
  final ProductService productService;
  final String mode;
  final String categoryId;
  final String categoryName;

  const _ProductSliverList({
    required this.productService,
    required this.mode,
    required this.categoryId,
    required this.categoryName,
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

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No products found.\nSeed demo data from Profile.',
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
                      builder: (_) =>
                          ProductDetailScreen(productId: product.id),
                    ),
                  ),
                  onAdd: () {
                    context
                        .read<CartService>()
                        .addItem(CartItemModel.fromProduct(product));
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