import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite/features/restaurants/data/restaurant_repository.dart';
import 'package:quickbite/features/restaurants/domain/models/food_item.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';
import 'package:quickbite/features/home/domain/models/category.dart';

/// Repository provider allowing painless DI and testing overrides.
final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return const MockRestaurantRepository();
});

/// State notifier managing the search query in Riverpod 3.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// State notifier managing the selected craving category filter.
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? categoryId) => state = categoryId;

  void toggleCategory(String categoryId) {
    state = state == categoryId ? null : categoryId;
  }

  void clear() => state = null;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(
      SelectedCategoryNotifier.new,
    );

/// Provides the list of available craving categories.
final categoriesProvider = Provider<List<Category>>((ref) {
  return DefaultCategories.all;
});

/// Provides popular restaurants filtered by active search query & selected category.
final popularRestaurantsProvider = FutureProvider<List<Restaurant>>((
  ref,
) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (query.trim().isEmpty && category == null) {
    return repository.getPopularRestaurants();
  }

  return repository.searchRestaurants(query: query, categoryId: category);
});

/// Provides recommended food items filtered by active search query & selected category.
final recommendedFoodProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (query.trim().isEmpty && category == null) {
    return repository.getRecommendedFoodItems();
  }

  return repository.searchFoodItems(query: query, categoryId: category);
});
