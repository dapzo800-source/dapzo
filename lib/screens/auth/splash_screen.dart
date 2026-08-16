import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    // Give Firebase and local cache a moment to restore the session.
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    try {
      // ============================================================
      // STEP 1: CHECK AUTH (FIREBASE USER OR STORED SESSION)
      // ============================================================
      final String? effectiveUid = await _authService.getCurrentOrStoredUid();
      final User? user = _authService.currentUser;

      debugPrint('======================================');
      debugPrint('SPLASH SCREEN');
      debugPrint('Effective UID: $effectiveUid');
      debugPrint('Current Firebase User: ${user?.uid}');
      debugPrint('======================================');

      // ============================================================
      // STEP 2: NO USER → ONBOARDING
      // ============================================================
      if (effectiveUid == null || effectiveUid.isEmpty) {
        debugPrint('NO USER → ONBOARDING');
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          ),
        );
        return;
      }

      // ============================================================
      // STEP 3: USER EXISTS - CHECK FIRESTORE PROFILE
      // ============================================================
      debugPrint('USER EXISTS → CHECKING FIRESTORE PROFILE');

      bool isNew;
      try {
        isNew = await _authService
            .isNewUser(effectiveUid)
            .timeout(const Duration(seconds: 10));

        debugPrint('Firestore profile check: isNewUser = $isNew');
      } catch (e) {
        debugPrint('======================================');
        debugPrint('FIRESTORE ERROR IN SPLASH: $e');
        debugPrint('======================================');

        if (!mounted) return;
        setState(() {
          _checking = false;
          _error =
              'Unable to check your profile.\nPlease check your internet connection and try again.';
        });
        return;
      }

      if (!mounted) return;

      // ============================================================
      // STEP 4: NEW USER → PROFILE SETUP
      // ============================================================
      if (isNew) {
        debugPrint('NEW USER → PROFILE SETUP');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(),
          ),
        );
        return;
      }

      // ============================================================
      // STEP 5: EXISTING USER → LOAD FULL PROFILE INTO APP STATE
      // ============================================================
      debugPrint('EXISTING USER → LOADING PROFILE');

      try {
        final profile = await _authService
            .getUserProfile(effectiveUid)
            .timeout(const Duration(seconds: 10));

        if (profile != null && mounted) {
          context.read<AppState>().setUser(profile);
          debugPrint('Loaded profile: name=${profile.name}, email=${profile.email}');
        } else {
          debugPrint('Profile document does not exist for $effectiveUid');
        }
      } catch (e) {
        debugPrint('FAILED TO LOAD USER PROFILE IN SPLASH: $e');
      }

      if (!mounted) return;

      debugPrint('EXISTING USER → HOME');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      debugPrint('SPLASH BOOTSTRAP ERROR: $e');
      if (!mounted) return;

      setState(() {
        _checking = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Gradient Background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Color(0xFF0B0F19),
                  ],
                ),
              ),
            ),
          ),

          // ── Ambient Glow Behind Logo ──
          Positioned(
            top: 0,
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 90,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Center Content ──
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // ── Official Dapzo Logo (Crisp & Unclipped) ──
                    Hero(
                      tag: 'dapzo_logo',
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 260,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          'DAPZO',
                          style: AppTextStyles.heading.copyWith(
                            color: AppColors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Loading Indicator or Error Retry ──
                    if (_checking) ...[
                      const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Loading your experience...',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],

                    if (!_checking && _error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.supporting.copyWith(
                                color: const Color(0xFFFCA5A5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _bootstrap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}