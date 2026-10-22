import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/features/restaurants/data/mock_restaurant_data.dart';

void main() {
  group('Food Image Audit & Integrity Tests', () {
    test('Every FoodItem has a valid, secure HTTPS imageUrl', () {
      expect(MockRestaurantData.foodItems, isNotEmpty);
      for (final food in MockRestaurantData.foodItems) {
        expect(
          food.imageUrl,
          isNotEmpty,
          reason: '${food.name} (${food.id}) has an empty imageUrl',
        );
        expect(
          food.imageUrl.startsWith('https://'),
          isTrue,
          reason: '${food.name} (${food.id}) image is not HTTPS',
        );
        final uri = Uri.tryParse(food.imageUrl);
        expect(
          uri,
          isNotNull,
          reason: '${food.name} (${food.id}) has an unparseable imageUrl',
        );
        expect(uri!.hasAuthority, isTrue);
      }
    });

    test('Peri-Peri Crinkle Cut Fries (food_2_3) uses verified working Unsplash image', () {
      final fries = MockRestaurantData.foodItems.firstWhere(
        (f) => f.id == 'food_2_3',
      );
      expect(fries.name, 'Peri-Peri Crinkle Cut Fries');
      // Must not be the broken 404 URL (photo-1576107232684-1279f3908594)
      expect(
        fries.imageUrl.contains('photo-1576107232684-1279f3908594'),
        isFalse,
      );
      // Must be the verified working image
      expect(
        fries.imageUrl,
        'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=500&q=80',
      );
    });

    test(
      'Identified invalid images are replaced with verified food images',
      () {
        // 1. Cheesy Garlic Breadsticks must not be a portrait photo (photo-1573140247632-f8fd74997d5c)
        final bread = MockRestaurantData.foodItems.firstWhere(
          (f) => f.id == 'food_1_4',
        );
        expect(
          bread.imageUrl.contains('photo-1573140247632-f8fd74997d5c'),
          isFalse,
        );
        expect(
          bread.imageUrl,
          'https://images.unsplash.com/photo-1619535860434-ba1d8fa12536?auto=format&fit=crop&w=500&q=80',
        );

        // 2. San Pellegrino Sparkling Lemon must not be a Coca-Cola can (photo-1622483767028-3f66f32aef97)
        final drink = MockRestaurantData.foodItems.firstWhere(
          (f) => f.id == 'food_1_6',
        );
        expect(
          drink.imageUrl.contains('photo-1622483767028-3f66f32aef97'),
          isFalse,
        );
        expect(
          drink.imageUrl,
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=500&q=80',
        );

        // 3. Royal Galouti Kebab must not be an aquarium with fish (photo-1599488615731-7e5c2823ff28)
        final kebab = MockRestaurantData.foodItems.firstWhere(
          (f) => f.id == 'food_5_3',
        );
        expect(
          kebab.imageUrl.contains('photo-1599488615731-7e5c2823ff28'),
          isFalse,
        );
        expect(
          kebab.imageUrl,
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=500&q=80',
        );

        // 4. Kesariya Shahi Tukda must not be a sleeping cat (photo-1541781774459-bb2af2f05b55)
        final shahiTukda = MockRestaurantData.foodItems.firstWhere(
          (f) => f.id == 'food_5_5',
        );
        expect(
          shahiTukda.imageUrl.contains('photo-1541781774459-bb2af2f05b55'),
          isFalse,
        );
        expect(
          shahiTukda.imageUrl,
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=500&q=80',
        );
      },
    );

    test('All 20 food items are present and have authentic food metadata', () {
      expect(MockRestaurantData.foodItems.length, 20);
      final uniqueIds = MockRestaurantData.foodItems.map((f) => f.id).toSet();
      expect(uniqueIds.length, 20, reason: 'Food item IDs must be unique');
    });

    test('All 10 restaurants have valid secure HTTPS imageUrls', () {
      expect(MockRestaurantData.restaurants.length, 10);
      for (final rest in MockRestaurantData.restaurants) {
        expect(rest.imageUrl, isNotEmpty);
        expect(rest.imageUrl.startsWith('https://'), isTrue);
      }
    });
  });
}
