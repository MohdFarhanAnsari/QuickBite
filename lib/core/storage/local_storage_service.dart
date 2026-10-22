import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickbite/features/cart/domain/models/cart_item.dart';
import 'package:quickbite/features/checkout/domain/models/order.dart';

/// Centralized local persistence service for QuickBite.
/// Manages cart items and order history persistence with resilient
/// error handling, corrupted data recovery, and graceful test support.
class LocalStorageService {
  static const String cartKey = 'quickbite_cart_items_v1';
  static const String ordersKey = 'quickbite_orders_v1';
  static const String ordersInitializedKey = 'quickbite_orders_initialized_v1';

  final SharedPreferences? _prefs;
  final Map<String, Object> _inMemoryStore = {};

  LocalStorageService([this._prefs]);

  String? _getString(String key) {
    if (_prefs != null) {
      return _prefs.getString(key);
    }
    return _inMemoryStore[key] as String?;
  }

  bool? _getBool(String key) {
    if (_prefs != null) {
      return _prefs.getBool(key);
    }
    return _inMemoryStore[key] as bool?;
  }

  Future<bool> _setString(String key, String value) async {
    if (_prefs != null) {
      return await _prefs.setString(key, value);
    }
    _inMemoryStore[key] = value;
    return true;
  }

  Future<bool> _setBool(String key, bool value) async {
    if (_prefs != null) {
      return await _prefs.setBool(key, value);
    }
    _inMemoryStore[key] = value;
    return true;
  }

  Future<bool> _remove(String key) async {
    if (_prefs != null) {
      return await _prefs.remove(key);
    }
    _inMemoryStore.remove(key);
    return true;
  }

  /// Injects raw string directly into storage (for corrupted data testing).
  @visibleForTesting
  Future<void> setRawDataForTesting(String key, String rawValue) async {
    await _setString(key, rawValue);
  }

  // ==========================================
  // CART PERSISTENCE
  // ==========================================

  /// Saves current cart items to local storage as JSON.
  Future<void> saveCart(List<CartItem> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final success = await _setString(cartKey, jsonString);
      if (!success) {
        throw Exception('Failed to write cart to local storage.');
      }
    } catch (e, stack) {
      debugPrint('LocalStorageService.saveCart error: $e\n$stack');
      rethrow;
    }
  }

  /// Loads cart items synchronously if data is available.
  List<CartItem>? loadCartSync() {
    try {
      final rawString = _getString(cartKey);
      if (rawString == null || rawString.trim().isEmpty) {
        return [];
      }
      final decoded = jsonDecode(rawString);
      if (decoded is! List) return [];
      final items = <CartItem>[];
      for (final itemJson in decoded) {
        try {
          if (itemJson is Map<String, dynamic>) {
            items.add(CartItem.fromJson(itemJson));
          }
        } catch (_) {}
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Loads cart items from local storage.
  /// Safely catches malformed JSON or corrupted entries and returns valid items.
  Future<List<CartItem>> loadCart() async {
    try {
      final rawString = _getString(cartKey);
      if (rawString == null || rawString.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(rawString);
      if (decoded is! List) {
        debugPrint(
          'LocalStorageService.loadCart warning: stored data is not a JSON list.',
        );
        return [];
      }

      final items = <CartItem>[];
      for (final itemJson in decoded) {
        try {
          if (itemJson is Map<String, dynamic>) {
            items.add(CartItem.fromJson(itemJson));
          }
        } catch (itemError) {
          debugPrint(
            'LocalStorageService.loadCart warning: skipping corrupted cart item: $itemError',
          );
        }
      }
      return items;
    } catch (e) {
      debugPrint(
        'LocalStorageService.loadCart error: corrupted JSON data: $e. Returning empty cart.',
      );
      return [];
    }
  }

  /// Clears stored cart data.
  Future<void> clearCart() async {
    await _remove(cartKey);
  }

  // ==========================================
  // ORDERS PERSISTENCE
  // ==========================================

  /// Saves current orders to local storage as JSON.
  Future<void> saveOrders(List<Order> orders) async {
    try {
      final jsonList = orders.map((order) => order.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final success = await _setString(ordersKey, jsonString);
      if (!success) {
        throw Exception('Failed to write orders to local storage.');
      }
      await _setBool(ordersInitializedKey, true);
    } catch (e, stack) {
      debugPrint('LocalStorageService.saveOrders error: $e\n$stack');
      rethrow;
    }
  }

  /// Loads orders synchronously if data is available.
  List<Order>? loadOrdersSync() {
    try {
      final isInitialized = _getBool(ordersInitializedKey) ?? false;
      final rawString = _getString(ordersKey);

      if (!isInitialized && rawString == null) {
        return null;
      }

      if (rawString == null || rawString.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(rawString);
      if (decoded is! List) return [];

      final orders = <Order>[];
      for (final orderJson in decoded) {
        try {
          if (orderJson is Map<String, dynamic>) {
            orders.add(Order.fromJson(orderJson));
          }
        } catch (_) {}
      }
      return orders;
    } catch (_) {
      return [];
    }
  }

  /// Loads orders from local storage.
  /// Returns `null` if orders have NEVER been initialized in storage (signals first launch).
  /// If initialized (even if empty), returns `List<Order>`.
  Future<List<Order>?> loadOrders() async {
    try {
      final isInitialized = _getBool(ordersInitializedKey) ?? false;
      final rawString = _getString(ordersKey);

      if (!isInitialized && rawString == null) {
        return null;
      }

      if (rawString == null || rawString.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(rawString);
      if (decoded is! List) {
        debugPrint(
          'LocalStorageService.loadOrders warning: stored data is not a JSON list.',
        );
        return [];
      }

      final orders = <Order>[];
      for (final orderJson in decoded) {
        try {
          if (orderJson is Map<String, dynamic>) {
            orders.add(Order.fromJson(orderJson));
          }
        } catch (orderError) {
          debugPrint(
            'LocalStorageService.loadOrders warning: skipping corrupted order: $orderError',
          );
        }
      }
      return orders;
    } catch (e) {
      debugPrint(
        'LocalStorageService.loadOrders error: corrupted JSON data: $e. Returning empty list.',
      );
      return [];
    }
  }

  /// Clears stored order history.
  Future<void> clearOrders() async {
    await _remove(ordersKey);
    await _setBool(ordersInitializedKey, true);
  }
}

/// Optional provider for injecting pre-initialized SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Global provider for LocalStorageService.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});
