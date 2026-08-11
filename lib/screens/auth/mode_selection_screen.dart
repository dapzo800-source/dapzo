import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/app_state.dart';
import '../home/home_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _selectMode(BuildContext context, String mode) {
    context.read<AppState>().setMode(mode);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectMode(context, 'food'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _AnimatedBackground(imagePath: 'assets/images/food_bg.png'),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.ramen_dining, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Food',
                            style: AppTextStyles.heading.copyWith(color: AppColors.primary, fontSize: 32),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectMode(context, 'meat'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _AnimatedBackground(imagePath: 'assets/images/meat_bg.png'),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.kebab_dining, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Meat',
                            style: AppTextStyles.heading.copyWith(color: AppColors.primary, fontSize: 32),
                          ),
                        ],
                      ),
                    ),
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

class _AnimatedBackground extends StatefulWidget {
  final String imagePath;
  const _AnimatedBackground({required this.imagePath});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Image.asset(widget.imagePath, fit: BoxFit.cover),
        );
      },
    );
  }
}
