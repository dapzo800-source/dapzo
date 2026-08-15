import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  Razorpay? _razorpay;

  Function(String orderId, String orderCode, String paymentId)? _onVerifiedSuccess;
  Function(String errorMessage)? _onPaymentError;
  Function(String walletName)? _onExternalWallet;

  // Stored active order payload for verification step
  Map<String, dynamic>? _pendingOrderPayload;
  String? _pendingOrderId;
  String? _currentGatewayOrderId;

  String get apiUrl {
    final url = dotenv.env['DAPZO_API_URL'];
    if (url != null && url.isNotEmpty) {
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
    return 'http://127.0.0.1:8787';
  }

  String get defaultRazorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_live_TJOQUr5qKGOXR8';

  void initialize({
    required Function(String orderId, String orderCode, String paymentId) onVerifiedSuccess,
    required Function(String errorMessage) onPaymentError,
    Function(String walletName)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _onVerifiedSuccess = onVerifiedSuccess;
    _onPaymentError = onPaymentError;
    _onExternalWallet = onExternalWallet;

    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Step 1: Request Cloudflare Worker backend to create a trusted Razorpay Order
  Future<Map<String, dynamic>> createPaymentOrderOnBackend({
    required double amount,
    required String userId,
    required String orderCode,
  }) async {
    final uri = Uri.parse('$apiUrl/api/payments/create-order');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount,
            'currency': 'INR',
            'userId': userId,
            'orderCode': orderCode,
            'receipt': 'rcpt_$orderCode',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = errorData?['error'] ?? 'Unable to connect to payment server';
      throw Exception(msg);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Step 2: Open native Razorpay checkout sheet with gatewayOrderId
  Future<void> startCheckout({
    required double amountInRupees,
    required String orderCode,
    required String userId,
    required String customerPhone,
    required String customerEmail,
    required Map<String, dynamic> orderPayload,
    String? existingOrderId,
  }) async {
    _pendingOrderPayload = orderPayload;
    _pendingOrderId = existingOrderId;

    // 1. Call Cloudflare Worker to create payment order
    final backendOrder = await createPaymentOrderOnBackend(
      amount: amountInRupees,
      userId: userId,
      orderCode: orderCode,
    );

    final gatewayOrderId = backendOrder['gatewayOrderId'] as String;
    final keyId = (backendOrder['keyId'] as String?)?.isNotEmpty == true
        ? backendOrder['keyId'] as String
        : defaultRazorpayKeyId;
    final int amountInPaise = (backendOrder['amount'] as num?)?.toInt() ?? (amountInRupees * 100).round();

    _currentGatewayOrderId = gatewayOrderId;

    final options = {
      'key': keyId,
      'order_id': gatewayOrderId, // Gateway Order ID from Cloudflare Backend
      'amount': amountInPaise,
      'name': 'Dapzo',
      'description': 'Order Payment #$orderCode',
      'currency': 'INR',
      'timeout': 300,
      'prefill': {
        'contact': customerPhone.replaceAll('+91', '').trim(),
        'email': customerEmail.isNotEmpty ? customerEmail : 'customer@dapzo.com',
      },
      'theme': {
        'color': '#FC8019',
      },
      'modal': {
        'confirm_close': true,
      },
      'external': {
        'wallets': ['paytm', 'phonepe']
      }
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      if (kDebugMode) print('Error opening Razorpay checkout: $e');
      throw Exception('Unable to launch payment checkout: $e');
    }
  }

  /// Step 3: Handle Gateway Success -> Call Cloudflare Worker /api/payments/verify
  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final gatewayOrderId = response.orderId ?? _currentGatewayOrderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    if (gatewayOrderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      _onPaymentError?.call('Payment signature missing from gateway response.');
      return;
    }

    try {
      final verifyUri = Uri.parse('$apiUrl/api/payments/verify');
      final verifyResponse = await http
          .post(
            verifyUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'gatewayOrderId': gatewayOrderId,
              'paymentId': paymentId,
              'signature': signature,
              'orderId': _pendingOrderId,
              'orderPayload': _pendingOrderPayload,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final verifyData = jsonDecode(verifyResponse.body) as Map<String, dynamic>;

      if (verifyResponse.statusCode == 200 &&
          verifyData['success'] == true &&
          verifyData['paymentStatus'] == 'paid') {
        final orderId = verifyData['orderId'] as String? ?? _pendingOrderId ?? '';
        final orderCode = verifyData['orderCode'] as String? ?? '';
        _onVerifiedSuccess?.call(orderId, orderCode, paymentId);
      } else {
        final errMsg = verifyData['error'] ?? 'Payment verification failed on server.';
        _onPaymentError?.call(errMsg);
      }
    } catch (e) {
      if (kDebugMode) print('Error during server-side payment verification: $e');
      _onPaymentError?.call('Unable to verify payment with server: $e');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    final msg = response.message?.isNotEmpty == true
        ? response.message!
        : 'Payment cancelled or failed';
    _onPaymentError?.call(msg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (response.walletName != null) {
      _onExternalWallet?.call(response.walletName!);
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
