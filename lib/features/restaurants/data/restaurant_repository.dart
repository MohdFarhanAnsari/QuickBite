import '../domain/models/food_item.dart';
import '../domain/models/restaurant.dart';
import 'mock_restaurant_data.dart';

/// Contract for fetching restaurant and food item data.
/// Enables seamless swapping from local deterministic mock data
/// to remote Dio HTTP client implementation in future stages.
abstract class RestaurantRepository {
  /// Fetches all available restaurants.
  Future<List<Restaurant>> getRestaurants();

  /// Fetches top-rated / featured restaurants for the popular section.
  Future<List<Restaurant>> getPopularRestaurants();

  /// Fetches recommended food items for the home screen.
  Future<List<FoodItem>> getRecommendedFoodItems();

  /// Fetches a specific restaurant by unique [id].
  Future<Restaurant?> getRestaurantById(String id);

  /// Fetches the menu items of a specific restaurant, optionally filtered by category.
  Future<List<FoodItem>> getRestaurantMenu(
    String restaurantId, {
    String? category,
  });

  /// Fetches a specific food item by its unique [id].
  Future<FoodItem?> getFoodItemById(String id);

  /// Searches and filters restaurants based on search keyword and category.
  Future<List<Restaurant>> searchRestaurants({
    String? query,
    String? categoryId,
  });

  /// Searches and filters food items based on search keyword and category.
  Future<List<FoodItem>> searchFoodItems({String? query, String? categoryId});
}

/// Day 1 & Day 2 Mock implementation of [RestaurantRepository].
/// Operates on local in-memory deterministic data without network latency.
class MockRestaurantRepository implements RestaurantRepository {
  const MockRestaurantRepository();

  @override
  Future<List<Restaurant>> getRestaurants() async {
    return MockRestaurantData.restaurants;
  }

  @override
  Future<List<Restaurant>> getPopularRestaurants() async {
    return MockRestaurantData.restaurants
        .where((r) => r.isFeatured || r.rating >= 4.7)
        .toList();
  }

  @override
  Future<List<FoodItem>> getRecommendedFoodItems() async {
    return MockRestaurantData.foodItems;
  }

  @override
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      return MockRestaurantData.restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FoodItem>> getRestaurantMenu(
    String restaurantId, {
    String? category,
  }) async {
    var items = MockRestaurantData.foodItems
        .where((item) => item.restaurantId == restaurantId)
        .toList();

    if (category != null && category.isNotEmpty && category != 'Recommended') {
      final catLower = category.toLowerCase();
      items = items
          .where((item) => item.category.toLowerCase() == catLower)
          .toList();
    }

    return items;
  }

  @override
  Future<FoodItem?> getFoodItemById(String id) async {
    try {
      return MockRestaurantData.foodItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Restaurant>> searchRestaurants({
    String? query,
    String? categoryId,
  }) async {
    var results = MockRestaurantData.restaurants;

    if (categoryId != null && categoryId.isNotEmpty) {
      final categoryLower = categoryId.toLowerCase();
      results = results.where((r) {
        return r.cuisine.toLowerCase().contains(categoryLower);
      }).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((r) {
        return r.name.toLowerCase().contains(q) ||
            r.cuisine.toLowerCase().contains(q);
      }).toList();
    }

    return results;
  }

  @override
  Future<List<FoodItem>> searchFoodItems({
    String? query,
    String? categoryId,
  }) async {
    var results = MockRestaurantData.foodItems;

    if (categoryId != null && categoryId.isNotEmpty) {
      final categoryLower = categoryId.toLowerCase();
      results = results.where((item) {
        return item.category.toLowerCase() == categoryLower;
      }).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q);
      }).toList();
    }

    return results;
  }
}
