import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String? initialOtp;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.initialOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _otp = '';
  String? _displayedOtp;
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
    _displayedOtp = widget.initialOtp;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
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
      final newOtp = await _authService.resendOtp(
        phoneNumber: widget.phoneNumber,
        reqId: _currentVerificationId,
      );

      if (!mounted) return;

      setState(() {
        _displayedOtp = newOtp;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New OTP generated: $newOtp'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to generate new OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  void _autoFillOtp() {
    if (_displayedOtp != null && _displayedOtp!.isNotEmpty) {
      _otpController.text = _displayedOtp!;
      setState(() {
        _otp = _displayedOtp!;
        _error = null;
      });
      _verify();
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() {
        _error = 'Please enter the 6-digit OTP code';
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
        smsCode: code,
        phoneNumber: widget.phoneNumber,
      );

      debugPrint('Direct OTP Verification Success for UID: $uid');

      bool isNewUser;
      try {
        isNewUser = await _authService.isNewUser(uid, phone: widget.phoneNumber);
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
          final profile = await _authService.getUserProfile(uid, phone: widget.phoneNumber);
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
        _error = errMsg.isNotEmpty ? errMsg : 'Invalid OTP code. Please try again.';
        _loading = false;
      });
    }
  }

  Widget _buildDigitBoxes() {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Invisible actual text input
          Opacity(
            opacity: 0.0,
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                setState(() {
                  _otp = val;
                  _error = null;
                });
                if (val.length == 6) {
                  _verify();
                }
              },
            ),
          ),

          // Custom styled digit boxes with dark theme
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final isFilled = index < _otp.length;
              final isFocused = _focusNode.hasFocus && index == _otp.length;
              final char = isFilled ? _otp[index] : '';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : isFilled
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : const Color(0xFF334155),
                    width: isFocused || isFilled ? 1.8 : 1.2,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    char,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanPhone = widget.phoneNumber;

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

          // ── Ambient Glow ──
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 65,
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
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Card Container ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
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
                            'Verification code for $cleanPhone',
                            style: AppTextStyles.supporting.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── In-App Generated OTP Helper Card ──
                          if (_displayedOtp != null && _displayedOtp!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mark_email_read_outlined,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Generated OTP Code',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _displayedOtp!,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 4.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _autoFillOtp,
                                    icon: const Icon(Icons.touch_app_rounded, size: 16),
                                    label: const Text('Fill OTP'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ── Custom Dark Digit Entry Boxes (No White Box Bug) ──
                          _buildDigitBoxes(),

                          // ── Error Message ──
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 16, color: AppColors.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),

                          // ── Verify Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Verify & Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Resend Code Row ──
                          Center(
                            child: _resendCountdown > 0
                                ? Text(
                                    'Resend OTP in ${_resendCountdown}s',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _resending ? null : _resendOtp,
                                    child: _resending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.primary),
                                            ),
                                          )
                                        : const Text(
                                            'Resend OTP',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                          ),
                        ],
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