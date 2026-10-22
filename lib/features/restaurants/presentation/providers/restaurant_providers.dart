import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite/features/home/presentation/providers/home_providers.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/domain/models/food_item.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';

/// Fetches restaurant details by unique ID.
final restaurantDetailsProvider = FutureProvider.family<Restaurant?, String>((
  ref,
  restaurantId,
) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.getRestaurantById(restaurantId);
});

/// Tracks favorite status for restaurants (local toggle).
class FavoriteRestaurantsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggleFavorite(String restaurantId) {
    if (state.contains(restaurantId)) {
      state = {...state}..remove(restaurantId);
    } else {
      state = {...state, restaurantId};
    }
  }

  bool isFavorite(String restaurantId) => state.contains(restaurantId);
}

final favoriteRestaurantsProvider =
    NotifierProvider<FavoriteRestaurantsNotifier, Set<String>>(
      FavoriteRestaurantsNotifier.new,
    );

/// State notifier managing active menu category tab for a restaurant.
class SelectedMenuCategoryNotifier extends Notifier<String> {
  final String restaurantId;
  SelectedMenuCategoryNotifier(this.restaurantId);

  @override
  String build() => 'Recommended';

  void setCategory(String category) => state = category;
}

final selectedMenuCategoryProvider =
    NotifierProvider.family<SelectedMenuCategoryNotifier, String, String>(
      SelectedMenuCategoryNotifier.new,
    );

/// Provides the available menu categories for a specific restaurant.
final restaurantMenuCategoriesProvider =
    FutureProvider.family<List<String>, String>((ref, restaurantId) async {
      final repository = ref.watch(restaurantRepositoryProvider);
      final allItems = await repository.getRestaurantMenu(restaurantId);

      final categories = <String>{'Recommended'};
      for (final item in allItems) {
        if (item.category.isNotEmpty) {
          categories.add(item.category);
        }
      }
      return categories.toList();
    });

/// Provides menu items filtered by the currently selected menu category.
final restaurantMenuProvider = FutureProvider.family<List<FoodItem>, String>((
  ref,
  restaurantId,
) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  final activeCategory = ref.watch(selectedMenuCategoryProvider(restaurantId));

  return repository.getRestaurantMenu(restaurantId, category: activeCategory);
});

/// Fetches a specific food item by ID for the Food Details screen.
final foodDetailsProvider = FutureProvider.family<FoodItem?, String>((
  ref,
  foodId,
) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.getFoodItemById(foodId);
});

/// State representation for active customization in Food Details screen.
class FoodCustomizationState {
  final FoodItem foodItem;
  final int quantity;
  final Map<String, List<FoodCustomizationOption>> selectedOptions;
  final String specialInstructions;

  const FoodCustomizationState({
    required this.foodItem,
    this.quantity = 1,
    this.selectedOptions = const {},
    this.specialInstructions = '',
  });

  /// Dynamic unit price taking base item price and modifiers into account.
  double get unitPrice {
    double total = foodItem.price;
    for (final options in selectedOptions.values) {
      for (final option in options) {
        total += option.priceModifier;
      }
    }
    return total;
  }

  /// Dynamic total price: unitPrice * quantity.
  double get totalPrice => unitPrice * quantity;

  String get unitPriceFormatted => '₹${unitPrice.toInt()}';
  String get totalPriceFormatted => '₹${totalPrice.toInt()}';

  FoodCustomizationState copyWith({
    FoodItem? foodItem,
    int? quantity,
    Map<String, List<FoodCustomizationOption>>? selectedOptions,
    String? specialInstructions,
  }) {
    return FoodCustomizationState(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

/// Controller managing customization state (size, add-ons, quantity, instructions).
class FoodCustomizationNotifier extends Notifier<FoodCustomizationState> {
  final FoodItem initialFoodItem;
  FoodCustomizationNotifier(this.initialFoodItem);

  @override
  FoodCustomizationState build() {
    // Automatically select default options for required single-select groups (e.g. Size, Crust, Spice)
    final initialSelections = <String, List<FoodCustomizationOption>>{};
    for (final group in initialFoodItem.customizationGroups) {
      if (group.isRequired &&
          !group.isMultiSelect &&
          group.options.isNotEmpty) {
        initialSelections[group.id] = [group.options.first];
      } else {
        initialSelections[group.id] = [];
      }
    }

    return FoodCustomizationState(
      foodItem: initialFoodItem,
      quantity: 1,
      selectedOptions: initialSelections,
    );
  }

  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  void selectSingleOption(String groupId, FoodCustomizationOption option) {
    final current = Map<String, List<FoodCustomizationOption>>.from(
      state.selectedOptions,
    );
    current[groupId] = [option];
    state = state.copyWith(selectedOptions: current);
  }

  void toggleMultiOption(String groupId, FoodCustomizationOption option) {
    final current = Map<String, List<FoodCustomizationOption>>.from(
      state.selectedOptions,
    );
    final groupList = List<FoodCustomizationOption>.from(
      current[groupId] ?? [],
    );

    if (groupList.any((o) => o.id == option.id)) {
      groupList.removeWhere((o) => o.id == option.id);
    } else {
      groupList.add(option);
    }

    current[groupId] = groupList;
    state = state.copyWith(selectedOptions: current);
  }

  void setSpecialInstructions(String note) {
    state = state.copyWith(specialInstructions: note);
  }

  CartItemConfig toCartItemConfig({Restaurant? restaurant}) {
    return CartItemConfig(
      foodItem: state.foodItem,
      restaurant: restaurant,
      quantity: state.quantity,
      selectedOptions: state.selectedOptions,
      specialInstructions: state.specialInstructions,
    );
  }
}

final foodCustomizationProvider =
    NotifierProvider.family<
      FoodCustomizationNotifier,
      FoodCustomizationState,
      FoodItem
    >(FoodCustomizationNotifier.new);
