import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item_model.dart';

enum OrderStatus {
  placed,
  shopAccepted,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';

      case OrderStatus.shopAccepted:
        return 'Shop Accepted';

      case OrderStatus.preparing:
        return 'Preparing';

      case OrderStatus.ready:
        return 'Ready for Pickup';

      case OrderStatus.outForDelivery:
        return 'Out for Delivery';

      case OrderStatus.delivered:
        return 'Delivered';

      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.placed;
    final clean = value.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');

    switch (clean) {
      case 'placed':
      case 'new':
      case 'orderplaced':
      case 'pending':
        return OrderStatus.placed;

      case 'shopaccepted':
      case 'accepted':
      case 'acceptedbyshop':
      case 'accepted_by_shop':
      case 'orderaccepted':
        return OrderStatus.shopAccepted;

      case 'preparing':
      case 'preparingorder':
      case 'inpreparation':
      case 'cooking':
        return OrderStatus.preparing;

      case 'ready':
      case 'readyforpickup':
      case 'ready_for_pickup':
      case 'orderready':
        return OrderStatus.ready;

      case 'outfordelivery':
      case 'out_for_delivery':
      case 'headingtocustomer':
      case 'pickedup':
      case 'pickedupbydeliverypartner':
      case 'onway':
      case 'ontheway':
        return OrderStatus.outForDelivery;

      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;

      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return OrderStatus.cancelled;

      default:
        return OrderStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == clean,
          orElse: () => OrderStatus.placed,
        );
    }
  }
}

class OrderModel {
  final String id;
  final String orderCode;
  final String userId;
  final String shopId;
  final String shopName;
  final List<CartItemModel> items;

  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double tax;
  final double total;

  final String paymentMethod;
  final String paymentStatus;
  final OrderStatus status;

  final String addressId;
  final Map<String, dynamic> deliveryAddress;

  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final String? deliveryOtp;
  final String? couponCode;

  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.addressId,
    this.deliveryAddress = const {},
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    this.deliveryOtp,
    this.couponCode,
    this.createdAt,
  });

  OrderModel copyWith({
    String? id,
    String? orderCode,
    String? userId,
    String? shopId,
    String? shopName,
    List<CartItemModel>? items,
    double? subtotal,
    double? deliveryCharge,
    double? discount,
    double? tax,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    OrderStatus? status,
    String? addressId,
    Map<String, dynamic>? deliveryAddress,
    String? deliveryPartnerId,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    String? deliveryOtp,
    String? couponCode,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      addressId: addressId ?? this.addressId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      couponCode: couponCode ?? this.couponCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OrderModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final rawData = doc.data();

    final data = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }

      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          value,
        );
      }

      return null;
    }

    double parseDouble(dynamic value, [double fallback = 0.0]) {
      if (value == null) return fallback;
      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
        return parsed ?? fallback;
      }

      return fallback;
    }

    String parseString(
      dynamic value, [
      String fallback = '',
    ]) {
      if (value == null) {
        return fallback;
      }

      return value.toString().trim();
    }

    // Support items, products, orderItems, cartItems, itemsList
    final rawItems = data['items'] ??
        data['products'] ??
        data['orderItems'] ??
        data['cartItems'] ??
        data['itemsList'];

    final parsedItems = <CartItemModel>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        try {
          if (item is Map) {
            parsedItems.add(
              CartItemModel.fromMap(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        } catch (_) {
          // Ignore malformed item
        }
      }
    } else if (rawItems is Map) {
      for (final entry in rawItems.entries) {
        try {
          if (entry.value is Map) {
            parsedItems.add(
              CartItemModel.fromMap(
                Map<String, dynamic>.from(entry.value as Map),
              ),
            );
          }
        } catch (_) {
          // Ignore malformed item
        }
      }
    }

    final primaryShopId =
        parseString(
          data['shopId'] ?? data['storeId'] ?? data['shop_id'],
        ).isNotEmpty
            ? parseString(data['shopId'] ?? data['storeId'] ?? data['shop_id'])
            : (parsedItems.isNotEmpty
                ? parsedItems.first.shopId
                : '');

    final primaryShopName =
        parseString(
          data['shopName'] ??
              data['storeName'] ??
              data['shop_name'] ??
              data['vendorName'] ??
              data['merchantName'],
        ).isNotEmpty
            ? parseString(
                data['shopName'] ??
                    data['storeName'] ??
                    data['shop_name'] ??
                    data['vendorName'] ??
                    data['merchantName'],
              )
            : (parsedItems.isNotEmpty && parsedItems.first.shopName.isNotEmpty
                ? parsedItems.first.shopName
                : 'Dapzo Partner Shop');

    final userId =
        parseString(data['userId']).isNotEmpty
            ? parseString(data['userId'])
            : parseString(data['customerId']);

    Map<String, dynamic> deliveryAddress = {};

    if (data['deliveryAddress'] is Map) {
      deliveryAddress =
          Map<String, dynamic>.from(
        data['deliveryAddress'] as Map,
      );
    }

    final subtotal = parseDouble(
      data['subtotal'] ?? data['subTotal'] ?? data['itemTotal'] ?? data['itemsTotal'],
    );

    final deliveryCharge = parseDouble(
      data['deliveryCharge'] ?? data['deliveryFee'] ?? data['delivery_fee'],
    );

    final discount = parseDouble(
      data['discount'] ?? data['discountAmount'],
    );

    final tax = parseDouble(
      data['tax'] ?? data['taxAmount'] ?? data['taxes'],
    );

    double total = parseDouble(
      data['total'] ??
          data['totalAmount'] ??
          data['grandTotal'] ??
          data['amount'] ??
          data['orderTotal'] ??
          data['netAmount'],
    );

    // If total is 0, compute from subtotal + deliveryCharge + tax - discount or items
    if (total <= 0.0) {
      if (subtotal > 0.0) {
        total = subtotal + deliveryCharge + tax - discount;
      } else if (parsedItems.isNotEmpty) {
        final itemsSum = parsedItems.fold<double>(
          0.0,
          (acc, item) => acc + item.totalPrice,
        );
        total = itemsSum + deliveryCharge + tax - discount;
      }
      if (total < 0.0) total = 0.0;
    }

    final rawOrderCode = parseString(
      data['orderCode'] ??
          data['orderNumber'] ??
          data['order_code'] ??
          data['order_id'] ??
          data['orderId'],
    );

    final orderCode = rawOrderCode.isNotEmpty
        ? (rawOrderCode.startsWith('#')
            ? rawOrderCode.substring(1)
            : rawOrderCode)
        : (doc.id.length > 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id);

    final rawStatus = parseString(
      data['status'] ?? data['orderStatus'] ?? data['order_status'],
      'placed',
    );

    return OrderModel(
      id: doc.id,
      orderCode: orderCode,
      userId: userId,
      shopId: primaryShopId,
      shopName: primaryShopName,
      items: parsedItems,
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      discount: discount,
      tax: tax,
      total: total,
      paymentMethod: parseString(
        data['paymentMethod'] ?? data['payment_method'],
        'cod',
      ),
      paymentStatus: parseString(
        data['paymentStatus'] ?? data['payment_status'],
        'pending',
      ),
      status: OrderStatusX.fromString(rawStatus),
      addressId: parseString(
        data['addressId'] ?? data['address_id'],
      ),
      deliveryAddress: deliveryAddress,
      deliveryPartnerId: data['deliveryPartnerId'] ??
          data['driverId'] ??
          data['deliveryBoyId'],
      deliveryPartnerName: data['deliveryPartnerName'] ??
          data['driverName'] ??
          data['deliveryBoyName'],
      deliveryPartnerPhone: data['deliveryPartnerPhone'] ??
          data['driverPhone'] ??
          data['deliveryBoyPhone'],
      deliveryOtp: parseString(
        data['deliveryOtp'] ?? data['otp'],
      ).isNotEmpty
          ? parseString(data['deliveryOtp'] ?? data['otp'])
          : null,
      couponCode: data['couponCode']?.toString(),
      createdAt: parseDate(
        data['createdAt'] ?? data['created_at'] ?? data['timestamp'],
      ),
    );
  }
}