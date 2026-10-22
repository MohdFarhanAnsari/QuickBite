import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';

enum DeliveryMethodType { standard, express }

extension DeliveryMethodTypeExtension on DeliveryMethodType {
  String get title => switch (this) {
    DeliveryMethodType.standard => 'Standard Delivery',
    DeliveryMethodType.express => 'Express Delivery',
  };

  String get timeEstimate => switch (this) {
    DeliveryMethodType.standard => '30–45 min',
    DeliveryMethodType.express => '20–30 min',
  };

  double get additionalFee => switch (this) {
    DeliveryMethodType.standard => 0.0,
    DeliveryMethodType.express => 49.0,
  };

  String get description => switch (this) {
    DeliveryMethodType.standard => 'FREE on orders ₹499+',
    DeliveryMethodType.express => '+₹49 Priority delivery',
  };
}

enum PaymentMethodType { upi, card, cod }

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get title => switch (this) {
    PaymentMethodType.upi => 'UPI',
    PaymentMethodType.card => 'Credit / Debit Card',
    PaymentMethodType.cod => 'Cash on Delivery',
  };

  String get subtitle => switch (this) {
    PaymentMethodType.upi => 'Google Pay, PhonePe, Paytm',
    PaymentMethodType.card => 'Visa, Mastercard, RuPay',
    PaymentMethodType.cod => 'Pay cash or UPI upon delivery',
  };
}

/// Represents a placed order in QuickBite.
/// Prepared for Day 4 Order History and Tracking.
class Order {
  final String orderId;
  final DateTime createdAt;
  final Restaurant? restaurant;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final DeliveryAddress deliveryAddress;
  final DeliveryMethodType deliveryMethod;
  final PaymentMethodType paymentMethod;
  final String status;

  const Order({
    required this.orderId,
    required this.createdAt,
    this.restaurant,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.deliveryMethod,
    required this.paymentMethod,
    this.status = 'Confirmed',
  });

  String get subtotalFormatted => '₹${subtotal.toInt()}';
  String get deliveryFeeFormatted =>
      deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toInt()}';
  String get discountFormatted => '-₹${discount.toInt()}';
  String get totalFormatted => '₹${total.toInt()}';
  String get estimatedDelivery => deliveryMethod.timeEstimate;

  int get totalQuantity {
    int sum = 0;
    for (final item in items) {
      sum += item.quantity;
    }
    return sum;
  }

  /// Exact sum of item line totals (unit price * quantity for each item).
  double get itemsTotal {
    double sum = 0.0;
    for (final item in items) {
      sum += item.totalPrice;
    }
    return sum;
  }

  /// Verifies price consistency:
  /// 1. itemsTotal equals subtotal
  /// 2. subtotal + deliveryFee - discount equals total
  bool get isPriceConsistent {
    final expectedTotal = (subtotal + deliveryFee - discount).clamp(
      0.0,
      double.infinity,
    );
    return (total - expectedTotal).abs() < 0.01 &&
        (itemsTotal - subtotal).abs() < 0.01;
  }

  Order copyWith({
    String? orderId,
    DateTime? createdAt,
    Restaurant? restaurant,
    List<CartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    DeliveryAddress? deliveryAddress,
    DeliveryMethodType? deliveryMethod,
    PaymentMethodType? paymentMethod,
    String? status,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      restaurant: restaurant ?? this.restaurant,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'restaurant': restaurant?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'deliveryAddress': deliveryAddress.toJson(),
      'deliveryMethod': deliveryMethod.name,
      'paymentMethod': paymentMethod.name,
      'status': status,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'] as String;
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now();
    final restaurant = json['restaurant'] != null
        ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
        : null;

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = <CartItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is Map<String, dynamic>) {
        items.add(CartItem.fromJson(rawItem));
      }
    }

    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (json['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final discount = (json['discount'] as num?)?.toDouble() ?? 0.0;
    final total = (json['total'] as num?)?.toDouble() ?? 0.0;

    final deliveryAddress = DeliveryAddress.fromJson(
      json['deliveryAddress'] as Map<String, dynamic>,
    );

    DeliveryMethodType deliveryMethod;
    try {
      deliveryMethod = DeliveryMethodType.values.byName(
        json['deliveryMethod'] as String? ?? 'standard',
      );
    } catch (_) {
      deliveryMethod = DeliveryMethodType.standard;
    }

    PaymentMethodType paymentMethod;
    try {
      paymentMethod = PaymentMethodType.values.byName(
        json['paymentMethod'] as String? ?? 'upi',
      );
    } catch (_) {
      paymentMethod = PaymentMethodType.upi;
    }

    final status = json['status'] as String? ?? 'Confirmed';

    return Order(
      orderId: orderId,
      createdAt: createdAt,
      restaurant: restaurant,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      deliveryAddress: deliveryAddress,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      status: status,
    );
  }
}
