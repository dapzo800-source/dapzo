import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'profile_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final AuthService _authService = AuthService();

  String _otp = '';
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit OTP';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ============================================================
      // STEP 1: VERIFY OTP
      // ============================================================

      final UserCredential credential =
          await _authService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );

      final User? user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Firebase user was not returned.',
        );
      }

      debugPrint('======================================');
      debugPrint('OTP VERIFICATION SUCCESS');
      debugPrint('UID: ${user.uid}');
      debugPrint('PHONE: ${user.phoneNumber}');
      debugPrint('======================================');

      // ============================================================
      // STEP 2: CHECK FIRESTORE PROFILE
      // ============================================================

      bool isNewUser;

      try {
        isNewUser = await _authService.isNewUser(user.uid);

        debugPrint('======================================');
        debugPrint('FIRESTORE CHECK SUCCESS');
        debugPrint('Is new user: $isNewUser');
        debugPrint('======================================');
      } on FirebaseException catch (e) {
        debugPrint('======================================');
        debugPrint('FIRESTORE ERROR');
        debugPrint('Code: ${e.code}');
        debugPrint('Message: ${e.message}');
        debugPrint('======================================');

        if (!mounted) return;

        setState(() {
          _loading = false;
          _error =
              'Login successful, but your profile could not be loaded.';
        });

        return;
      }

      // ============================================================
      // STEP 3: NAVIGATE
      // ============================================================

      if (!mounted) return;

      if (isNewUser) {
        debugPrint('NEW USER → PROFILE SETUP');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(),
          ),
          (route) => false,
        );
      } else {
        debugPrint('EXISTING USER → HOME');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    }

    // ==============================================================
    // FIREBASE AUTHENTICATION ERRORS
    // ==============================================================

    on FirebaseAuthException catch (e) {
      debugPrint('======================================');
      debugPrint('FIREBASE AUTH ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('======================================');

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message =
              'Invalid OTP. Please check the code and try again.';
          break;

        case 'session-expired':
          message =
              'OTP expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          message =
              'Verification session expired. Please request a new OTP.';
          break;

        case 'missing-verification-id':
          message =
              'Verification session is missing. Please request a new OTP.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please wait and try again later.';
          break;

        case 'quota-exceeded':
          message =
              'OTP limit reached. Please try again later.';
          break;

        default:
          message = e.message ?? 'OTP verification failed.';
      }

      setState(() {
        _error = message;
        _loading = false;
      });
    }

    // ==============================================================
    // OTHER UNEXPECTED ERRORS
    // ==============================================================

    catch (e) {
      debugPrint('======================================');
      debugPrint('UNEXPECTED ERROR');
      debugPrint(e.toString());
      debugPrint('======================================');

      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 16),

              Text(
                'Enter verification code',
                style: AppTextStyles.sectionHeading,
              ),

              const SizedBox(height: 8),

              Text(
                'Sent to ${widget.phoneNumber}',
                style: AppTextStyles.supporting,
              ),

              const SizedBox(height: 28),

              PinCodeTextField(
                appContext: context,

                length: 6,

                keyboardType: TextInputType.number,

                animationType: AnimationType.fade,

                onChanged: (value) {
                  setState(() {
                    _otp = value;
                    _error = null;
                  });
                },

                onCompleted: (value) {
                  setState(() {
                    _otp = value;
                  });
                },

                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,

                  borderRadius:
                      BorderRadius.circular(10),

                  fieldHeight: 48,

                  fieldWidth: 44,

                  activeColor:
                      AppColors.primary,

                  selectedColor:
                      AppColors.primary,

                  inactiveColor:
                      AppColors.divider,

                  activeFillColor:
                      AppColors.white,

                  selectedFillColor:
                      AppColors.white,

                  inactiveFillColor:
                      AppColors.white,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),

                Text(
                  _error!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed:
                      _loading ? null : _verify,

                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}