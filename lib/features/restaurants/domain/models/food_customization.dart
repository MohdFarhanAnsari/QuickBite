import 'food_item.dart';
import 'restaurant.dart';

/// Represents a single option within a customization group
/// (e.g., "Large (+₹150)", "Extra Cheese (+₹50)", "Spicy").
class FoodCustomizationOption {
  final String id;
  final String name;
  final double priceModifier;

  const FoodCustomizationOption({
    required this.id,
    required this.name,
    this.priceModifier = 0.0,
  });

  String get priceModifierFormatted {
    if (priceModifier == 0.0) return '';
    return '+₹${priceModifier.toInt()}';
  }

  factory FoodCustomizationOption.fromJson(Map<String, dynamic> json) {
    return FoodCustomizationOption(
      id: json['id'] as String,
      name: json['name'] as String,
      priceModifier: (json['priceModifier'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'priceModifier': priceModifier};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodCustomizationOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a group of customization options (e.g. Size, Spice Level, Add-ons).
class FoodCustomizationGroup {
  final String id;
  final String title;
  final bool isRequired;
  final bool isMultiSelect;
  final List<FoodCustomizationOption> options;

  const FoodCustomizationGroup({
    required this.id,
    required this.title,
    this.isRequired = false,
    this.isMultiSelect = false,
    required this.options,
  });

  factory FoodCustomizationGroup.fromJson(Map<String, dynamic> json) {
    return FoodCustomizationGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
      isMultiSelect: json['isMultiSelect'] as bool? ?? false,
      options: (json['options'] as List<dynamic>)
          .map(
            (e) => FoodCustomizationOption.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isRequired': isRequired,
      'isMultiSelect': isMultiSelect,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

/// Cart-ready configured item model representing user's choices.
/// Prepared for Day 3 persistent Cart foundation.
class CartItemConfig {
  final FoodItem foodItem;
  final Restaurant? restaurant;
  final int quantity;
  final Map<String, List<FoodCustomizationOption>> selectedOptions;
  final String specialInstructions;

  const CartItemConfig({
    required this.foodItem,
    this.restaurant,
    required this.quantity,
    required this.selectedOptions,
    this.specialInstructions = '',
  });

  /// Calculates unit price including selected size and add-on price modifiers.
  double get unitPrice {
    double total = foodItem.price;
    for (final options in selectedOptions.values) {
      for (final option in options) {
        total += option.priceModifier;
      }
    }
    return total;
  }

  /// Total calculated price: unitPrice * quantity.
  double get totalPrice => unitPrice * quantity;

  String get unitPriceFormatted => '₹${unitPrice.toInt()}';
  String get totalPriceFormatted => '₹${totalPrice.toInt()}';

  CartItemConfig copyWith({
    FoodItem? foodItem,
    Restaurant? restaurant,
    int? quantity,
    Map<String, List<FoodCustomizationOption>>? selectedOptions,
    String? specialInstructions,
  }) {
    return CartItemConfig(
      foodItem: foodItem ?? this.foodItem,
      restaurant: restaurant ?? this.restaurant,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodItem': foodItem.toJson(),
      'restaurant': restaurant?.toJson(),
      'quantity': quantity,
      'selectedOptions': selectedOptions.map(
        (key, list) =>
            MapEntry(key, list.map((option) => option.toJson()).toList()),
      ),
      'specialInstructions': specialInstructions,
    };
  }

  factory CartItemConfig.fromJson(Map<String, dynamic> json) {
    final foodItem = FoodItem.fromJson(
      json['foodItem'] as Map<String, dynamic>,
    );
    final restaurant = json['restaurant'] != null
        ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
        : null;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    final specialInstructions = json['specialInstructions'] as String? ?? '';

    final rawOptions = json['selectedOptions'] as Map<String, dynamic>?;
    final selectedOptions = <String, List<FoodCustomizationOption>>{};
    if (rawOptions != null) {
      for (final entry in rawOptions.entries) {
        if (entry.value is List) {
          selectedOptions[entry.key] = (entry.value as List)
              .map(
                (e) =>
                    FoodCustomizationOption.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      }
    }

    return CartItemConfig(
      foodItem: foodItem,
      restaurant: restaurant,
      quantity: quantity,
      selectedOptions: selectedOptions,
      specialInstructions: specialInstructions,
    );
  }
}
