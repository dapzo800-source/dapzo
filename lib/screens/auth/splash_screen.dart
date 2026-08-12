import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
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

    // Give Firebase a moment to restore the authentication session.
    await Future.delayed(
      const Duration(milliseconds: 1200),
    );

    if (!mounted) return;

    try {
      // ============================================================
      // STEP 1: CHECK FIREBASE AUTH
      // ============================================================

      final User? user = _authService.currentUser;

      debugPrint('======================================');
      debugPrint('SPLASH SCREEN');
      debugPrint(
        'Current Firebase User: ${user?.uid}',
      );
      debugPrint(
        'Current Phone: ${user?.phoneNumber}',
      );
      debugPrint('======================================');

      // ============================================================
      // STEP 2: NO USER
      // ============================================================

      if (user == null) {
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
      // STEP 3: USER EXISTS
      // CHECK FIRESTORE PROFILE
      // ============================================================

      debugPrint('USER EXISTS → CHECKING FIRESTORE PROFILE');

      bool isNew;

      try {
        isNew = await _authService
            .isNewUser(user.uid)
            .timeout(
              const Duration(seconds: 10),
            );

        debugPrint(
          'Firestore profile check: isNewUser = $isNew',
        );
      } catch (e) {
        debugPrint('======================================');
        debugPrint('FIRESTORE ERROR IN SPLASH');
        debugPrint(e.toString());
        debugPrint('======================================');

        if (!mounted) return;

        setState(() {
          _checking = false;
          _error =
              'Unable to check your profile.\n'
              'Please check your internet connection and try again.';
        });

        return;
      }

      if (!mounted) return;

      // ============================================================
      // STEP 4: NEW USER
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
      // STEP 5: EXISTING USER
      // LOAD FULL PROFILE FROM FIRESTORE INTO APP STATE
      // ============================================================
      //
      // Previously this step was skipped entirely — the splash screen
      // routed straight to HomeScreen without ever populating
      // AppState.user from Firestore. Any screen reading user.email,
      // user.dateOfBirth, etc. right after a cold start would see stale
      // or empty values until something else happened to call setUser
      // with a full profile (e.g. opening Edit Profile and saving again).

      debugPrint('EXISTING USER → LOADING PROFILE');

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (doc.exists) {
          final profile = UserModel.fromFirestore(doc);

          if (!mounted) return;
          context.read<AppState>().setUser(profile);

          debugPrint('Loaded profile: name=${profile.name}, email=${profile.email}');
        } else {
          debugPrint('Profile document does not exist for ${user.uid}');
        }
      } catch (e) {
        // Don't block navigation to Home just because the profile fetch
        // failed — HomeScreen/ProfileScreen will show fallback values
        // and the user can retry from there. Log it for visibility.
        debugPrint('======================================');
        debugPrint('FAILED TO LOAD USER PROFILE IN SPLASH');
        debugPrint(e.toString());
        debugPrint('======================================');
      }

      if (!mounted) return;

      debugPrint('EXISTING USER → HOME');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      debugPrint('======================================');
      debugPrint('SPLASH BOOTSTRAP ERROR');
      debugPrint(e.toString());
      debugPrint('======================================');

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
      backgroundColor: const Color(0xFFD32F2F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DAPZO',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Food • Meat • Delivery',
                style: AppTextStyles.supporting.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 40),

              if (_checking)
                const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                ),

              if (!_checking && _error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.supporting.copyWith(
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}