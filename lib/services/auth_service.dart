import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'msg91_otp_service.dart';

/// Handles Phone + MSG91 OTP authentication with seamless Firebase & local session sync.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _prefPhoneKey = 'dapzo_verified_phone';
  static const String _prefUidKey = 'dapzo_user_uid';

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to the given phone number using MSG91 OTP Widget.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String reqId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    try {
      final reqId = await Msg91OtpService.sendOtp(phoneNumber: phoneNumber);
      if (reqId.isNotEmpty) {
        onCodeSent(reqId);
      } else {
        onError('Failed to generate verification request. Please try again.');
      }
    } catch (e) {
      debugPrint('[AuthService] sendOtp error: $e');
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Resends/Retries OTP via MSG91.
  Future<bool> resendOtp({
    required String reqId,
    String? channel,
  }) async {
    try {
      return await Msg91OtpService.retryOtp(reqId: reqId, retryChannel: channel);
    } catch (e) {
      debugPrint('[AuthService] resendOtp error: $e');
      return false;
    }
  }

  /// Verifies the OTP entered by the user via MSG91 and ensures a valid authenticated session.
  /// Returns the effective user ID (UID).
  Future<String> verifyOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    if (verificationId.trim().isEmpty) {
      throw Exception('Verification session missing. Please request a new OTP.');
    }

    if (smsCode.trim().length < 4) {
      throw Exception('Please enter a valid OTP.');
    }

    // 1. Verify code with MSG91
    final verified = await Msg91OtpService.verifyOtp(
      reqId: verificationId.trim(),
      otp: smsCode.trim(),
      phoneNumber: phoneNumber ?? '',
    );

    if (!verified) {
      throw Exception('OTP verification failed. Please check the code and try again.');
    }

    // 2. Safely attempt Firebase Auth sign-in if not signed in
    String? effectiveUid = _auth.currentUser?.uid;

    if (effectiveUid == null) {
      try {
        final userCred = await _auth.signInAnonymously();
        effectiveUid = userCred.user?.uid;
      } catch (e) {
        // If Anonymous auth is restricted in Firebase console, fallback to deterministic UID
        debugPrint('[AuthService] Anonymous auth note: $e');
      }
    }

    // If still null, generate a deterministic phone-based UID
    if (effectiveUid == null || effectiveUid.isEmpty) {
      final cleanPhone = Msg91OtpService.formatIdentifier(phoneNumber ?? 'user');
      effectiveUid = 'dapzo_$cleanPhone';
    }

    // 3. Cache verified phone number and UID locally
    final prefs = await SharedPreferences.getInstance();
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await prefs.setString(_prefPhoneKey, phoneNumber);
    }
    await prefs.setString(_prefUidKey, effectiveUid);

    debugPrint('[AuthService] Authentication successful for UID: $effectiveUid, Phone: $phoneNumber');
    return effectiveUid;
  }

  /// Retrieves the current or locally cached UID.
  Future<String?> getCurrentOrStoredUid() async {
    if (_auth.currentUser?.uid != null) {
      return _auth.currentUser!.uid;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefUidKey);
  }

  /// Retrieves cached phone number if present.
  Future<String?> getCachedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefPhoneKey);
  }

  /// Returns true when the user does not have a completed Firestore profile.
  Future<bool> isNewUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return true;
      final data = doc.data();
      if (data == null || data['name'] == null || (data['name'] as String).trim().isEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] isNewUser check note: $e');
      return true;
    }
  }

  Future<void> createUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUidKey, user.uid);
      if (user.phone.isNotEmpty) {
        await prefs.setString(_prefPhoneKey, user.phone);
      }
    } catch (e) {
      debugPrint('Cache prefs error: $e');
    }

    await _firestore.collection('users').doc(user.uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefPhoneKey);
      await prefs.remove(_prefUidKey);
    } catch (e) {
      debugPrint('[AuthService] prefs clear error: $e');
    }
    await _auth.signOut();
  }
}