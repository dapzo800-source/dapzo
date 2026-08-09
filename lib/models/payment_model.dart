enum PaymentMethod { cod, online }

enum PaymentStatus { pending, paid, failed, refunded }

class PaymentModel {
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? gatewayTransactionId;
  final DateTime? paidAt;

  PaymentModel({
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    this.gatewayTransactionId,
    this.paidAt,
  });

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'method': method.name,
        'status': status.name,
        'amount': amount,
        'gatewayTransactionId': gatewayTransactionId,
      };
}
