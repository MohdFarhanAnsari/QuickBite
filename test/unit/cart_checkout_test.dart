import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';

void main() {
  group('CartNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Initial cart is empty with zero counts and totals', () {
      final cart = container.read(cartProvider);
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.deliveryFee, 0.0);
      expect(cart.discount, 0.0);
      expect(cart.grandTotal, 0.0);
    });

    test('2. Add food to cart adds a distinct line item', () {
      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      final config = CartItemConfig(
        foodItem: food,
        restaurant: restaurant,
        quantity: 1,
        selectedOptions: const {},
      );

      container.read(cartProvider.notifier).addItem(config);
      final cart = container.read(cartProvider);

      expect(cart.itemCount, 1);
      expect(cart.totalQuantity, 1);
      expect(cart.items.first.foodItem.id, food.id);
      expect(cart.subtotal, food.price);
    });

    test('3. Same configured item increments quantity rather than creating duplicate', () {
      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      final config = CartItemConfig(
        foodItem: food,
        restaurant: restaurant,
        quantity: 1,
        selectedOptions: const {
          'size': [
            FoodCustomizationOption(
              id: 'reg',
              name: 'Regular',
              priceModifier: 0,
            ),
          ],
        },
      );

      container.read(cartProvider.notifier).addItem(config);
      container.read(cartProvider.notifier).addItem(config);

      final cart = container.read(cartProvider);
      expect(cart.itemCount, 1);
      expect(cart.totalQuantity, 2);
      expect(cart.items.first.quantity, 2);
    });

    test('4. Different customization creates separate cart lines', () {
      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      final regularConfig = CartItemConfig(
        foodItem: food,
        restaurant: restaurant,
        quantity: 1,
        selectedOptions: const {
          'size': [
            FoodCustomizationOption(
              id: 'reg',
              name: 'Regular',
              priceModifier: 0,
            ),
          ],
        },
      );

      final largeConfig = CartItemConfig(
        foodItem: food,
        restaurant: restaurant,
        quantity: 1,
        selectedOptions: const {
          'size': [
            FoodCustomizationOption(
              id: 'large',
              name: 'Large',
              priceModifier: 150,
            ),
          ],
        },
      );

      container.read(cartProvider.notifier).addItem(regularConfig);
      container.read(cartProvider.notifier).addItem(largeConfig);

      final cart = container.read(cartProvider);
      expect(cart.itemCount, 2);
      expect(cart.totalQuantity, 2);
      expect(cart.items[0].unitPrice, food.price);
      expect(cart.items[1].unitPrice, food.price + 150);
    });

    test('5. Increment and Decrement quantity work correctly', () {
      final food = MockRestaurantData.foodItems.first;
      final config = CartItemConfig(
        foodItem: food,
        quantity: 1,
        selectedOptions: const {},
      );

      container.read(cartProvider.notifier).addItem(config);
      final itemId = container.read(cartProvider).items.first.id;

      container.read(cartProvider.notifier).incrementItem(itemId);
      expect(container.read(cartProvider).items.first.quantity, 2);

      container.read(cartProvider.notifier).decrementItem(itemId);
      expect(container.read(cartProvider).items.first.quantity, 1);
    });

    test(
      '6. Decrementing at quantity 1 removes item with UNDO restoration',
      () {
        final food = MockRestaurantData.foodItems.first;
        final config = CartItemConfig(
          foodItem: food,
          quantity: 1,
          selectedOptions: const {},
        );

        container.read(cartProvider.notifier).addItem(config);
        final itemId = container.read(cartProvider).items.first.id;

        container.read(cartProvider.notifier).decrementItem(itemId);
        expect(container.read(cartProvider).isEmpty, isTrue);

        final restored = container.read(cartProvider.notifier).undoRemove();
        expect(restored, isTrue);
        expect(container.read(cartProvider).itemCount, 1);
        expect(container.read(cartProvider).items.first.quantity, 1);
      },
    );

    test('7. Explicit removal and Undo restore exact position', () {
      final food1 = MockRestaurantData.foodItems[0];
      final food2 = MockRestaurantData.foodItems[1];

      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food1,
              quantity: 1,
              selectedOptions: const {},
            ),
          );
      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food2,
              quantity: 2,
              selectedOptions: const {},
            ),
          );

      final firstItemId = container.read(cartProvider).items.first.id;
      container.read(cartProvider.notifier).removeItem(firstItemId);

      expect(container.read(cartProvider).itemCount, 1);
      expect(container.read(cartProvider).items.first.foodItem.id, food2.id);

      container.read(cartProvider.notifier).undoRemove();
      expect(container.read(cartProvider).itemCount, 2);
      expect(container.read(cartProvider).items.first.foodItem.id, food1.id);
    });

    test('8. Clear cart empties everything', () {
      final food = MockRestaurantData.foodItems.first;
      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food,
              quantity: 3,
              selectedOptions: const {},
            ),
          );
      expect(container.read(cartProvider).isNotEmpty, isTrue);

      container.read(cartProvider.notifier).clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('9. Subtotal, Delivery Fee (under ₹499: ₹40, >= ₹499: FREE), and Discount calculations', () {
      final food = MockRestaurantData.foodItems.first; // Price: 349.0

      // Case A: Subtotal ₹349 (< ₹499) -> Delivery fee ₹40, discount 0, total = 349 + 40 = 389
      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food,
              quantity: 1,
              selectedOptions: const {},
            ),
          );
      var cart = container.read(cartProvider);
      expect(cart.subtotal, 349.0);
      expect(cart.isFreeDeliveryUnlocked, isFalse);
      expect(cart.deliveryFee, 40.0);
      expect(cart.freeDeliveryRemaining, 150.0);
      expect(cart.discount, 0.0);
      expect(cart.grandTotal, 389.0);

      // Case B: Subtotal 349 * 2 = 698 (>= ₹499) -> Delivery fee FREE, discount ₹50 (since >= 400), total = 698 - 50 = 648
      container.read(cartProvider.notifier).incrementItem(cart.items.first.id);
      cart = container.read(cartProvider);
      expect(cart.subtotal, 698.0);
      expect(cart.isFreeDeliveryUnlocked, isTrue);
      expect(cart.deliveryFee, 0.0);
      expect(cart.freeDeliveryRemaining, 0.0);
      expect(cart.discount, 50.0);
      expect(cart.grandTotal, 648.0);
    });
  });

  group('CheckoutNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      '10. Defaults to Home address, Standard delivery, and UPI payment',
      () {
        final checkout = container.read(checkoutProvider);
        expect(checkout.selectedAddress.label, 'Home');
        expect(checkout.selectedDeliveryMethod, DeliveryMethodType.standard);
        expect(checkout.selectedPaymentMethod, PaymentMethodType.upi);
        expect(checkout.isProcessing, isFalse);
      },
    );

    test(
      '11. Address, Delivery Speed, and Payment selection updates state',
      () {
        final notifier = container.read(checkoutProvider.notifier);

        notifier.selectAddress(DeliveryAddress.demoAddresses.last);
        expect(container.read(checkoutProvider).selectedAddress.label, 'Work');

        notifier.selectDeliveryMethod(DeliveryMethodType.express);
        expect(
          container.read(checkoutProvider).selectedDeliveryMethod,
          DeliveryMethodType.express,
        );

        notifier.selectPaymentMethod(PaymentMethodType.card);
        expect(
          container.read(checkoutProvider).selectedPaymentMethod,
          PaymentMethodType.card,
        );
      },
    );

    test('12. Empty cart cannot place order', () async {
      final notifier = container.read(checkoutProvider.notifier);
      final emptyCart = container.read(cartProvider);

      bool cartCleared = false;
      final order = await notifier.placeOrder(
        cart: emptyCart,
        onCartClear: () => cartCleared = true,
      );

      expect(order, isNull);
      expect(cartCleared, isFalse);
      expect(container.read(checkoutProvider).errorMessage, isNotNull);
    });

    test('13. Successful order creates deterministic Order and triggers cart clear', () async {
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

      final cart = container.read(cartProvider);
      final notifier = container.read(checkoutProvider.notifier);

      bool cartCleared = false;
      final order = await notifier.placeOrder(
        cart: cart,
        onCartClear: () {
          cartCleared = true;
          container.read(cartProvider.notifier).clearCart();
        },
      );

      expect(order, isNotNull);
      expect(order!.orderId, startsWith('QB-2026-'));
      expect(order.status, 'Confirmed');
      expect(order.items.length, 1);
      expect(order.items.first.quantity, 2);
      expect(cartCleared, isTrue);
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('14. Duplicate order prevention: concurrent/repeated placeOrder calls are blocked', () async {
      final food = MockRestaurantData.foodItems.first;
      final restaurant = MockRestaurantData.restaurants.first;

      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food,
              restaurant: restaurant,
              quantity: 1,
              selectedOptions: const {},
            ),
          );

      final cart = container.read(cartProvider);
      final notifier = container.read(checkoutProvider.notifier);

      int clearCount = 0;
      // Trigger first placeOrder
      final future1 = notifier.placeOrder(
        cart: cart,
        onCartClear: () => clearCount++,
      );

      // Verify that isProcessing is immediately true
      expect(container.read(checkoutProvider).isProcessing, isTrue);

      // Attempt second placeOrder concurrently (e.g. rapid double tap)
      final future2 = notifier.placeOrder(
        cart: cart,
        onCartClear: () => clearCount++,
      );

      final results = await Future.wait([future1, future2]);

      // Exactly one succeeds, the duplicate is blocked and returns null
      expect(results[0], isNotNull);
      expect(results[1], isNull);
      expect(clearCount, 1);
      expect(container.read(checkoutProvider).isProcessing, isFalse);
    });
  });
}
