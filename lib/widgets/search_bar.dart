import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../state/app_state.dart';

class DapzoSearchBar extends StatefulWidget {
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextEditingController? controller;
  final bool showRecommendations;

  const DapzoSearchBar({
    super.key,
    this.hint = 'Search food or meat',
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.controller,
    this.showRecommendations = true,
  });

  @override
  State<DapzoSearchBar> createState() => _DapzoSearchBarState();
}

class _DapzoSearchBarState extends State<DapzoSearchBar>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  bool _showOverlay = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  static const _foodRecommendations = [
    {'emoji': '🍗', 'label': 'Biryani'},
    {'emoji': '🍕', 'label': 'Pizza'},
    {'emoji': '🍔', 'label': 'Burger'},
    {'emoji': '🧃', 'label': 'Juice'},
    {'emoji': '🍳', 'label': 'Breakfast'},
    {'emoji': '🍰', 'label': 'Desserts'},
    {'emoji': '🌮', 'label': 'Snacks'},
    {'emoji': '🍝', 'label': 'Pasta'},
  ];

  static const _meatRecommendations = [
    {'emoji': '🍗', 'label': 'Chicken'},
    {'emoji': '🥩', 'label': 'Mutton'},
    {'emoji': '🐟', 'label': 'Fish'},
    {'emoji': '🦐', 'label': 'Prawns'},
    {'emoji': '🐑', 'label': 'Sheep'},
    {'emoji': '🥓', 'label': 'Beef'},
  ];

  static const _foodQuickPicks = [
    'Chicken Biryani',
    'Paneer Butter Masala',
    'Veg Fried Rice',
    'Margherita Pizza',
    'Cold Coffee',
    'Gulab Jamun',
  ];

  static const _meatQuickPicks = [
    'Chicken Breast',
    'Mutton Leg',
    'Fish Fillet',
    'Boneless Chicken',
    'Prawns Large',
    'Chicken Drumstick',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.showRecommendations && _controller.text.isEmpty) {
      _showRecommendationOverlay();
    } else {
      _hideRecommendationOverlay();
    }
  }

  void _showRecommendationOverlay() {
    if (_showOverlay) return;
    _showOverlay = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  void _hideRecommendationOverlay() {
    if (!_showOverlay) return;
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
    _showOverlay = false;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        final mode = context.watch<AppState>().mode;
        final recommendations =
            mode == 'meat' ? _meatRecommendations : _foodRecommendations;
        final quickPicks =
            mode == 'meat' ? _meatQuickPicks : _foodQuickPicks;
        final modeColor = AppColors.modeColor(mode);

        return Stack(
          children: [
            // Dismiss overlay on tap outside
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _focusNode.unfocus();
                  _hideRecommendationOverlay();
                },
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: size.width,
                    constraints: const BoxConstraints(maxHeight: 340),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Trending Searches ─────────────────────
                          Row(
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  size: 16, color: modeColor),
                              const SizedBox(width: 6),
                              Text(
                                'Trending Searches',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recommendations.map((item) {
                              return GestureDetector(
                                onTap: () {
                                  _controller.text = item['label']!;
                                  _controller.selection =
                                      TextSelection.collapsed(
                                          offset: _controller.text.length);
                                  widget.onChanged?.call(item['label']!);
                                  _hideRecommendationOverlay();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: modeColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: modeColor.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(item['emoji']!, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        item['label']!,
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),
                          Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 12),

                          // ── Quick Picks ───────────────────────────
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded,
                                  size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Quick Picks',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...quickPicks.map((pick) {
                            return InkWell(
                              onTap: () {
                                _controller.text = pick;
                                _controller.selection =
                                    TextSelection.collapsed(
                                        offset: _controller.text.length);
                                widget.onChanged?.call(pick);
                                _hideRecommendationOverlay();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.search_rounded,
                                        size: 16,
                                        color: AppColors.textHint),
                                    const SizedBox(width: 10),
                                    Text(
                                      pick,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 13.5,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.north_west_rounded,
                                        size: 14,
                                        color: AppColors.textHint),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _overlayEntry?.remove();
    _animController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: (text) {
            widget.onChanged?.call(text);
            if (text.isNotEmpty) {
              _hideRecommendationOverlay();
            } else if (_focusNode.hasFocus && widget.showRecommendations) {
              _showRecommendationOverlay();
            }
          },
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.supporting,
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
