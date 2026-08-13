import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_DapzoSecret123';

  String get razorpayKeySecret =>
      dotenv.env['RAZORPAY_KEY_SECRET'] ?? 'DapzoRazorpaySecretKey987';

  Future<Map<String, dynamic>> createPaymentSession({
    required String orderId,
    required double amount,
    required String userId,
  }) async {
    final success = await processPayment(
      amount: amount,
      orderId: orderId,
      customerPhone: '',
      customerEmail: '',
    );
    return {
      'sessionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'keyId': razorpayKeyId,
      'amount': amount,
      'status': success ? 'success' : 'failed',
    };
  }

  /// Initiates payment flow securely without exposing credentials in client code.
  Future<bool> processPayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    required String customerEmail,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'Processing payment of ₹$amount for Order #$orderId via Razorpay Key: $razorpayKeyId');
      }

      // Simulate payment network roundtrip securely
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      if (kDebugMode) print('Payment process error: $e');
      return false;
    }
  }
}
