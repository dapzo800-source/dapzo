import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import 'mode_selection_screen.dart';
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
  bool _resending = false;
  String? _error;
  late String _currentVerificationId;

  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _resendCountdown = 0;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resending || _resendCountdown > 0) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      final success = await _authService.resendOtp(
        reqId: _currentVerificationId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully via SMS.'),
            backgroundColor: AppColors.success,
          ),
        );
        _startResendTimer();
      } else {
        await _authService.sendOtp(
          phoneNumber: widget.phoneNumber,
          onCodeSent: (newReqId) {
            if (!mounted) return;
            setState(() {
              _currentVerificationId = newReqId;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New OTP sent successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
            _startResendTimer();
          },
          onError: (err) {
            if (!mounted) return;
            setState(() {
              _error = err;
            });
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to resend OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    if (_otp.length < 4) {
      setState(() {
        _error = 'Please enter the complete verification code';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final String uid = await _authService.verifyOtp(
        verificationId: _currentVerificationId,
        smsCode: _otp,
        phoneNumber: widget.phoneNumber,
      );

      debugPrint('MSG91 OTP Verification Success for UID: $uid');

      bool isNewUser;
      try {
        isNewUser = await _authService.isNewUser(uid);
      } catch (e) {
        isNewUser = true;
      }

      if (!mounted) return;

      if (isNewUser) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(),
          ),
          (route) => false,
        );
      } else {
        try {
          final profile = await _authService.getUserProfile(uid);
          if (profile != null && mounted) {
            context.read<AppState>().setUser(profile);
          }
        } catch (e) {
          debugPrint('Profile load error: $e');
        }

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ModeSelectionScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = errMsg.isNotEmpty ? errMsg : 'Invalid OTP. Please check and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Premium Dark Background Overlay ──
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

          // ── Subtle Ambient Glow Behind Logo ──
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 70,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Official Dapzo Logo ──
                    Hero(
                      tag: 'dapzo_logo',
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        height: 95,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Card Container ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OTP Verification',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 22,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter the 6-digit code sent to',
                            style: AppTextStyles.supporting.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Phone Number Badge with Edit Option ──
                          InkWell(
                            onTap: () => Navigator.maybePop(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_iphone_rounded,
                                      size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.phoneNumber,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_rounded,
                                      size: 14, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── 6-Digit PIN Code Input ──
                          PinCodeTextField(
                            appContext: context,
                            backgroundColor: Colors.transparent,
                            cursorColor: AppColors.primaryLight,
                            length: 6,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.scale,
                            textStyle: AppTextStyles.heading.copyWith(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                              _verify();
                            },
                            enableActiveFill: true,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(12),
                              fieldHeight: 50,
                              fieldWidth: 44,
                              borderWidth: 1.5,
                              activeColor: AppColors.primary,
                              selectedColor: AppColors.primaryLight,
                              inactiveColor: Colors.white.withValues(alpha: 0.18),
                              activeFillColor: const Color(0xFF0F172A),
                              selectedFillColor: const Color(0xFF0F172A),
                              inactiveFillColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
                            ),
                          ),

                          // ── Error Alert ──
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 16, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFFFCA5A5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // ── Resend Countdown Row ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _resendCountdown > 0
                                    ? 'Resend OTP in ${_resendCountdown}s'
                                    : "Didn't receive code?",
                                style: AppTextStyles.supporting.copyWith(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 12.5,
                                ),
                              ),
                              TextButton(
                                onPressed: (_resendCountdown == 0 && !_resending)
                                    ? _resendOtp
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: _resending
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Text(
                                        'Resend',
                                        style: AppTextStyles.body.copyWith(
                                          color: _resendCountdown == 0
                                              ? AppColors.primaryLight
                                              : const Color(0xFF64748B),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Verify Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 4,
                                shadowColor: AppColors.primary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Text(
                                      'Verify & Proceed',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Trust Badge ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Secure Login with MSG91',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
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