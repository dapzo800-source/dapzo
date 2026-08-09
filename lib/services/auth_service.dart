import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles Phone + OTP authentication only.
/// No Google Sign-In, no email/password.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to the given phone number.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerified(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          onError(
            e.message ?? 'Phone verification failed.',
          );
        },

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          onCodeSent(verificationId);
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          // Verification ID is already received through codeSent.
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verify the OTP entered by the user.
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'Verification session is missing. Please request a new OTP.',
      );
    }

    if (smsCode.length != 6) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Please enter the 6-digit OTP.',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Returns true when the user does not have a Firestore profile.
  Future<bool> isNewUser(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    return !doc.exists;
  }

  Future<void> createUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}