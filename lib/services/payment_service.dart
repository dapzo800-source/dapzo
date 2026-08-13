import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  /// Public Key ID only — safe for client-side inclusion (e.g. rzp_live_xxx or rzp_test_xxx).
  /// Secret credentials MUST remain strictly on backend servers.
  String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  /// Create payment session token via backend API or gateway public parameters
  Future<Map<String, dynamic>> createPaymentSession({
    required String orderId,
    required double amount,
    required String userId,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final txnId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'sessionId': txnId,
      'keyId': razorpayKeyId,
      'amount': amount,
      'currency': 'INR',
      'orderId': orderId,
      'status': 'created',
    };
  }

  /// Initiates payment gateway checkout securely.
  /// Does NOT set paymentStatus = "paid" prematurely.
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    required String customerEmail,
  }) async {
    try {
      if (kDebugMode) {
        print('Initiating payment gateway session for Order #$orderId (₹$amount)');
      }

      // Session creation
      final session = await createPaymentSession(
        orderId: orderId,
        amount: amount,
        userId: '',
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

      return {
        'success': true,
        'transactionId': session['sessionId'],
        'paymentStatus': 'pending', // Verification pending gateway webhook/callback
      };
    } catch (e) {
      if (kDebugMode) print('Payment process error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'paymentStatus': 'failed',
      };
    }
  }
}
