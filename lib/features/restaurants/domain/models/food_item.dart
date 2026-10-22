import 'food_customization.dart';

/// Represents an individual dish / food item in QuickBite.
/// Immutable model with formatting helpers, veg/non-veg flag,
/// and optional data-driven customization groups.
class FoodItem {
  final String id;
  final String restaurantId;
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final double rating;
  final bool isVeg;
  final bool isPopular;
  final String category;
  final List<FoodCustomizationGroup> customizationGroups;

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.rating,
    required this.isVeg,
    this.isPopular = false,
    required this.category,
    this.customizationGroups = const [],
  });

  /// Human-readable price formatted in INR (e.g. ₹349).
  String get priceFormatted => '₹${price.toInt()}';

  FoodItem copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? imageUrl,
    String? description,
    double? price,
    double? rating,
    bool? isVeg,
    bool? isPopular,
    String? category,
    List<FoodCustomizationGroup>? customizationGroups,
  }) {
    return FoodItem(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      isVeg: isVeg ?? this.isVeg,
      isPopular: isPopular ?? this.isPopular,
      category: category ?? this.category,
      customizationGroups: customizationGroups ?? this.customizationGroups,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      isVeg: json['isVeg'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      category: json['category'] as String,
      customizationGroups:
          (json['customizationGroups'] as List<dynamic>?)
              ?.map(
                (e) =>
                    FoodCustomizationGroup.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'price': price,
      'rating': rating,
      'isVeg': isVeg,
      'isPopular': isPopular,
      'category': category,
      'customizationGroups': customizationGroups
          .map((e) => e.toJson())
          .toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
