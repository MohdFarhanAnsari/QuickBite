import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/orders/data/order_repository.dart';
import 'package:quickbite/features/orders/presentation/providers/orders_provider.dart';

class CheckoutState {
  final DeliveryAddress selectedAddress;
  final DeliveryMethodType selectedDeliveryMethod;
  final PaymentMethodType selectedPaymentMethod;
  final bool isProcessing;
  final Order? lastPlacedOrder;
  final String? errorMessage;

  const CheckoutState({
    required this.selectedAddress,
    this.selectedDeliveryMethod = DeliveryMethodType.standard,
    this.selectedPaymentMethod = PaymentMethodType.upi,
    this.isProcessing = false,
    this.lastPlacedOrder,
    this.errorMessage,
  });

  CheckoutState copyWith({
    DeliveryAddress? selectedAddress,
    DeliveryMethodType? selectedDeliveryMethod,
    PaymentMethodType? selectedPaymentMethod,
    bool? isProcessing,
    Order? lastPlacedOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedDeliveryMethod:
          selectedDeliveryMethod ?? this.selectedDeliveryMethod,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      lastPlacedOrder: lastPlacedOrder ?? this.lastPlacedOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    return CheckoutState(selectedAddress: DeliveryAddress.demoAddresses.first);
  }

  void selectAddress(DeliveryAddress address) {
    state = state.copyWith(selectedAddress: address, clearError: true);
  }

  void selectDeliveryMethod(DeliveryMethodType method) {
    state = state.copyWith(selectedDeliveryMethod: method, clearError: true);
  }

  void selectPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(selectedPaymentMethod: method, clearError: true);
  }

  double calculateDeliveryFee(CartState cart) {
    if (cart.isEmpty) return 0.0;
    return cart.deliveryFee + state.selectedDeliveryMethod.additionalFee;
  }

  double calculateTotal(CartState cart) {
    if (cart.isEmpty) return 0.0;
    final fee = calculateDeliveryFee(cart);
    final total = cart.subtotal + fee - cart.discount;
    return total > 0 ? total : 0.0;
  }

  /// Places order with validation, short simulation delay, and cart clearance.
  Future<Order?> placeOrder({
    required CartState cart,
    required void Function() onCartClear,
  }) async {
    if (state.isProcessing) {
      return null;
    }

    if (cart.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Your cart is empty. Add food items before checkout.',
      );
      return null;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    // Simulate order placement network delay
    await Future.delayed(const Duration(milliseconds: 900));

    final fee = calculateDeliveryFee(cart);
    final total = calculateTotal(cart);
    // Determine next unique order ID based on highest existing order number
    int highestNum = 0;
    final existingOrders = ref.read(orderRepositoryProvider).getOrders();
    for (final o in existingOrders) {
      final parts = o.orderId.split('-');
      if (parts.length >= 3) {
        final parsed = int.tryParse(parts.last);
        if (parsed != null && parsed > highestNum) {
          highestNum = parsed;
        }
      }
    }
    final nextNum = (highestNum + 1).toString().padLeft(4, '0');
    final orderId = 'QB-2026-$nextNum';

    final order = Order(
      orderId: orderId,
      createdAt: DateTime.now(),
      restaurant: cart.singleRestaurant,
      items: List.from(cart.items),
      subtotal: cart.subtotal,
      deliveryFee: fee,
      discount: cart.discount,
      total: total,
      deliveryAddress: state.selectedAddress,
      deliveryMethod: state.selectedDeliveryMethod,
      paymentMethod: state.selectedPaymentMethod,
      status: 'Confirmed',
    );

    // Save newly created order to repository with local persistence
    // MUST complete before clearing the cart to prevent data loss on storage failure
    try {
      await ref.read(ordersProvider.notifier).addOrder(order);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage:
            'Storage failure: Could not record order. Cart contents preserved.',
      );
      return null;
    }

    // Cart is cleared ONLY after successful order creation and persistence
    onCartClear();

    state = state.copyWith(
      isProcessing: false,
      lastPlacedOrder: order,
      clearError: true,
    );

    return order;
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);
