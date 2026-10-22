import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/domain/models/food_item.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';

/// Represents a distinct line item inside the QuickBite cart.
/// Identity is strictly determined by both the base food item AND
/// its configuration (size, options, instructions).
class CartItem {
  final String id;
  final CartItemConfig config;

  const CartItem({required this.id, required this.config});

  FoodItem get foodItem => config.foodItem;
  Restaurant? get restaurant => config.restaurant;
  int get quantity => config.quantity;
  double get unitPrice => config.unitPrice;
  double get totalPrice => config.totalPrice;
  String get unitPriceFormatted => config.unitPriceFormatted;
  String get totalPriceFormatted => config.totalPriceFormatted;
  String get specialInstructions => config.specialInstructions;

  /// Creates a deterministic ID representing this item and its specific options.
  static String generateId(CartItemConfig config) {
    final foodId = config.foodItem.id;
    final sortedOptionIds = <String>[];
    for (final entry in config.selectedOptions.entries) {
      for (final option in entry.value) {
        sortedOptionIds.add('${entry.key}:${option.id}');
      }
    }
    sortedOptionIds.sort();
    final optionsKey = sortedOptionIds.join('|');
    final noteKey = config.specialInstructions.trim().toLowerCase();
    return '${foodId}_${optionsKey}_$noteKey';
  }

  /// Human-readable summary of customization options.
  /// Example: "Large (12\") • Cheese Burst, Extra Mozzarella"
  String get customizationSummary {
    final parts = <String>[];
    for (final entry in config.selectedOptions.entries) {
      for (final option in entry.value) {
        parts.add(option.name);
      }
    }
    return parts.join(' • ');
  }

  CartItem copyWith({String? id, CartItemConfig? config, int? newQuantity}) {
    return CartItem(
      id: id ?? this.id,
      config: newQuantity != null
          ? this.config.copyWith(quantity: newQuantity)
          : (config ?? this.config),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'config': config.toJson()};
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      config: CartItemConfig.fromJson(json['config'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
