import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickbite/core/router/app_router.dart';
import 'package:quickbite/core/theme/app_theme.dart';
import 'package:quickbite/features/cart/presentation/providers/cart_provider.dart';
import 'package:quickbite/features/cart/presentation/screens/cart_screen.dart';
import 'package:quickbite/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:quickbite/features/checkout/presentation/screens/order_success_screen.dart';
import 'package:quickbite/features/home/presentation/screens/home_screen.dart';
import 'package:quickbite/features/home/presentation/widgets/category_chip.dart';
import 'package:quickbite/features/home/presentation/widgets/home_search_bar.dart';
import 'package:quickbite/features/home/presentation/widgets/location_header.dart';
import 'package:quickbite/features/home/presentation/widgets/promo_banner.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/presentation/screens/food_details_screen.dart';
import 'package:quickbite/features/restaurants/presentation/screens/restaurant_details_screen.dart';
import 'package:quickbite/features/restaurants/presentation/widgets/food_card.dart';
import 'package:quickbite/features/restaurants/presentation/widgets/menu_item_card.dart';
import 'package:quickbite/features/restaurants/presentation/widgets/restaurant_card.dart';
import 'package:quickbite/main.dart';
import 'package:quickbite/shared/widgets/app_network_image.dart';

Widget createTestApp({Widget? child}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child ?? const HomeScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    // Prevent GoogleFonts from attempting network calls during tests
    GoogleFonts.config.allowRuntimeFetching = false;
    AppNetworkImage.forceFallback = true;
  });

  group('Day 1 Home Screen Widget Tests', () {
    testWidgets(
      'Home renders LocationHeader, SearchBar, PromoBanner, and Categories',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Location header and greeting
        expect(find.byType(LocationHeader), findsOneWidget);
        expect(find.text('Hazratganj, Lucknow'), findsOneWidget);
        expect(find.textContaining('👋'), findsOneWidget);
        expect(find.text('Deliver to'), findsOneWidget);

        // Search bar
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.text('Search for restaurants or dishes'), findsOneWidget);

        // Promotional Hero Banner
        expect(find.byType(PromoBanner), findsOneWidget);
        expect(find.text('50% OFF'), findsOneWidget);
        expect(find.text('Order now'), findsOneWidget);

        // Craving Categories
        expect(find.text('What are you craving?'), findsOneWidget);
        expect(find.byType(CategoryChip), findsWidgets);
        expect(find.text('Pizza'), findsOneWidget);
        expect(find.text('Burgers'), findsOneWidget);
      },
    );

    testWidgets(
      'LocationHeader personalizes greeting when userName is provided',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(body: LocationHeader(userName: 'Farhan')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Farhan 👋'), findsOneWidget);
      },
    );

    testWidgets('Popular Restaurant cards render with details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Check section header
      expect(find.text('Popular Near You'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      // Restaurant cards
      expect(find.byType(RestaurantCard), findsWidgets);
      expect(
        find.widgetWithText(RestaurantCard, 'Artisan Woodfire Pizza'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Recommended Food dish cards render with add button and price',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Check recommended section
        expect(find.text('Recommended For You'), findsOneWidget);
        expect(find.byType(FoodCard), findsWidgets);
        expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);
        expect(find.text('ADD'), findsWidgets);
      },
    );

    testWidgets('Category selection filters popular restaurants & dishes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap on 'Pizza' category chip
      final pizzaChip = find.text('Pizza');
      expect(pizzaChip, findsOneWidget);
      await tester.tap(pizzaChip);
      await tester.pumpAndSettle();

      // Pizza results should be visible
      expect(
        find.widgetWithText(RestaurantCard, 'Artisan Woodfire Pizza'),
        findsOneWidget,
      );
      expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);
    });

    testWidgets('Search query updates state and filters content dynamically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Type "Ramen" in search bar
      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Ramen');
      await tester.pumpAndSettle();

      // Should display Tokyo Ramen
      expect(
        find.widgetWithText(RestaurantCard, 'Tokyo Ramen & Donburi'),
        findsOneWidget,
      );
      expect(find.text('Spicy Tonkotsu Ramen'), findsOneWidget);
    });

    testWidgets('Shows empty state when search produces no results', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'NonExistentDish12345');
      await tester.pumpAndSettle();

      expect(find.text('No matching dishes or restaurants'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Tap Clear Filters
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(RestaurantCard, 'Artisan Woodfire Pizza'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Bottom navigation renders all 4 tabs and navigates correctly',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: QuickBiteApp()));
        await tester.pumpAndSettle();

        // Navigation Bar items
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Explore'), findsOneWidget);
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Tap on Explore tab
        await tester.tap(find.text('Explore'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'This section will be introduced in subsequent roadmap phases.',
          ),
          findsOneWidget,
        );

        // Switch back to Home tab
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('What are you craving?'), findsOneWidget);
      },
    );
  });

  group('Day 2 Restaurant Details & Menu Tests', () {
    testWidgets(
      'Restaurant Details renders correct restaurant with info and hero',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const RestaurantDetailsScreen(restaurantId: 'rest_1'),
          ),
        );
        await tester.pumpAndSettle();

        // Check restaurant header details
        expect(find.text('Artisan Woodfire Pizza'), findsOneWidget);
        expect(find.text('Italian • Pizza'), findsOneWidget);
        expect(find.text('4.8'), findsOneWidget);
        expect(find.text('OPEN NOW'), findsOneWidget);
        expect(find.text('20-30 min'), findsOneWidget);
        expect(find.text('1.4 km'), findsOneWidget);
        expect(find.text('Free delivery'), findsOneWidget);
      },
    );

    testWidgets('Menu categories render and category filtering works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const RestaurantDetailsScreen(restaurantId: 'rest_1'),
        ),
      );
      await tester.pumpAndSettle();

      // Menu categories
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Starters'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
      expect(find.text('Drinks'), findsOneWidget);

      // Tap on Starters category
      await tester.tap(find.text('Starters'));
      await tester.pumpAndSettle();

      // Cheesy Garlic Breadsticks should now be visible
      expect(find.text('Cheesy Garlic Breadsticks'), findsOneWidget);
    });

    testWidgets('Menu item cards render with ADD button and price', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const RestaurantDetailsScreen(restaurantId: 'rest_1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MenuItemCard), findsWidgets);
      expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);
      expect(find.text('₹349'), findsOneWidget);
      expect(find.text('ADD'), findsWidgets);
    });
  });

  group('Day 2 Food Details & Customization Tests', () {
    testWidgets(
      'Food Details renders correct food, description, and base price',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(child: const FoodDetailsScreen(foodId: 'food_1')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);
        expect(find.text('₹349'), findsWidgets);
        expect(find.text('VEGETARIAN'), findsOneWidget);
        expect(find.text('POPULAR'), findsOneWidget);
        expect(find.text('Choose Size'), findsOneWidget);
        expect(find.text('Add-ons & Dips'), findsOneWidget);
        expect(find.text('Special instructions'), findsOneWidget);
      },
    );

    testWidgets('Quantity selector cannot go below 1 and increases correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const FoodDetailsScreen(foodId: 'food_1')),
      );
      await tester.pumpAndSettle();

      // Initial quantity is 1
      expect(find.text('1'), findsWidgets);

      // Decrement button should be disabled when quantity == 1
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);

      // Increment button
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('Customization options update dynamic total in INR', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const FoodDetailsScreen(foodId: 'food_1')),
      );
      await tester.pumpAndSettle();

      // Initial total for 1 Regular Truffle Mushroom Pizza: ₹349
      expect(find.textContaining('₹349'), findsWidgets);

      // Scroll slightly so size options are clearly in view
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Tap on 'Large (12")' option (+₹150)
      final largeOption = find.text('Large (12")');
      expect(largeOption, findsOneWidget);
      await tester.tap(largeOption);
      await tester.pumpAndSettle();

      // Price should now be 349 + 150 = ₹499
      expect(find.textContaining('₹499'), findsWidgets);

      // Ensure 'Extra Mozzarella' (+₹50) is visible and tap
      final extraCheese = find.text('Extra Mozzarella');
      await tester.ensureVisible(extraCheese);
      await tester.pumpAndSettle();
      expect(extraCheese, findsOneWidget);
      await tester.tap(extraCheese);
      await tester.pumpAndSettle();

      // Price should now be 499 + 50 = ₹549
      expect(find.textContaining('₹549'), findsWidgets);

      // Increment quantity to 2 -> 549 * 2 = ₹1098
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('₹1098'), findsWidgets);
    });

    testWidgets('Special instructions input and Add to Cart confirmation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const FoodDetailsScreen(foodId: 'food_1')),
      );
      await tester.pumpAndSettle();

      // Scroll down to special instructions
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();

      // Enter special instructions note
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Please bake it well done and crispy');
      await tester.pumpAndSettle();
      expect(find.text('Please bake it well done and crispy'), findsOneWidget);

      // Tap Add to Cart
      final addToCartButton = find.byType(ElevatedButton);
      expect(addToCartButton, findsOneWidget);
      await tester.tap(addToCartButton);
      await tester.pumpAndSettle();

      // Shows SnackBar confirmation
      expect(
        find.textContaining('Added 1x Truffle Mushroom Pizza to order'),
        findsOneWidget,
      );
    });
  });

  group('Day 2 Navigation Flow Tests', () {
    testWidgets(
      'Tapping RestaurantCard on Home navigates to RestaurantDetailsScreen',
      (WidgetTester tester) async {
        AppRouter.router.go('/');
        await tester.pumpWidget(const ProviderScope(child: QuickBiteApp()));
        await tester.pumpAndSettle();

        // Scroll down Home screen to reveal restaurant card
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();

        // Find restaurant card and tap
        final restaurantCard = find.widgetWithText(
          RestaurantCard,
          'Artisan Woodfire Pizza',
        );
        expect(restaurantCard, findsOneWidget);
        await tester.tap(restaurantCard);
        await tester.pumpAndSettle();

        // Should now be on Restaurant Details Screen
        expect(find.byType(RestaurantDetailsScreen), findsOneWidget);
        expect(find.text('Italian • Pizza'), findsOneWidget);
      },
    );

    testWidgets('Tapping FoodCard on Home navigates to FoodDetailsScreen', (
      WidgetTester tester,
    ) async {
      AppRouter.router.go('/');
      await tester.pumpWidget(const ProviderScope(child: QuickBiteApp()));
      await tester.pumpAndSettle();

      // Scroll down Home screen to reveal recommended food card
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();

      // Find recommended food card and tap
      final foodCard = find.widgetWithText(FoodCard, 'Truffle Mushroom Pizza');
      expect(foodCard, findsOneWidget);
      await tester.tap(foodCard);
      await tester.pumpAndSettle();

      // Should now be on Food Details Screen
      expect(find.byType(FoodDetailsScreen), findsOneWidget);
      expect(find.text('Choose Size'), findsOneWidget);
    });
  });

  group('Day 2 Responsive Layout Tests (320px, 360px, 390px)', () {
    testWidgets(
      'Restaurant Details renders cleanly at 320px without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(
            child: const RestaurantDetailsScreen(restaurantId: 'rest_1'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RestaurantDetailsScreen), findsOneWidget);
      },
    );

    testWidgets('Food Details renders cleanly at 320px without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(child: const FoodDetailsScreen(foodId: 'food_1')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FoodDetailsScreen), findsOneWidget);
    });

    testWidgets(
      'Restaurant Details & Food Details render cleanly at 360px without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360 * 2, 740 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(
            child: const RestaurantDetailsScreen(restaurantId: 'rest_1'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RestaurantDetailsScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Restaurant Details & Food Details render cleanly at 390px without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const FoodDetailsScreen(foodId: 'food_1')),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(FoodDetailsScreen), findsOneWidget);
      },
    );
  });

  group('Day 3 Cart Screen Widget Tests', () {
    testWidgets(
      'Food Details Add to Cart displays SnackBar and VIEW CART navigates to Cart',
      (WidgetTester tester) async {
        AppRouter.router.go('/food/food_1');
        await tester.pumpWidget(const ProviderScope(child: QuickBiteApp()));
        await tester.pumpAndSettle();

        // 1. Render Food Details
        expect(find.byType(FoodDetailsScreen), findsOneWidget);
        expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);

        // 2. Tap Add to Cart
        final addToCartButton = find.byType(ElevatedButton);
        expect(addToCartButton, findsOneWidget);
        await tester.tap(addToCartButton);
        await tester.pumpAndSettle();

        // 3. Verify SnackBar appears
        expect(
          find.textContaining('Added 1x Truffle Mushroom Pizza to order'),
          findsOneWidget,
        );

        // 4. Find "VIEW CART"
        final viewCartButton = find.text('VIEW CART');
        expect(viewCartButton, findsOneWidget);

        // 5. Tap "VIEW CART"
        await tester.tap(viewCartButton);
        await tester.pumpAndSettle();

        // 6. Verify Cart screen is displayed and item is present
        expect(find.byType(CartScreen), findsOneWidget);
        expect(find.text('Your Cart'), findsOneWidget);
        expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);
      },
    );

    testWidgets(
      'Empty cart renders empty illustration and Explore Food button',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(child: const CartScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Your cart is empty'), findsOneWidget);
        expect(
          find.text(
            "Add your favorite food and we'll deliver it to your door.",
          ),
          findsOneWidget,
        );
        expect(find.text('Explore Food'), findsOneWidget);
      },
    );

    testWidgets(
      'Populated cart renders item card, customization, and updates stepper',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        final food = MockRestaurantData.foodItems.first;
        final restaurant = MockRestaurantData.restaurants.first;

        container
            .read(cartProvider.notifier)
            .addItem(
              CartItemConfig(
                foodItem: food,
                restaurant: restaurant,
                quantity: 1,
                selectedOptions: const {
                  'size': [
                    FoodCustomizationOption(
                      id: 'large',
                      name: 'Large (12")',
                      priceModifier: 150,
                    ),
                  ],
                },
                specialInstructions: 'Well done please',
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CartScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Renders food name and customization summary
        expect(find.text(food.name), findsOneWidget);
        expect(find.text('Large (12")'), findsOneWidget);
        expect(find.text('Well done please'), findsOneWidget);
        expect(find.text('Proceed to Checkout'), findsOneWidget);

        // Increment quantity
        final addIcon = find.descendant(
          of: find.byType(CartItemCard),
          matching: find.byIcon(Icons.add_rounded),
        );
        await tester.tap(addIcon);
        await tester.pumpAndSettle();

        expect(container.read(cartProvider).totalQuantity, 2);
      },
    );

    testWidgets('Removing item shows SnackBar with UNDO and restores on tap', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      final food = MockRestaurantData.foodItems.first;

      container
          .read(cartProvider.notifier)
          .addItem(
            CartItemConfig(
              foodItem: food,
              quantity: 1,
              selectedOptions: const {},
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap remove (close icon on item card)
      final closeIcon = find.descendant(
        of: find.byType(CartItemCard),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Cart is now empty and SnackBar with UNDO is displayed
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      // Tap UNDO
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      // Restored
      expect(find.text(food.name), findsOneWidget);
      expect(container.read(cartProvider).itemCount, 1);
    });
  });

  group('Day 3 Checkout & Order Flow Widget Tests', () {
    testWidgets(
      'Checkout renders address, delivery speed, payment, and items overview',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        final food = MockRestaurantData.foodItems.first;

        container
            .read(cartProvider.notifier)
            .addItem(
              CartItemConfig(
                foodItem: food,
                quantity: 2,
                selectedOptions: const {},
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CheckoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Delivery Address'), findsOneWidget);
        expect(find.text('Delivery Speed'), findsOneWidget);
        expect(find.text('Payment Method'), findsOneWidget);
        expect(find.text('Standard'), findsOneWidget);
        expect(find.text('Express'), findsOneWidget);
        expect(find.text('UPI'), findsOneWidget);
        expect(find.text('Demo Payment'), findsOneWidget);
        expect(find.textContaining('Place Order'), findsOneWidget);
      },
    );

    testWidgets(
      'Order Success screen renders confirmation details and Track Order dialog',
      (WidgetTester tester) async {
        final order = Order(
          orderId: 'QB-2026-0001',
          createdAt: DateTime.now(),
          items: const [],
          subtotal: 698.0,
          deliveryFee: 0.0,
          discount: 50.0,
          total: 648.0,
          deliveryAddress: DeliveryAddress.demoAddresses.first,
          deliveryMethod: DeliveryMethodType.standard,
          paymentMethod: PaymentMethodType.upi,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: OrderSuccessScreen(order: order),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Order Placed Successfully!'), findsOneWidget);
        expect(find.text('QB-2026-0001'), findsOneWidget);
        expect(find.text('30–45 min'), findsOneWidget);
        expect(find.text('Track Order'), findsOneWidget);
        expect(find.text('Continue Shopping'), findsOneWidget);

        // Tap Track Order
        await tester.tap(find.text('Track Order'));
        await tester.pumpAndSettle();

        expect(find.text('Live Tracking'), findsOneWidget);
        expect(find.textContaining('Day 4'), findsOneWidget);
      },
    );
  });

  group('Day 3 Responsive Layout Tests (320px, 360px, 390px)', () {
    testWidgets('CartScreen renders cleanly at 320px without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('CheckoutScreen renders cleanly at 360px without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 2, 740 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets(
      'OrderSuccessScreen renders cleanly at 390px without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const OrderSuccessScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(OrderSuccessScreen), findsOneWidget);
      },
    );
  });
}
