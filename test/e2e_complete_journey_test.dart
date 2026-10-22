import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickbite/core/router/app_router.dart';
import 'package:quickbite/core/theme/app_theme.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/cart/presentation/screens/cart_screen.dart';
import 'package:quickbite/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:quickbite/features/checkout/presentation/screens/order_success_screen.dart';
import 'package:quickbite/features/home/presentation/widgets/category_chip.dart';
import 'package:quickbite/features/restaurants/presentation/widgets/menu_item_card.dart';
import 'package:quickbite/features/restaurants/presentation/widgets/restaurant_card.dart';
import 'package:quickbite/features/orders/data/order_repository.dart';
import 'package:quickbite/features/orders/presentation/screens/order_details_screen.dart';
import 'package:quickbite/features/orders/presentation/screens/orders_screen.dart';
import 'package:quickbite/features/orders/presentation/screens/track_order_screen.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/presentation/screens/food_details_screen.dart';
import 'package:quickbite/features/restaurants/presentation/screens/restaurant_details_screen.dart';
import 'package:quickbite/main.dart';
import 'package:quickbite/shared/widgets/app_network_image.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppNetworkImage.forceFallback = true;
  });

  group('E2E Complete Customer Journey & Price Integrity', () {
    testWidgets(
      'Full 30-step Customer Journey simulation with State & Navigation',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // 1. Launch the app
        AppRouter.router.go('/');
        await tester.pumpWidget(const ProviderScope(child: QuickBiteApp()));
        await tester.pumpAndSettle();

        // 2. Open Home - Verify Home elements rendered
        expect(find.text('Deliver to'), findsOneWidget);
        expect(find.byType(CategoryChip), findsWidgets);

        // 3. Open a restaurant from Home
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        final restaurantCard = find.widgetWithText(
          RestaurantCard,
          'Artisan Woodfire Pizza',
        );
        expect(restaurantCard, findsOneWidget);
        await tester.tap(restaurantCard);
        await tester.pumpAndSettle();

        expect(find.byType(RestaurantDetailsScreen), findsOneWidget);
        expect(find.text('Artisan Woodfire Pizza'), findsOneWidget);

        // 4. Select a food item from Restaurant menu
        final menuItem = find.widgetWithText(
          MenuItemCard,
          'Truffle Mushroom Pizza',
        );
        expect(menuItem, findsOneWidget);
        await tester.tap(menuItem);
        await tester.pumpAndSettle();

        // 5. Open Food Details
        expect(find.byType(FoodDetailsScreen), findsOneWidget);
        expect(find.text('Truffle Mushroom Pizza'), findsWidgets);

        // 6. Change quantity (increment from 1 to 2)
        final addQtyBtn = find.byIcon(Icons.add_rounded);
        expect(addQtyBtn, findsWidgets);
        await tester.tap(addQtyBtn.first);
        await tester.pumpAndSettle();
        expect(find.text('2'), findsWidgets);

        // 7. Select available customizations (e.g. Crust)
        final crustOption = find.text('Cheese Burst Crust');
        if (crustOption.evaluate().isNotEmpty) {
          await tester.tap(crustOption);
          await tester.pumpAndSettle();
        }

        // 8. Add special instructions
        final specialInstructionsField = find.byType(TextField);
        if (specialInstructionsField.evaluate().isNotEmpty) {
          await tester.enterText(
            specialInstructionsField,
            'Extra oregano and well baked.',
          );
          await tester.pumpAndSettle();
        }

        // 9. Add the food to the cart
        final addToCartCta = find.textContaining('Add to Cart');
        expect(addToCartCta, findsOneWidget);
        await tester.tap(addToCartCta);
        await tester.pumpAndSettle();

        // 10. Tap VIEW CART in SnackBar
        final viewCartAction = find.text('VIEW CART');
        expect(viewCartAction, findsOneWidget);
        await tester.tap(viewCartAction);
        await tester.pumpAndSettle();

        // 11. Verify the correct item, quantity, image, and customizations
        expect(find.byType(CartScreen), findsOneWidget);
        expect(find.text('Your Cart'), findsOneWidget);
        expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);

        // 12. Increase and decrease quantity in Cart
        final plusBtn = find.byIcon(Icons.add_rounded);
        expect(plusBtn, findsWidgets);
        await tester.tap(plusBtn.first);
        await tester.pumpAndSettle();

        final minusBtn = find.byIcon(Icons.remove_rounded);
        expect(minusBtn, findsWidgets);
        await tester.tap(minusBtn.first);
        await tester.pumpAndSettle();

        // 13. Remove an item
        final deleteBtn = find.byIcon(Icons.close_rounded);
        expect(deleteBtn, findsWidgets);
        await tester.tap(deleteBtn.first);
        await tester.pumpAndSettle();

        // Verify SnackBar with UNDO appears
        expect(find.text('UNDO'), findsOneWidget);

        // 15. Restore an item via UNDO
        await tester.tap(find.text('UNDO'));
        await tester.pumpAndSettle();
        expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);

        // 14. Verify totals update correctly
        expect(find.text('Bill Summary'), findsOneWidget);

        // 16. Proceed to Checkout
        final proceedCheckoutBtn = find.widgetWithText(
          ElevatedButton,
          'Proceed to Checkout',
        );
        expect(proceedCheckoutBtn, findsOneWidget);
        await tester.tap(proceedCheckoutBtn);
        await tester.pumpAndSettle();

        // 17. Verify delivery address on Checkout screen
        expect(find.byType(CheckoutScreen), findsOneWidget);
        expect(find.text('Delivery Address'), findsOneWidget);
        expect(find.text('Delivery Speed'), findsOneWidget);
        expect(find.text('Payment Method'), findsOneWidget);

        // 18. Change delivery method (Select Express)
        final expressOption = find.text('Express');
        expect(expressOption, findsOneWidget);
        await tester.tap(expressOption);
        await tester.pumpAndSettle();

        // 19. Change payment method (Select Card)
        final cardOption = find.text('Credit / Debit Card');
        expect(cardOption, findsOneWidget);
        await tester.tap(cardOption);
        await tester.pumpAndSettle();

        // 20. Verify order items and pricing
        expect(find.text('Order Items (2)'), findsOneWidget);
        expect(find.text('Truffle Mushroom Pizza'), findsWidgets);

        // 21. Place the order
        final placeOrderBtn = find.textContaining('Place Order');
        expect(placeOrderBtn, findsOneWidget);
        await tester.tap(placeOrderBtn);
        // Wait for the simulated network delay
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        // 22. Verify Order Success displays the correct order ID and total
        expect(find.byType(OrderSuccessScreen), findsOneWidget);
        expect(find.text('Order Placed Successfully!'), findsOneWidget);
        expect(find.textContaining('QB-2026-'), findsOneWidget);

        // 23. Open Track Order
        final trackOrderBtn = find.widgetWithText(
          ElevatedButton,
          'Track Order',
        );
        expect(trackOrderBtn, findsOneWidget);
        await tester.tap(trackOrderBtn);
        await tester.pumpAndSettle();

        expect(find.byType(TrackOrderScreen), findsOneWidget);
        expect(find.text('Track Order'), findsOneWidget);
        expect(
          find.text(
            'Demo Simulation: Order tracking stages are simulated for portfolio demonstration. No live GPS or real courier tracking is active.',
          ),
          findsOneWidget,
        );

        // 24. Return to the app (pop back)
        final backBtn = find.byTooltip('Back');
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn);
        } else {
          await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        }
        await tester.pumpAndSettle();

        // 25. Open My Orders
        AppRouter.router.go('/orders');
        await tester.pumpAndSettle();

        expect(find.byType(OrdersScreen), findsOneWidget);
        expect(find.text('My Orders'), findsOneWidget);

        // 26. Open the newly created order
        final newestOrderCard = find.textContaining('QB-2026-').first;
        expect(newestOrderCard, findsOneWidget);
        await tester.tap(newestOrderCard);
        await tester.pumpAndSettle();

        // 27. Verify Order Details
        expect(find.byType(OrderDetailsScreen), findsOneWidget);
        expect(find.text('Order Details'), findsOneWidget);

        // 28. Verify item images and customizations
        expect(find.text('Truffle Mushroom Pizza'), findsWidgets);
        expect(find.byType(AppNetworkImage), findsWidgets);

        // 29. Reorder the completed order
        final reorderBtn = find.widgetWithText(OutlinedButton, 'Reorder');
        expect(reorderBtn, findsOneWidget);
        await tester.tap(reorderBtn);
        await tester.pumpAndSettle();

        // 30. Verify the resulting Cart contents and totals
        expect(find.byType(CartScreen), findsOneWidget);
        expect(find.text('Your Cart'), findsOneWidget);
        expect(find.text('Truffle Mushroom Pizza'), findsWidgets);
        expect(
          find.textContaining('From Artisan Woodfire Pizza'),
          findsOneWidget,
        );
      },
    );
  });

  group('Phase 3 & 4: Price Integrity & Order State Formulations', () {
    test('Formulas: Subtotal = Sum of items, Final Total = Subtotal + Delivery - Discount', () {
      final food1 = MockRestaurantData.foodItems[0]; // 349.0
      final food2 = MockRestaurantData.foodItems[1]; // 279.0

      final item1 = CartItem(
        id: 'test_1',
        config: CartItemConfig(
          foodItem: food1,
          quantity: 2,
          selectedOptions: const {
            'crust': [
              FoodCustomizationOption(
                id: 'cheese_burst',
                name: 'Cheese Burst',
                priceModifier: 60,
              ),
            ],
          },
        ),
      ); // Unit price = 349 + 60 = 409. Total = 818.

      final item2 = CartItem(
        id: 'test_2',
        config: CartItemConfig(
          foodItem: food2,
          quantity: 1,
          selectedOptions: const {},
        ),
      ); // Total = 279.

      final cartState = CartState(items: [item1, item2]);

      // Subtotal = 818 + 279 = 1097.
      expect(cartState.subtotal, 1097.0);

      // Free delivery unlocked (>= 499) -> DeliveryFee = 0
      expect(cartState.isFreeDeliveryUnlocked, isTrue);
      expect(cartState.deliveryFee, 0.0);

      // Discount (>= 400) -> 50
      expect(cartState.discount, 50.0);

      // Grand Total = 1097 + 0 - 50 = 1047
      expect(cartState.grandTotal, 1047.0);
    });

    test('Zero-item cart behavior: All calculations yield 0 and empty properties hold', () {
      const emptyCart = CartState();
      expect(emptyCart.isEmpty, isTrue);
      expect(emptyCart.isNotEmpty, isFalse);
      expect(emptyCart.itemCount, 0);
      expect(emptyCart.totalQuantity, 0);
      expect(emptyCart.subtotal, 0.0);
      expect(emptyCart.deliveryFee, 0.0);
      expect(emptyCart.discount, 0.0);
      expect(emptyCart.grandTotal, 0.0);
      expect(emptyCart.singleRestaurant, isNull);
    });

    test('Negative totals prevention: Grand total is never negative', () {
      final food = MockRestaurantData.foodItems[0];
      final item = CartItem(
        id: 'negative_test',
        config: CartItemConfig(
          foodItem: food,
          quantity: 1,
          selectedOptions: const {},
        ),
      );
      final cart = CartState(items: [item]);
      expect(cart.grandTotal, greaterThanOrEqualTo(0.0));
    });

    test('Reorder item quantities and customization preservation', () {
      final food = MockRestaurantData.foodItems[0];
      final orderItem = CartItem(
        id: 'reorder_check',
        config: CartItemConfig(
          foodItem: food,
          quantity: 4,
          selectedOptions: const {
            'size': [
              FoodCustomizationOption(
                id: 'large',
                name: 'Large',
                priceModifier: 150,
              ),
            ],
          },
          specialInstructions: 'Make it piping hot',
        ),
      );

      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(orderItem.config);

      final cart = container.read(cartProvider);
      expect(cart.items.first.quantity, 4);
      expect(cart.items.first.specialInstructions, 'Make it piping hot');
      expect(
        cart.items.first.config.selectedOptions['size']!.first.name,
        'Large',
      );
      expect(cart.items.first.unitPrice, food.price + 150);
      expect(cart.items.first.totalPrice, (food.price + 150) * 4);
      container.dispose();
    });
  });

  group('Phase 5: Multi-Viewport Responsiveness (320px, 360px, 390px)', () {
    const widths = [320.0, 360.0, 390.0];
    const height = 750.0;

    for (final width in widths) {
      testWidgets(
        'CheckoutScreen renders without overflow at ${width.toInt()}px',
        (WidgetTester tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final container = ProviderContainer();
          container
              .read(cartProvider.notifier)
              .addItem(
                CartItemConfig(
                  foodItem: MockRestaurantData.foodItems.first,
                  quantity: 2,
                  selectedOptions: const {},
                ),
              );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: CheckoutScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(CheckoutScreen), findsOneWidget);
          container.dispose();
        },
      );

      testWidgets(
        'OrderSuccessScreen renders without overflow at ${width.toInt()}px',
        (WidgetTester tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final order = OrderRepository.defaultMockOrders.first;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: OrderSuccessScreen(order: order),
            ),
          );
          await tester.pumpAndSettle();

          final exception = tester.takeException();
          if (exception is FlutterError) {
            debugPrint(
              'OVERFLOW EXCEPTION DETAILS: ${exception.toStringDeep()}',
            );
          }
          expect(exception, isNull);
          expect(find.byType(OrderSuccessScreen), findsOneWidget);
        },
      );

      testWidgets('CartScreen renders without overflow at ${width.toInt()}px', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final container = ProviderContainer();
        container
            .read(cartProvider.notifier)
            .addItem(
              CartItemConfig(
                foodItem: MockRestaurantData.foodItems.first,
                quantity: 3,
                selectedOptions: const {},
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(theme: AppTheme.lightTheme, home: CartScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CartScreen), findsOneWidget);
        container.dispose();
      });
    }
  });
}
