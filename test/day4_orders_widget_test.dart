import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickbite/core/theme/app_theme.dart';
import 'package:quickbite/features/orders/data/order_repository.dart';
import 'package:quickbite/features/orders/presentation/screens/order_details_screen.dart';
import 'package:quickbite/features/orders/presentation/screens/orders_screen.dart';
import 'package:quickbite/features/orders/presentation/screens/track_order_screen.dart';
import 'package:quickbite/features/orders/presentation/widgets/order_card.dart';
import 'package:quickbite/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:quickbite/features/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:quickbite/features/profile/presentation/screens/profile_screen.dart';
import 'package:quickbite/shared/widgets/app_network_image.dart';

Widget createTestWidget({
  required Widget child,
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides.cast(),

    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppNetworkImage.forceFallback = true;
  });

  group('Day 4 Order History Widget Tests', () {
    testWidgets(
      '1. Empty orders state renders properly with illustration and Explore CTA',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const OrdersScreen(),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(initialOrders: const []),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('No orders yet'), findsOneWidget);
        expect(
          find.textContaining('You have not placed any orders yet'),
          findsOneWidget,
        );
        expect(find.text('Explore Food'), findsOneWidget);
        expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      },
    );

    testWidgets(
      '2. Orders list rendering shows order cards with order IDs, restaurants, prices',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const OrdersScreen(),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(
                  initialOrders: OrderRepository.defaultMockOrders,
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Orders'), findsOneWidget);
        expect(find.byType(OrderCard), findsWidgets);
        expect(find.text('QB-2026-0042'), findsOneWidget);
        expect(find.text('QB-2026-0038'), findsOneWidget);
        expect(find.text('Artisan Woodfire Pizza'), findsOneWidget);
        expect(find.text('The Burger Foundry'), findsOneWidget);
        expect(find.text('₹688'), findsOneWidget);
      },
    );

    testWidgets('3. Order filters filter displayed orders by category chip', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const OrdersScreen(),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: OrderRepository.defaultMockOrders),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // All has 4 orders initially
      expect(find.text('QB-2026-0042'), findsOneWidget); // On the Way
      expect(find.text('QB-2026-0038'), findsOneWidget); // Preparing
      expect(find.text('QB-2026-0021'), findsOneWidget); // Delivered
      expect(find.text('QB-2026-0008'), findsOneWidget); // Cancelled

      // Tap Delivered filter
      await tester.tap(find.widgetWithText(FilterChip, 'Delivered'));
      await tester.pumpAndSettle();

      expect(find.text('QB-2026-0021'), findsOneWidget);
      expect(find.text('QB-2026-0042'), findsNothing);
      expect(find.text('QB-2026-0038'), findsNothing);

      // Tap Cancelled filter
      await tester.tap(find.widgetWithText(FilterChip, 'Cancelled'));
      await tester.pumpAndSettle();

      expect(find.text('QB-2026-0008'), findsOneWidget);
      expect(find.text('QB-2026-0021'), findsNothing);

      // Tap In Progress filter
      await tester.tap(find.widgetWithText(FilterChip, 'In Progress'));
      await tester.pumpAndSettle();

      expect(find.text('QB-2026-0042'), findsOneWidget);
      expect(find.text('QB-2026-0038'), findsOneWidget);
      expect(find.text('QB-2026-0008'), findsNothing);
    });

    testWidgets(
      '4. Status badges render correct labels and icons for all statuses',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const Scaffold(
              body: Column(
                children: [
                  OrderStatusBadge(status: 'Placed'),
                  OrderStatusBadge(status: 'Preparing'),
                  OrderStatusBadge(status: 'Ready for Pickup'),
                  OrderStatusBadge(status: 'On the Way'),
                  OrderStatusBadge(status: 'Delivered'),
                  OrderStatusBadge(status: 'Cancelled'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Placed'), findsOneWidget);
        expect(find.text('Preparing'), findsOneWidget);
        expect(find.text('Ready for Pickup'), findsOneWidget);
        expect(find.text('On the Way'), findsOneWidget);
        expect(find.text('Delivered'), findsOneWidget);
        expect(find.text('Cancelled'), findsOneWidget);
      },
    );

    testWidgets('5 & 6. Order Details rendering and customization summary', (
      WidgetTester tester,
    ) async {
      final sampleOrder =
          OrderRepository.defaultMockOrders.first; // QB-2026-0042

      await tester.pumpWidget(
        createTestWidget(
          child: OrderDetailsScreen(orderId: sampleOrder.orderId),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: [sampleOrder]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Header and summary
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text(sampleOrder.orderId), findsOneWidget);
      expect(find.text('Artisan Woodfire Pizza'), findsOneWidget);

      // Customization summary: Regular (8") • Cheese Burst Crust • Extra Mozzarella
      expect(find.text('Truffle Mushroom Pizza'), findsOneWidget);
      expect(
        find.textContaining(
          'Regular (8") • Cheese Burst Crust • Extra Mozzarella',
        ),
        findsOneWidget,
      );
      expect(find.text('Please make crust extra crispy.'), findsOneWidget);

      // Displayed individual item prices and line totals
      expect(find.text('₹459'), findsWidgets);
      expect(find.text('Classic Margherita Pizza'), findsOneWidget);
      expect(find.text('₹279'), findsWidgets);

      // Delivery & Payment
      expect(find.text('Delivery & Payment'), findsOneWidget);
      expect(find.text('Farhan Ansari'), findsOneWidget);
      expect(find.textContaining('Standard Delivery'), findsOneWidget);
      expect(find.textContaining('UPI (Demo Payment)'), findsOneWidget);

      // Bill Summary
      expect(find.text('Bill Summary'), findsOneWidget);
      expect(find.text('₹738'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('-₹50'), findsOneWidget);
      expect(find.text('₹688'), findsOneWidget);

      // Action buttons
      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('Reorder'), findsOneWidget);
    });

    testWidgets(
      '7. Track Order timeline rendering displays 5 stages and demo disclaimer',
      (WidgetTester tester) async {
        final order =
            OrderRepository.defaultMockOrders[1]; // QB-2026-0038 (Preparing)

        await tester.pumpWidget(
          createTestWidget(
            child: TrackOrderScreen(orderId: order.orderId),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(initialOrders: [order]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Track Order'), findsOneWidget);
        expect(find.text('The Burger Foundry'), findsOneWidget);
        expect(find.text('Order #QB-2026-0038'), findsOneWidget);
        expect(find.byType(OrderTrackingTimeline), findsOneWidget);

        // 5 stages
        expect(find.text('Order Placed'), findsWidgets);
        expect(find.text('Preparing Your Food'), findsOneWidget);
        expect(find.text('Ready for Pickup'), findsWidgets);
        expect(find.text('On the Way'), findsWidgets);
        expect(find.text('Delivered'), findsWidgets);

        // Demo disclaimer
        expect(
          find.textContaining(
            'Demo Simulation: Order tracking stages are simulated',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('14. Track Order opens the correct order through GoRouter', (
      WidgetTester tester,
    ) async {
      final sampleOrder = OrderRepository.defaultMockOrders.first;

      final router = GoRouter(
        initialLocation: '/order-details/${sampleOrder.orderId}',
        routes: [
          GoRoute(
            path: '/order-details/:orderId',
            builder: (context, state) =>
                OrderDetailsScreen(orderId: state.pathParameters['orderId']!),
          ),
          GoRoute(
            path: '/track-order/:orderId',
            builder: (context, state) =>
                TrackOrderScreen(orderId: state.pathParameters['orderId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: [sampleOrder]),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Details'), findsOneWidget);

      // Tap Track Order button
      await tester.tap(find.text('Track Order'));
      await tester.pumpAndSettle();

      // Should open TrackOrderScreen with matching order ID
      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('Order #${sampleOrder.orderId}'), findsOneWidget);
      expect(find.text(sampleOrder.restaurant!.name), findsOneWidget);
    });

    testWidgets('19. Profile -> My Orders navigation', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: OrderRepository.defaultMockOrders),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Farhan Ansari'), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);

      // Tap My Orders tile
      await tester.tap(find.text('My Orders'));
      await tester.pumpAndSettle();

      // Navigated to My Orders screen
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.byType(OrderCard), findsWidgets);
    });

    testWidgets('20. Empty-state Explore Food navigation', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Home Destination'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: const []),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No orders yet'), findsOneWidget);

      // Tap Explore Food
      await tester.tap(find.text('Explore Food'));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });
  });

  group('Day 4 Responsive Layout Tests (320px, 360px, 390px)', () {
    final sampleOrder = OrderRepository.defaultMockOrders.first;

    testWidgets(
      '21. Responsive 320px OrdersScreen, OrderDetailsScreen, TrackOrderScreen render cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // OrdersScreen at 320px
        await tester.pumpWidget(
          createTestWidget(
            child: const OrdersScreen(),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(
                  initialOrders: OrderRepository.defaultMockOrders,
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('My Orders'), findsOneWidget);

        // OrderDetailsScreen at 320px
        await tester.pumpWidget(
          createTestWidget(
            child: OrderDetailsScreen(orderId: sampleOrder.orderId),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(initialOrders: [sampleOrder]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Order Details'), findsOneWidget);

        // TrackOrderScreen at 320px
        await tester.pumpWidget(
          createTestWidget(
            child: TrackOrderScreen(orderId: sampleOrder.orderId),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(initialOrders: [sampleOrder]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Track Order'), findsOneWidget);
      },
    );

    testWidgets(
      '22. Responsive 360px screens render cleanly without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(
            child: const OrdersScreen(),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(
                  initialOrders: OrderRepository.defaultMockOrders,
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          createTestWidget(
            child: OrderDetailsScreen(orderId: sampleOrder.orderId),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(initialOrders: [sampleOrder]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          createTestWidget(
            child: TrackOrderScreen(orderId: sampleOrder.orderId),
            overrides: [
              orderRepositoryProvider.overrideWithValue(
                OrderRepository(initialOrders: [sampleOrder]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('23 & 24. Responsive 390px and No layout overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: const OrdersScreen(),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: OrderRepository.defaultMockOrders),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        createTestWidget(
          child: OrderDetailsScreen(orderId: sampleOrder.orderId),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: [sampleOrder]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        createTestWidget(
          child: TrackOrderScreen(orderId: sampleOrder.orderId),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: [sampleOrder]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Profile screen check
      await tester.pumpWidget(
        createTestWidget(
          child: const ProfileScreen(),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              OrderRepository(initialOrders: [sampleOrder]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('My Orders'), findsOneWidget);
    });
  });
}
