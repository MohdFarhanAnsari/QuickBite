import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite/core/storage/local_storage_service.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';

/// Centralized state representing the current QuickBite cart.
class CartState {
  final List<CartItem> items;
  final CartItem? lastRemovedItem;
  final int? lastRemovedIndex;

  static const double freeDeliveryThreshold = 499.0;
  static const double standardDeliveryFee = 40.0;
  static const double demoDiscountThreshold = 400.0;
  static const double demoDiscountAmount = 50.0;

  const CartState({
    this.items = const [],
    this.lastRemovedItem,
    this.lastRemovedIndex,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.length;

  int get totalQuantity {
    int total = 0;
    for (final item in items) {
      total += item.quantity;
    }
    return total;
  }

  double get subtotal {
    double sum = 0.0;
    for (final item in items) {
      sum += item.totalPrice;
    }
    return sum;
  }

  bool get isFreeDeliveryUnlocked =>
      isNotEmpty && subtotal >= freeDeliveryThreshold;

  double get freeDeliveryRemaining {
    if (isEmpty || isFreeDeliveryUnlocked) return 0.0;
    return freeDeliveryThreshold - subtotal;
  }

  double get freeDeliveryProgress {
    if (isEmpty) return 0.0;
    if (isFreeDeliveryUnlocked) return 1.0;
    return (subtotal / freeDeliveryThreshold).clamp(0.0, 1.0);
  }

  double get deliveryFee {
    if (isEmpty) return 0.0;
    return isFreeDeliveryUnlocked ? 0.0 : standardDeliveryFee;
  }

  double get discount {
    if (subtotal >= demoDiscountThreshold) {
      return demoDiscountAmount;
    }
    return 0.0;
  }

  double get grandTotal {
    if (isEmpty) return 0.0;
    final total = subtotal + deliveryFee - discount;
    return total > 0 ? total : 0.0;
  }

  String get subtotalFormatted => '₹${subtotal.toInt()}';
  String get deliveryFeeFormatted =>
      deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toInt()}';
  String get discountFormatted => '-₹${discount.toInt()}';
  String get grandTotalFormatted => '₹${grandTotal.toInt()}';

  /// Primary restaurant associated with the cart if items are from a single restaurant.
  Restaurant? get singleRestaurant {
    if (isEmpty) return null;
    final first = items.first.restaurant;
    for (final item in items) {
      if (item.restaurant?.id != first?.id) return null;
    }
    return first;
  }

  /// Groups cart items by their originating restaurant.
  Map<String, List<CartItem>> get itemsByRestaurant {
    final map = <String, List<CartItem>>{};
    for (final item in items) {
      final key = item.restaurant?.name ?? 'QuickBite Partner';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  CartState copyWith({
    List<CartItem>? items,
    CartItem? lastRemovedItem,
    int? lastRemovedIndex,
    bool clearUndo = false,
  }) {
    return CartState(
      items: items ?? this.items,
      lastRemovedItem: clearUndo
          ? null
          : (lastRemovedItem ?? this.lastRemovedItem),
      lastRemovedIndex: clearUndo
          ? null
          : (lastRemovedIndex ?? this.lastRemovedIndex),
    );
  }
}

/// Riverpod notifier managing immutable cart modifications with local persistence.
class CartNotifier extends Notifier<CartState> {
  LocalStorageService? _storageService;
  bool _isUserModified = false;
  bool _isRestored = false;

  bool get isRestored => _isRestored;

  @override
  CartState build() {
    _storageService = ref.watch(localStorageServiceProvider);
    _isUserModified = false;
    _isRestored = false;

    // Fast synchronous load if SharedPreferences is already initialized
    final initialItems = _storageService?.loadCartSync();
    if (initialItems != null && initialItems.isNotEmpty) {
      _isRestored = true;
      return CartState(items: initialItems);
    }

    // Asynchronous load fallback (for test containers or deferred init)
    _restoreFromStorage();

    return const CartState();
  }

  /// Restores cart from local storage safely if the user has not modified it.
  Future<void> _restoreFromStorage() async {
    try {
      final items = await _storageService?.loadCart() ?? [];
      // Prevent race conditions: do not overwrite newer user actions
      if (!_isUserModified && items.isNotEmpty) {
        state = state.copyWith(items: items);
      }
      _isRestored = true;
    } catch (e) {
      debugPrint('CartNotifier._restoreFromStorage error: $e');
      _isRestored = true;
    }
  }

  /// Persists current cart items to local storage.
  void _persistCart() {
    _storageService?.saveCart(state.items).catchError((e) {
      debugPrint('CartNotifier._persistCart error: $e');
    });
  }

  /// Explicitly await saving cart to storage (useful for tests and critical transactions).
  Future<void> saveToStorage() async {
    await _storageService?.saveCart(state.items);
  }

  /// Explicitly trigger restoration from storage (useful in tests).
  Future<void> restoreCart() async {
    await _restoreFromStorage();
  }

  /// Adds a configured food item to the cart.
  /// If an item with the EXACT SAME configuration exists, increments its quantity.
  /// Otherwise, inserts as a new distinct line item.
  void addItem(CartItemConfig config) {
    _isUserModified = true;
    final itemId = CartItem.generateId(config);
    final currentList = List<CartItem>.from(state.items);
    final existingIndex = currentList.indexWhere((item) => item.id == itemId);

    if (existingIndex >= 0) {
      final existing = currentList[existingIndex];
      final updatedQty = existing.quantity + config.quantity;
      currentList[existingIndex] = existing.copyWith(newQuantity: updatedQty);
    } else {
      currentList.add(CartItem(id: itemId, config: config));
    }

    state = state.copyWith(items: currentList, clearUndo: true);
    _persistCart();
  }

  /// Explicitly removes an item line and stores it for UNDO.
  void removeItem(String itemId) {
    _isUserModified = true;
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final removed = state.items[index];
      final updatedList = List<CartItem>.from(state.items)..removeAt(index);
      state = state.copyWith(
        items: updatedList,
        lastRemovedItem: removed,
        lastRemovedIndex: index,
      );
      _persistCart();
    }
  }

  /// Restores the most recently removed item back to its original position.
  bool undoRemove() {
    if (state.lastRemovedItem != null && state.lastRemovedIndex != null) {
      _isUserModified = true;
      final updatedList = List<CartItem>.from(state.items);
      final insertIndex = state.lastRemovedIndex!.clamp(0, updatedList.length);
      updatedList.insert(insertIndex, state.lastRemovedItem!);
      state = state.copyWith(items: updatedList, clearUndo: true);
      _persistCart();
      return true;
    }
    return false;
  }

  /// Increments quantity for a specific cart line item.
  void incrementItem(String itemId) {
    _isUserModified = true;
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      final current = updatedList[index];
      updatedList[index] = current.copyWith(newQuantity: current.quantity + 1);
      state = state.copyWith(items: updatedList);
      _persistCart();
    }
  }

  /// Decrements quantity for a specific cart line item.
  /// When quantity is 1, calling decrement removes the line item with UNDO support.
  void decrementItem(String itemId) {
    _isUserModified = true;
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final current = state.items[index];
      if (current.quantity > 1) {
        final updatedList = List<CartItem>.from(state.items);
        updatedList[index] = current.copyWith(
          newQuantity: current.quantity - 1,
        );
        state = state.copyWith(items: updatedList);
        _persistCart();
      } else {
        removeItem(itemId);
      }
    }
  }

  /// Sets absolute quantity for an item.
  void updateQuantity(String itemId, int newQuantity) {
    _isUserModified = true;
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      updatedList[index] = updatedList[index].copyWith(
        newQuantity: newQuantity,
      );
      state = state.copyWith(items: updatedList);
      _persistCart();
    }
  }

  /// Clears all items in the cart.
  void clearCart() {
    _isUserModified = true;
    state = const CartState();
    _storageService?.clearCart().catchError((e) {
      debugPrint('CartNotifier.clearCart storage error: $e');
    });
  }
}

/// Global provider for the shopping cart.
final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
