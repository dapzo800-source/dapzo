import 'dart:convert';
import 'package:http/http.dart' as http;

/// Online payments never touch a payment-gateway secret key inside Flutter.
/// The app calls a Cloudflare Worker, which holds the gateway secret and
/// talks to the payment gateway server-side, per spec section 18:
///   Online Payment -> Cloudflare Worker -> Payment Gateway -> Verification
class PaymentService {
  // TODO: replace with your deployed Cloudflare Worker URL.
  static const String _workerBaseUrl = 'https://dapzo-payments.YOUR_SUBDOMAIN.workers.dev';

  /// Asks the worker to create a payment session/order with the gateway.
  /// Returns gateway session data (e.g. order_id, checkout token) needed
  /// to open the gateway's native checkout UI.
  Future<Map<String, dynamic>> createPaymentSession({
    required String orderId,
    required double amount,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$_workerBaseUrl/create-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderId': orderId,
        'amount': amount,
        'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create payment session');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Called after the gateway checkout completes, so the worker can verify
  /// the payment signature server-side before the order is marked paid.
  Future<bool> verifyPayment({
    required String orderId,
    required Map<String, dynamic> gatewayResponse,
  }) async {
    final response = await http.post(
      Uri.parse('$_workerBaseUrl/verify-payment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderId': orderId,
        'gatewayResponse': gatewayResponse,
      }),
    );

    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body);
    return data['verified'] == true;
  }
}
