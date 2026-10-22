import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:quickbite/features/orders/data/order_repository.dart';
import 'package:quickbite/features/orders/presentation/providers/orders_provider.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';

void main() {
  group('Day 4 Order History & Lifecycle Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            OrderRepository(initialOrders: const []),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('OrderRepository starts empty when initialized with empty list', () {
      final repo = container.read(orderRepositoryProvider);
      expect(repo.getOrders(), isEmpty);
      expect(repo.getOrderById('QB-2026-9999'), isNull);
    });

    test('8. Placed status mapping', () {
      expect(
        QuickBiteOrderStatus.fromString('Placed'),
        QuickBiteOrderStatus.placed,
      );
      expect(
        QuickBiteOrderStatus.fromString('Confirmed'),
        QuickBiteOrderStatus.placed,
      );
      expect(QuickBiteOrderStatus.fromString('placed').label, 'Placed');
      expect(QuickBiteOrderStatus.placed.isInProgress, isTrue);
    });

    test('9. Preparing status mapping', () {
      expect(
        QuickBiteOrderStatus.fromString('Preparing'),
        QuickBiteOrderStatus.preparing,
      );
      expect(
        QuickBiteOrderStatus.fromString('in prep'),
        QuickBiteOrderStatus.preparing,
      );
      expect(QuickBiteOrderStatus.preparing.label, 'Preparing');
      expect(QuickBiteOrderStatus.preparing.isInProgress, isTrue);
    });

    test('10. On the Way status mapping', () {
      expect(
        QuickBiteOrderStatus.fromString('On the Way'),
        QuickBiteOrderStatus.onTheWay,
      );
      expect(
        QuickBiteOrderStatus.fromString('out for delivery'),
        QuickBiteOrderStatus.onTheWay,
      );
      expect(QuickBiteOrderStatus.onTheWay.label, 'On the Way');
      expect(QuickBiteOrderStatus.onTheWay.isInProgress, isTrue);
    });

    test('11. Delivered status mapping', () {
      expect(
        QuickBiteOrderStatus.fromString('Delivered'),
        QuickBiteOrderStatus.delivered,
      );
      expect(QuickBiteOrderStatus.delivered.label, 'Delivered');
      expect(QuickBiteOrderStatus.delivered.isInProgress, isFalse);
    });

    test('Ready for Pickup and Cancelled status mappings', () {
      expect(
        QuickBiteOrderStatus.fromString('Ready for Pickup'),
        QuickBiteOrderStatus.readyForPickup,
      );
      expect(QuickBiteOrderStatus.readyForPickup.label, 'Ready for Pickup');
      expect(QuickBiteOrderStatus.readyForPickup.isInProgress, isTrue);

      expect(
        QuickBiteOrderStatus.fromString('Cancelled'),
        QuickBiteOrderStatus.cancelled,
      );
      expect(QuickBiteOrderStatus.cancelled.label, 'Cancelled');
      expect(QuickBiteOrderStatus.cancelled.isInProgress, isFalse);
    });

    test('12 & 13. Successful checkout adds order to history and appears in My Orders', () async {
      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      // Add item to cart
      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food,
              restaurant: restaurant,
              quantity: 2,
              selectedOptions: const {},
            ),
          );

      final cart = container.read(cartProvider);
      expect(cart.isNotEmpty, isTrue);

      // Verify orders history is initially empty
      expect(container.read(ordersProvider).orders, isEmpty);

      // Place order via CheckoutNotifier
      final notifier = container.read(checkoutProvider.notifier);
      final order = await notifier.placeOrder(
        cart: cart,
        onCartClear: () => container.read(cartProvider.notifier).clearCart(),
      );

      expect(order, isNotNull);
      expect(order!.orderId, startsWith('QB-2026-'));

      // Cart is cleared
      expect(container.read(cartProvider).isEmpty, isTrue);

      // 12. Order was added to orders history
      final ordersState = container.read(ordersProvider);
      expect(ordersState.orders.length, 1);
      expect(ordersState.orders.first.orderId, order.orderId);

      // 13. Order appears in My Orders via lookup
      final retrieved = ordersState.getOrderById(order.orderId);
      expect(retrieved, isNotNull);
      expect(retrieved!.total, order.total);
      expect(retrieved.items.length, 1);
      expect(retrieved.items.first.quantity, 2);
    });

    test(
      'Order filters work properly (All, In Progress, Delivered, Cancelled)',
      () {
        final repo = OrderRepository(
          initialOrders: OrderRepository.defaultMockOrders,
        );
        final testContainer = ProviderContainer(
          overrides: [orderRepositoryProvider.overrideWithValue(repo)],
        );

        final ordersNotifier = testContainer.read(ordersProvider.notifier);
        var state = testContainer.read(ordersProvider);

        // Default filter is All (4 mock orders)
        expect(state.activeFilter, OrderFilter.all);
        expect(state.filteredOrders.length, 4);

        // Filter: In Progress (On the Way & Preparing -> 2 orders)
        ordersNotifier.setFilter(OrderFilter.inProgress);
        state = testContainer.read(ordersProvider);
        expect(state.filteredOrders.length, 2);
        expect(
          state.filteredOrders.every(
            (o) => QuickBiteOrderStatus.fromString(o.status).isInProgress,
          ),
          isTrue,
        );

        // Filter: Delivered (1 order)
        ordersNotifier.setFilter(OrderFilter.delivered);
        state = testContainer.read(ordersProvider);
        expect(state.filteredOrders.length, 1);
        expect(state.filteredOrders.first.status, 'Delivered');

        // Filter: Cancelled (1 order)
        ordersNotifier.setFilter(OrderFilter.cancelled);
        state = testContainer.read(ordersProvider);
        expect(state.filteredOrders.length, 1);
        expect(state.filteredOrders.first.status, 'Cancelled');

        testContainer.dispose();
      },
    );

    test('15, 16, 17, 18. Reorder adds items, preserves quantity & customization, and recalculates total', () {
      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      final customOptions = {
        'size': [
          const FoodCustomizationOption(
            id: 'large',
            name: 'Large (12")',
            priceModifier: 150,
          ),
        ],
        'crust': [
          const FoodCustomizationOption(
            id: 'cheese_burst',
            name: 'Cheese Burst Crust',
            priceModifier: 60,
          ),
        ],
      };

      final orderItem = CartItem(
        id: 'mock_reorder_item_1',
        config: CartItemConfig(
          foodItem: food,
          restaurant: restaurant,
          quantity: 3,
          selectedOptions: customOptions,
          specialInstructions: 'Extra well done',
        ),
      );

      final order = Order(
        orderId: 'QB-2026-TEST',
        createdAt: DateTime.now(),
        restaurant: restaurant,
        items: [orderItem],
        subtotal: orderItem.totalPrice,
        deliveryFee: 0.0,
        discount: 50.0,
        total: orderItem.totalPrice - 50.0,
        deliveryAddress: DeliveryAddress.demoAddresses.first,
        deliveryMethod: DeliveryMethodType.standard,
        paymentMethod: PaymentMethodType.upi,
        status: 'Delivered',
      );

      // Ensure cart starts empty
      final cartNotifier = container.read(cartProvider.notifier);
      expect(container.read(cartProvider).isEmpty, isTrue);

      // 15. Reorder adds items to existing cart
      for (final item in order.items) {
        cartNotifier.addItem(item.config);
      }

      final updatedCart = container.read(cartProvider);
      expect(updatedCart.items.length, 1);

      // 16. Reorder preserves quantity
      final reorderedItem = updatedCart.items.first;
      expect(reorderedItem.quantity, 3);

      // 17. Reorder preserves supported customization
      expect(
        reorderedItem.config.selectedOptions['size']!.first.name,
        'Large (12")',
      );
      expect(
        reorderedItem.config.selectedOptions['crust']!.first.name,
        'Cheese Burst Crust',
      );
      expect(reorderedItem.specialInstructions, 'Extra well done');

      // 18. Cart total recalculates correctly
      // Unit price = 349 (base) + 150 (size) + 60 (crust) = 559.
      // 3 items = 1677.
      // Subtotal = 1677. Free delivery unlocked (>= 499). Discount = 50 (>= 400).
      // Grand Total = 1677 + 0 - 50 = 1627.
      expect(reorderedItem.unitPrice, 559.0);
      expect(reorderedItem.totalPrice, 1677.0);
      expect(updatedCart.subtotal, 1677.0);
      expect(updatedCart.isFreeDeliveryUnlocked, isTrue);
      expect(updatedCart.deliveryFee, 0.0);
      expect(updatedCart.discount, 50.0);
      expect(updatedCart.grandTotal, 1627.0);
    });

    test('Updating order status reflects immediately in OrderRepository and OrdersProvider', () {
      final repo = OrderRepository(
        initialOrders: OrderRepository.defaultMockOrders,
      );
      final testContainer = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repo)],
      );

      final notifier = testContainer.read(ordersProvider.notifier);
      final initialOrder = testContainer
          .read(ordersProvider)
          .getOrderById('QB-2026-0038');
      expect(initialOrder!.status, 'Preparing');

      notifier.updateOrderStatus('QB-2026-0038', 'Ready for Pickup');
      final updatedOrder = testContainer
          .read(ordersProvider)
          .getOrderById('QB-2026-0038');
      expect(updatedOrder!.status, 'Ready for Pickup');

      testContainer.dispose();
    });

    test('Price Consistency Audit for order QB-2026-0042', () {
      final repo = OrderRepository(
        initialOrders: OrderRepository.defaultMockOrders,
      );
      final order = repo.getOrderById('QB-2026-0042');
      expect(order, isNotNull);

      // 1. Verify individual item unit prices and line totals
      // Item 1: Truffle Mushroom Pizza (Base: ₹349, Cheese Burst: +₹60, Extra Mozzarella: +₹50)
      final item1 = order!.items[0];
      expect(item1.foodItem.name, 'Truffle Mushroom Pizza');
      expect(item1.unitPrice, 459.0);
      expect(item1.quantity, 1);
      expect(item1.totalPrice, 459.0);

      // Item 2: Classic Margherita Pizza (Base: ₹279, No add-ons: +₹0)
      final item2 = order.items[1];
      expect(item2.foodItem.name, 'Classic Margherita Pizza');
      expect(item2.unitPrice, 279.0);
      expect(item2.quantity, 1);
      expect(item2.totalPrice, 279.0);

      // 2. Verify displayed item totals sum
      final displayedItemTotalsSum = item1.totalPrice + item2.totalPrice;
      expect(displayedItemTotalsSum, 738.0);
      expect(order.itemsTotal, 738.0);

      // 3. Verify subtotal matches items total exactly
      expect(order.subtotal, 738.0);
      expect(order.subtotalFormatted, '₹738');

      // 4. Verify delivery fee (Standard delivery: FREE for orders >= ₹499)
      expect(order.deliveryFee, 0.0);
      expect(order.deliveryFeeFormatted, 'FREE');

      // 5. Verify discount (Promo discount: ₹50 for orders >= ₹400)
      expect(order.discount, 50.0);
      expect(order.discountFormatted, '-₹50');

      // 6. Verify final order total: Subtotal (738) + DeliveryFee (0) - Discount (50) = 688
      final calculatedTotal =
          order.subtotal + order.deliveryFee - order.discount;
      expect(calculatedTotal, 688.0);
      expect(order.total, 688.0);
      expect(order.totalFormatted, '₹688');

      // 7. Overall price consistency flag
      expect(order.isPriceConsistent, isTrue);
    });

    test('All deterministic mock orders satisfy price consistency', () {
      final mockOrders = OrderRepository.defaultMockOrders;
      expect(mockOrders.length, 4);

      for (final order in mockOrders) {
        // Items sum must equal subtotal
        expect(
          order.itemsTotal,
          order.subtotal,
          reason: 'Order ${order.orderId} itemsTotal does not match subtotal',
        );

        // Subtotal + deliveryFee - discount must equal total
        final expectedTotal =
            (order.subtotal + order.deliveryFee - order.discount).clamp(
              0.0,
              double.infinity,
            );
        expect(
          order.total,
          expectedTotal,
          reason:
              'Order ${order.orderId} total does not match expected formula',
        );

        expect(
          order.isPriceConsistent,
          isTrue,
          reason:
              'Order ${order.orderId} isPriceConsistent flag should be true',
        );
      }
    });
  });
}
