import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/core/storage/local_storage_service.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:quickbite/features/orders/data/order_repository.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';

/// Fault-injecting storage service used to verify error resilience and cart preservation.
class FaultyStorageService extends LocalStorageService {
  bool shouldFailOrders = false;
  bool shouldFailCart = false;

  FaultyStorageService() : super();

  @override
  Future<void> saveOrders(List<Order> orders) async {
    if (shouldFailOrders) {
      throw Exception('Simulated disk I/O failure writing orders');
    }
    return super.saveOrders(orders);
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    if (shouldFailCart) {
      throw Exception('Simulated disk I/O failure writing cart');
    }
    return super.saveCart(items);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Data Persistence Unit & Integration Tests', () {
    test(
      '1. Cart restoration after restart: items and quantities persist',
      () async {
        final sharedStorage = LocalStorageService();

        // Session 1: Add items to cart
        final container1 = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(sharedStorage),
          ],
        );

        final food = MockRestaurantData.foodItems.first;
        final restaurant = MockRestaurantData.restaurants.first;

        container1
            .read(cartProvider.notifier)
            .addItem(
              CartItemConfig(
                foodItem: food,
                restaurant: restaurant,
                quantity: 2,
                selectedOptions: const {},
              ),
            );

        await container1.read(cartProvider.notifier).saveToStorage();
        final cart1 = container1.read(cartProvider);
        expect(cart1.itemCount, 1);
        expect(cart1.totalQuantity, 2);
        expect(cart1.subtotal, food.price * 2);

        // Session 2: Fresh container with same persistent storage (simulating app restart)
        final container2 = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(sharedStorage),
          ],
        );

        await container2.read(cartProvider.notifier).restoreCart();
        final cart2 = container2.read(cartProvider);

        expect(cart2.itemCount, 1);
        expect(cart2.totalQuantity, 2);
        expect(cart2.items.first.foodItem.id, food.id);
        expect(cart2.items.first.quantity, 2);
        expect(cart2.subtotal, food.price * 2);
      },
    );

    test('2. Quantity and customization restoration: preserves size, crust, addons & notes', () async {
      final sharedStorage = LocalStorageService();

      final container1 = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      final pizzaFood = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      final config = CartItemConfig(
        foodItem: pizzaFood,
        restaurant: restaurant,
        quantity: 3,
        selectedOptions: {
          'size': [
            const FoodCustomizationOption(
              id: 'large',
              name: 'Large (12")',
              priceModifier: 150.0,
            ),
          ],
          'crust': [
            const FoodCustomizationOption(
              id: 'cheese_burst',
              name: 'Cheese Burst Crust',
              priceModifier: 60.0,
            ),
          ],
          'addons': [
            const FoodCustomizationOption(
              id: 'extra_cheese',
              name: 'Extra Mozzarella',
              priceModifier: 50.0,
            ),
          ],
        },
        specialInstructions: 'Well done crust please',
      );

      container1.read(cartProvider.notifier).addItem(config);
      await container1.read(cartProvider.notifier).saveToStorage();

      final expectedUnitPrice = pizzaFood.price + 150.0 + 60.0 + 50.0;
      final expectedTotalPrice = expectedUnitPrice * 3;

      // Session 2: App restart
      final container2 = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      await container2.read(cartProvider.notifier).restoreCart();
      final restoredCart = container2.read(cartProvider);

      expect(restoredCart.items.length, 1);
      final item = restoredCart.items.first;
      expect(item.quantity, 3);
      expect(item.unitPrice, expectedUnitPrice);
      expect(item.totalPrice, expectedTotalPrice);
      expect(item.config.specialInstructions, 'Well done crust please');
      expect(item.config.selectedOptions['size']!.first.name, 'Large (12")');
      expect(
        item.config.selectedOptions['crust']!.first.name,
        'Cheese Burst Crust',
      );
      expect(
        item.config.selectedOptions['addons']!.first.name,
        'Extra Mozzarella',
      );
      expect(item.customizationSummary, contains('Large (12")'));
      expect(item.customizationSummary, contains('Cheese Burst Crust'));
      expect(item.customizationSummary, contains('Extra Mozzarella'));
    });

    test('3. Order history restoration: preserves user orders and avoids duplicate mock orders', () async {
      final sharedStorage = LocalStorageService();

      // Session 1: Initialize repository and place a new user order
      final container1 = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      final repo1 = container1.read(orderRepositoryProvider);
      await repo1.init();

      final initialCount = repo1.getOrders().length;
      expect(initialCount, OrderRepository.defaultMockOrders.length);

      final newOrder = Order(
        orderId: 'QB-2026-9999',
        createdAt: DateTime(2026, 10, 12, 14, 0),
        restaurant: MockRestaurantData.restaurants[0],
        items: [
          CartItem(
            id: 'item_1',
            config: CartItemConfig(
              foodItem: MockRestaurantData.foodItems[0],
              restaurant: MockRestaurantData.restaurants[0],
              quantity: 2,
              selectedOptions: const {},
            ),
          ),
        ],
        subtotal: 698.0,
        deliveryFee: 0.0,
        discount: 50.0,
        total: 648.0,
        deliveryAddress: DeliveryAddress.demoAddresses[0],
        deliveryMethod: DeliveryMethodType.standard,
        paymentMethod: PaymentMethodType.upi,
        status: 'Confirmed',
      );

      await repo1.addOrder(newOrder);
      expect(repo1.getOrders().length, initialCount + 1);
      expect(repo1.getOrders().first.orderId, 'QB-2026-9999');

      // Session 2: App restart
      final container2 = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      final repo2 = container2.read(orderRepositoryProvider);
      await repo2.init();

      final restoredOrders = repo2.getOrders();
      // Total orders must be initialCount + 1 (NO duplicate mock orders!)
      expect(restoredOrders.length, initialCount + 1);
      expect(restoredOrders.first.orderId, 'QB-2026-9999');
      expect(restoredOrders.first.total, 648.0);
      expect(restoredOrders.first.items.first.quantity, 2);
      expect(
        restoredOrders.first.deliveryAddress.streetAddress,
        DeliveryAddress.demoAddresses[0].streetAddress,
      );
      expect(restoredOrders.first.paymentMethod, PaymentMethodType.upi);
      expect(restoredOrders.first.deliveryMethod, DeliveryMethodType.standard);
    });

    test('4. Corrupted JSON handling: handles malformed JSON without throwing or crashing', () async {
      final storage = LocalStorageService();

      // Write completely invalid, malformed JSON string directly into storage
      await storage.setRawDataForTesting(
        LocalStorageService.cartKey,
        '{{malformed json!!...',
      );
      await storage.setRawDataForTesting(
        LocalStorageService.ordersKey,
        '[{"broken json',
      );

      // Load cart should safely catch parse error and return empty list
      final cartItems = await storage.loadCart();
      expect(cartItems, isEmpty);

      // Load orders should safely catch parse error and return empty list
      final orders = await storage.loadOrders();
      expect(orders, isEmpty);

      // Verify CartNotifier safely initializes on corrupted stored data
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );

      await container.read(cartProvider.notifier).restoreCart();
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('5. Corrupted item recovery: skips corrupt entries while retaining valid items', () async {
      final storage = LocalStorageService();
      final food = MockRestaurantData.foodItems.first;
      final validItem = CartItem(
        id: 'valid_1',
        config: CartItemConfig(
          foodItem: food,
          quantity: 1,
          selectedOptions: const {},
        ),
      );

      // Inject a JSON array containing one corrupted entry and one valid entry
      final mixedList = [
        {'invalid_field': 12345}, // Corrupted entry missing required fields
        validItem.toJson(), // Valid entry
      ];

      await storage.setRawDataForTesting(
        LocalStorageService.cartKey,
        jsonEncode(mixedList),
      );

      final loaded = await storage.loadCart();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'valid_1');
      expect(loaded.first.foodItem.name, food.name);
    });

    test('6. Duplicate order prevention: identical orderId deduplicates in history', () async {
      final storage = LocalStorageService();
      final repo = OrderRepository(storageService: storage);
      await repo.init();

      final order = Order(
        orderId: 'QB-2026-DUPLICATE',
        createdAt: DateTime.now(),
        items: const [],
        subtotal: 100.0,
        deliveryFee: 40.0,
        discount: 0.0,
        total: 140.0,
        deliveryAddress: DeliveryAddress.demoAddresses[0],
        deliveryMethod: DeliveryMethodType.standard,
        paymentMethod: PaymentMethodType.cod,
        status: 'Confirmed',
      );

      await repo.addOrder(order);
      final count1 = repo.getOrders().length;

      // Add identical order again
      await repo.addOrder(order);
      final count2 = repo.getOrders().length;

      expect(count1, count2);
      expect(
        repo.getOrders().where((o) => o.orderId == 'QB-2026-DUPLICATE').length,
        1,
      );
    });

    test('7. Persistence failure safety: cart is PRESERVED when order storage fails', () async {
      final faultyStorage = FaultyStorageService();
      faultyStorage.shouldFailOrders = true; // Inject simulated storage failure

      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(faultyStorage),
        ],
      );

      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

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

      final cartBefore = container.read(cartProvider);
      expect(cartBefore.isNotEmpty, isTrue);

      bool cartClearInvoked = false;
      final placedOrder = await container
          .read(checkoutProvider.notifier)
          .placeOrder(
            cart: cartBefore,
            onCartClear: () => cartClearInvoked = true,
          );

      // Order placement MUST fail and return null
      expect(placedOrder, isNull);

      // Cart clear callback MUST NOT be invoked!
      expect(cartClearInvoked, isFalse);

      // Cart contents MUST remain preserved in state!
      final cartAfter = container.read(cartProvider);
      expect(cartAfter.isNotEmpty, isTrue);
      expect(cartAfter.totalQuantity, 2);

      // Checkout state MUST contain a clear user-facing error message
      final checkoutState = container.read(checkoutProvider);
      expect(checkoutState.isProcessing, isFalse);
      expect(checkoutState.errorMessage, contains('Storage failure'));
    });

    test('8. Reorder regression testing: restores all items and configurations to cart', () async {
      final container = ProviderContainer();

      final orders = container.read(orderRepositoryProvider).getOrders();
      final sampleOrder =
          orders.first; // e.g. QB-2026-0042 with multiple items & options

      expect(sampleOrder.items.isNotEmpty, isTrue);

      // Clear cart
      container.read(cartProvider.notifier).clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);

      // Simulate reorder action: re-adding all order items to cart
      for (final item in sampleOrder.items) {
        container.read(cartProvider.notifier).addItem(item.config);
      }

      final restoredCart = container.read(cartProvider);
      expect(restoredCart.itemCount, sampleOrder.items.length);
      expect(restoredCart.totalQuantity, sampleOrder.totalQuantity);
      expect(restoredCart.subtotal, sampleOrder.subtotal);
    });
  });
}
