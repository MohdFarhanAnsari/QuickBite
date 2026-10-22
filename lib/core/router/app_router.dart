import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/domain/models/order.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/track_order_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/restaurants/presentation/screens/food_details_screen.dart';
import '../../features/restaurants/presentation/screens/restaurant_details_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../shared/widgets/main_shell_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Central routing configuration using GoRouter and StatefulShellRoute.
/// Includes root-level routes for Restaurant Details, Food Customization,
/// Cart, Checkout, Order Success, Order Details, and Track Order.
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // 0. Branded Splash Screen Route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 1. Bottom Tab Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Explore Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Explore',
                  icon: Icons.explore_rounded,
                ),
              ),
            ],
          ),

          // Orders Tab (Day 4: OrdersScreen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),

          // Profile Tab (Day 4: ProfileScreen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // 2. Day 2: Restaurant Details Route (ID-resolved)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/restaurant/:restaurantId',
        builder: (context, state) {
          final restaurantId = state.pathParameters['restaurantId']!;
          return RestaurantDetailsScreen(restaurantId: restaurantId);
        },
      ),

      // 3. Day 2: Food Customization & Details Route (ID-resolved)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/food/:foodId',
        builder: (context, state) {
          final foodId = state.pathParameters['foodId']!;
          return FoodDetailsScreen(foodId: foodId);
        },
      ),

      // 4. Day 3: Cart Route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),

      // 5. Day 3: Checkout Route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      // 6. Day 3: Order Success Route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/order-success',
        builder: (context, state) {
          final order = state.extra as Order?;
          return OrderSuccessScreen(order: order);
        },
      ),

      // 7. Day 4: Order Details Route (ID-resolved)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/order-details/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailsScreen(orderId: orderId);
        },
      ),

      // 8. Day 4: Track Order Route (ID-resolved)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/track-order/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return TrackOrderScreen(orderId: orderId);
        },
      ),
    ],
  );
}
