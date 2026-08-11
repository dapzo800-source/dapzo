import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    final phone = '+91${_phoneController.text.trim()}';

    await _authService.sendOtp(
      phoneNumber: phone,

      // Firebase successfully sent the OTP.
      onCodeSent: (String verificationId) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: phone,
              verificationId: verificationId,
            ),
          ),
        );
      },

      // Firebase failed to send the OTP.
      onError: (String error) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
      },

      // Android may automatically verify the phone.
      onAutoVerified: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e) {
          if (!mounted) return;

          setState(() {
            _loading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Automatic verification failed. Please enter the OTP manually.',
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'DAPZO',
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.primary,
                        fontSize: 40,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Enter your phone number',
                      style: AppTextStyles.sectionHeading.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We'll send you a one-time verification code.",
                      style: AppTextStyles.supporting.copyWith(color: AppColors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: AppTextStyles.body.copyWith(color: AppColors.white),
                      validator: Validators.phone,
                      decoration: InputDecoration(
                        prefixText: '+91  ',
                        prefixStyle: AppTextStyles.body.copyWith(color: AppColors.white),
                        hintText: '98765 43210',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.white.withOpacity(0.5)),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text('Send OTP', style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
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