import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite/core/storage/local_storage_service.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/checkout/domain/models/delivery_address.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';

/// Repository managing Order entities with local persistence.
/// Provides deterministic mock orders for testing & review on first launch,
/// persists user-created orders placed via Checkout, and restores on restart.
class OrderRepository {
  final List<Order> _orders;
  final LocalStorageService? _storageService;
  final List<VoidCallback> _listeners = [];
  bool _isUserModified = false;
  bool _isRestored = false;

  OrderRepository({
    List<Order>? initialOrders,
    LocalStorageService? storageService,
  }) : _storageService = storageService,
       _orders = List<Order>.from(
         initialOrders ?? storageService?.loadOrdersSync() ?? defaultMockOrders,
       ) {
    if (initialOrders != null) {
      _isUserModified = true;
      _isRestored = true;
    } else if (storageService?.loadOrdersSync() != null) {
      _isRestored = true;
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Initializes orders from storage (asynchronous fallback).
  Future<void> init() async {
    if (_isRestored || _storageService == null) {
      if (_storageService != null && !_isUserModified) {
        final existing = await _storageService.loadOrders();
        if (existing == null) {
          await _storageService.saveOrders(_orders);
        }
      }
      return;
    }

    try {
      final loaded = await _storageService.loadOrders();
      if (!_isUserModified) {
        if (loaded != null) {
          _orders.clear();
          _orders.addAll(loaded);
        } else {
          await _storageService.saveOrders(_orders);
        }
        _notifyListeners();
      }
      _isRestored = true;
    } catch (e) {
      debugPrint('OrderRepository.init error: $e');
      _isRestored = true;
    }
  }

  /// Returns all stored orders ordered by recency.
  List<Order> getOrders() {
    return List<Order>.unmodifiable(_orders);
  }

  /// Finds an order by its unique ID.
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  /// Adds a newly placed order to the top of the history.
  /// Deduplicates identical order IDs and persists to storage.
  Future<void> addOrder(Order order) async {
    _isUserModified = true;
    // Avoid duplicates if called with identical order ID
    _orders.removeWhere((o) => o.orderId == order.orderId);
    _orders.insert(0, order);
    _notifyListeners();
    if (_storageService != null) {
      await _storageService.saveOrders(_orders);
    }
  }

  /// Updates the status of an existing order.
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    _isUserModified = true;
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      _notifyListeners();
      if (_storageService != null) {
        await _storageService.saveOrders(_orders);
      }
    }
  }

  /// Clears all stored orders (useful for empty state testing).
  Future<void> clearOrders() async {
    _isUserModified = true;
    _orders.clear();
    _notifyListeners();
    if (_storageService != null) {
      await _storageService.clearOrders();
    }
  }

  /// Resets to default portfolio demo orders.
  Future<void> resetToDefault() async {
    _isUserModified = true;
    _orders.clear();
    _orders.addAll(defaultMockOrders);
    _notifyListeners();
    if (_storageService != null) {
      await _storageService.saveOrders(_orders);
    }
  }

  /// Deterministic set of mock orders covering diverse statuses
  /// (Delivered, On the Way, Preparing, Cancelled) and customization options.
  static List<Order> get defaultMockOrders {
    final now = DateTime.now();
    final pizzaRestaurant =
        MockRestaurantData.restaurants[0]; // Artisan Woodfire Pizza
    final burgerRestaurant =
        MockRestaurantData.restaurants[1]; // The Burger Foundry
    final indianRestaurant = MockRestaurantData
        .restaurants[4]; // Saffron Spice Kitchen (Indian • Awadhi)
    final ramenRestaurant =
        MockRestaurantData.restaurants[2]; // Tokyo Ramen & Donburi

    final pizzaFood =
        MockRestaurantData.foodItems[0]; // Truffle Mushroom Pizza (₹349)
    final margheritaFood =
        MockRestaurantData.foodItems[1]; // Classic Margherita Pizza (₹279)
    final burgerFood = MockRestaurantData.foodItems.firstWhere(
      (f) => f.restaurantId == burgerRestaurant.id,
      orElse: () => MockRestaurantData.foodItems[0],
    ); // Double Smash Cheeseburger (₹299)
    final indianFood = MockRestaurantData.foodItems.firstWhere(
      (f) => f.id == 'food_5_2',
      orElse: () => MockRestaurantData.foodItems[0],
    ); // Awadhi Dum Gosht Biryani (₹380)
    final ramenFood = MockRestaurantData.foodItems.firstWhere(
      (f) => f.id == 'food_3',
      orElse: () => MockRestaurantData.foodItems[0],
    ); // Spicy Tonkotsu Ramen (₹379)

    return [
      // 1. Order in progress: On the Way
      // Items: Truffle Mushroom Pizza (₹349 + ₹60 crust + ₹50 extra cheese = ₹459)
      //        + Classic Margherita Pizza (₹279)
      // Displayed item totals = ₹459 + ₹279 = ₹738
      // Subtotal = ₹738, Delivery = FREE (₹0, orders >= ₹499), Discount = ₹50 (orders >= ₹400)
      // Grand Total = ₹738 + ₹0 - ₹50 = ₹688
      Order(
        orderId: 'QB-2026-0042',
        createdAt: now.subtract(const Duration(minutes: 25)),
        restaurant: pizzaRestaurant,
        items: [
          CartItem(
            id: 'cart_mock_1',
            config: CartItemConfig(
              foodItem: pizzaFood,
              restaurant: pizzaRestaurant,
              quantity: 1,
              selectedOptions: {
                'size': [
                  const FoodCustomizationOption(
                    id: 'reg',
                    name: 'Regular (8")',
                    priceModifier: 0,
                  ),
                ],
                'crust': [
                  const FoodCustomizationOption(
                    id: 'cheese_burst',
                    name: 'Cheese Burst Crust',
                    priceModifier: 60,
                  ),
                ],
                'addons': [
                  const FoodCustomizationOption(
                    id: 'extra_cheese',
                    name: 'Extra Mozzarella',
                    priceModifier: 50,
                  ),
                ],
              },
              specialInstructions: 'Please make crust extra crispy.',
            ),
          ),
          CartItem(
            id: 'cart_mock_2',
            config: CartItemConfig(
              foodItem: margheritaFood,
              restaurant: pizzaRestaurant,
              quantity: 1,
              selectedOptions: const {},
            ),
          ),
        ],
        subtotal: 738.0,
        deliveryFee: 0.0,
        discount: 50.0,
        total: 688.0,
        deliveryAddress: DeliveryAddress.demoAddresses[0],
        deliveryMethod: DeliveryMethodType.standard,
        paymentMethod: PaymentMethodType.upi,
        status: 'On the Way',
      ),

      // 2. Order in progress: Preparing
      // Items: Double Smash Cheeseburger (₹299 + ₹40 cheese = ₹339) x 2 = ₹678
      // Subtotal = ₹678, Delivery = Express Priority (₹49), Discount = ₹50 (orders >= ₹400)
      // Grand Total = ₹678 + ₹49 - ₹50 = ₹677
      Order(
        orderId: 'QB-2026-0038',
        createdAt: now.subtract(const Duration(minutes: 12)),
        restaurant: burgerRestaurant,
        items: [
          CartItem(
            id: 'cart_mock_3',
            config: CartItemConfig(
              foodItem: burgerFood,
              restaurant: burgerRestaurant,
              quantity: 2,
              selectedOptions: {
                'spice': [
                  const FoodCustomizationOption(
                    id: 'medium',
                    name: 'Medium Zest',
                    priceModifier: 0,
                  ),
                ],
                'addons': [
                  const FoodCustomizationOption(
                    id: 'extra_cheese',
                    name: 'Aged Cheddar Slice',
                    priceModifier: 40,
                  ),
                ],
              },
              specialInstructions: 'No pickles please.',
            ),
          ),
        ],
        subtotal: 678.0,
        deliveryFee: 49.0,
        discount: 50.0,
        total: 677.0,
        deliveryAddress: DeliveryAddress.demoAddresses[1],
        deliveryMethod: DeliveryMethodType.express,
        paymentMethod: PaymentMethodType.card,
        status: 'Preparing',
      ),

      // 3. Completed order: Delivered
      // Items: Awadhi Dum Gosht Biryani (₹380) x 1 = ₹380
      // Subtotal = ₹380, Delivery = Standard (₹40, orders < ₹499), Discount = ₹0
      // Grand Total = ₹380 + ₹40 - ₹0 = ₹420
      Order(
        orderId: 'QB-2026-0021',
        createdAt: now.subtract(const Duration(hours: 26)),
        restaurant: indianRestaurant,
        items: [
          CartItem(
            id: 'cart_mock_4',
            config: CartItemConfig(
              foodItem: indianFood,
              restaurant: indianRestaurant,
              quantity: 1,
              selectedOptions: {
                'spice': [
                  const FoodCustomizationOption(
                    id: 'mild',
                    name: 'Mild & Aromatic',
                    priceModifier: 0,
                  ),
                ],
              },
            ),
          ),
        ],
        subtotal: 380.0,
        deliveryFee: 40.0,
        discount: 0.0,
        total: 420.0,
        deliveryAddress: DeliveryAddress.demoAddresses[0],
        deliveryMethod: DeliveryMethodType.standard,
        paymentMethod: PaymentMethodType.cod,
        status: 'Delivered',
      ),

      // 4. Cancelled order: Cancelled
      // Items: Spicy Tonkotsu Ramen (₹379) x 1 = ₹379
      // Subtotal = ₹379, Delivery = Standard (₹40), Discount = ₹0
      // Grand Total = ₹379 + ₹40 - ₹0 = ₹419
      Order(
        orderId: 'QB-2026-0008',
        createdAt: now.subtract(const Duration(days: 3)),
        restaurant: ramenRestaurant,
        items: [
          CartItem(
            id: 'cart_mock_5',
            config: CartItemConfig(
              foodItem: ramenFood,
              restaurant: ramenRestaurant,
              quantity: 1,
              selectedOptions: const {},
            ),
          ),
        ],
        subtotal: 379.0,
        deliveryFee: 40.0,
        discount: 0.0,
        total: 419.0,
        deliveryAddress: DeliveryAddress.demoAddresses[0],
        deliveryMethod: DeliveryMethodType.standard,
        paymentMethod: PaymentMethodType.upi,
        status: 'Cancelled',
      ),
    ];
  }
}

/// Global provider for the OrderRepository.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  final repo = OrderRepository(storageService: storageService);
  repo.init();
  return repo;
});
