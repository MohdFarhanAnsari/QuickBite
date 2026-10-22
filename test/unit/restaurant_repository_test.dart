import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';
import 'package:quickbite/features/restaurants/data/restaurant_repository.dart';

void main() {
  late RestaurantRepository repository;

  setUp(() {
    repository = const MockRestaurantRepository();
  });

  group('MockRestaurantRepository Unit Tests', () {
    test('Loads deterministic mock restaurants correctly', () async {
      final restaurants = await repository.getRestaurants();
      expect(restaurants, isNotEmpty);
      expect(restaurants.length, 10);
      expect(restaurants.any((r) => r.name.contains('Pizza')), isTrue);
      expect(restaurants.any((r) => r.name.contains('Burger')), isTrue);
    });

    test(
      'Loads popular restaurants with rating >= 4.7 or isFeatured',
      () async {
        final popular = await repository.getPopularRestaurants();
        expect(popular, isNotEmpty);
        for (final r in popular) {
          expect(r.isFeatured || r.rating >= 4.7, isTrue);
        }
      },
    );

    test('Loads recommended food items correctly', () async {
      final dishes = await repository.getRecommendedFoodItems();
      expect(dishes, isNotEmpty);
      expect(dishes.length, MockRestaurantData.foodItems.length);
      expect(dishes.any((d) => d.isVeg), isTrue);
      expect(dishes.any((d) => !d.isVeg), isTrue);
    });

    test('Fetches restaurant by ID correctly', () async {
      final restaurant = await repository.getRestaurantById('rest_1');
      expect(restaurant, isNotNull);
      expect(restaurant!.name, 'Artisan Woodfire Pizza');

      final notFound = await repository.getRestaurantById('non_existent');
      expect(notFound, isNull);
    });

    test('Fetches restaurant menu and filters by category', () async {
      final allMenu = await repository.getRestaurantMenu('rest_1');
      expect(allMenu, isNotEmpty);
      expect(allMenu.length, greaterThanOrEqualTo(4));

      final pizzaOnly = await repository.getRestaurantMenu(
        'rest_1',
        category: 'Pizza',
      );
      expect(pizzaOnly, isNotEmpty);
      expect(
        pizzaOnly.every((item) => item.category.toLowerCase() == 'pizza'),
        isTrue,
      );
    });

    test('Fetches food item by ID correctly', () async {
      final food = await repository.getFoodItemById('food_1');
      expect(food, isNotNull);
      expect(food!.name, 'Truffle Mushroom Pizza');
      expect(food.customizationGroups, isNotEmpty);

      final notFound = await repository.getFoodItemById('non_existent');
      expect(notFound, isNull);
    });

    test('Searches restaurants by query keyword correctly', () async {
      final ramenResults = await repository.searchRestaurants(query: 'ramen');
      expect(ramenResults, isNotEmpty);
      expect(ramenResults.first.name, contains('Tokyo Ramen'));

      final nonExistent = await repository.searchRestaurants(
        query: 'xyz123notfound',
      );
      expect(nonExistent, isEmpty);
    });

    test('Filters restaurants by category correctly', () async {
      final indianResults = await repository.searchRestaurants(
        categoryId: 'Indian',
      );
      expect(indianResults, isNotEmpty);
      expect(
        indianResults.every((r) => r.cuisine.toLowerCase().contains('indian')),
        isTrue,
      );
    });

    test('Searches food items by query and category', () async {
      final pizzaItems = await repository.searchFoodItems(categoryId: 'pizza');
      expect(pizzaItems, isNotEmpty);
      expect(pizzaItems.first.category.toLowerCase(), 'pizza');

      final biryaniSearch = await repository.searchFoodItems(query: 'Biryani');
      expect(biryaniSearch, isNotEmpty);
      expect(biryaniSearch.first.name, contains('Biryani'));
    });
  });
}
