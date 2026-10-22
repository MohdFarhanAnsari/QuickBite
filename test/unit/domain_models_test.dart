import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite/features/home/domain/models/category.dart';
import 'package:quickbite/features/restaurants/domain/models/food_customization.dart';
import 'package:quickbite/features/restaurants/domain/models/food_item.dart';
import 'package:quickbite/features/restaurants/domain/models/restaurant.dart';

void main() {
  group('Restaurant Model Unit Tests', () {
    test('Calculates delivery fee formatting correctly in INR', () {
      const freeDeliveryRest = Restaurant(
        id: '1',
        name: 'Test',
        imageUrl: '',
        cuisine: 'Pizza',
        rating: 4.8,
        reviewCount: 500,
        deliveryTime: '20 min',
        deliveryFee: 0.0,
        distance: '1.2 km',
      );

      const paidDeliveryRest = Restaurant(
        id: '2',
        name: 'Test 2',
        imageUrl: '',
        cuisine: 'Burgers',
        rating: 4.5,
        reviewCount: 1500,
        deliveryTime: '30 min',
        deliveryFee: 40.0,
        distance: '3.0 km',
      );

      expect(freeDeliveryRest.deliveryFeeFormatted, 'Free');
      expect(paidDeliveryRest.deliveryFeeFormatted, '₹40');
      expect(freeDeliveryRest.reviewCountFormatted, '500+');
      expect(paidDeliveryRest.reviewCountFormatted, '1.5k+');
    });

    test('Serializes to and from JSON faithfully', () {
      const original = Restaurant(
        id: 'rest_99',
        name: 'Gourmet Bistro',
        imageUrl: 'https://example.com/bistro.jpg',
        cuisine: 'French',
        rating: 4.9,
        reviewCount: 250,
        deliveryTime: '25-35 min',
        deliveryFee: 30.0,
        distance: '1.8 km',
        description: 'Authentic dining experience.',
        isFeatured: true,
        isOpen: true,
      );

      final json = original.toJson();
      final restored = Restaurant.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.deliveryFee, original.deliveryFee);
      expect(restored.rating, original.rating);
      expect(restored.description, original.description);
      expect(restored.isOpen, original.isOpen);
      expect(restored, equals(original));
    });
  });

  group('FoodItem Model Unit Tests', () {
    test('Formats price in INR and preserves properties accurately', () {
      const food = FoodItem(
        id: 'food_1',
        restaurantId: 'rest_1',
        name: 'Margherita Pizza',
        imageUrl: '',
        description: 'Fresh basil and mozzarella',
        price: 279.0,
        rating: 4.8,
        isVeg: true,
        isPopular: true,
        category: 'Pizza',
      );

      expect(food.priceFormatted, '₹279');
      expect(food.isVeg, isTrue);
      expect(food.isPopular, isTrue);

      final json = food.toJson();
      final restored = FoodItem.fromJson(json);
      expect(restored, equals(food));
    });

    test(
      'Customization and CartItemConfig calculate totals dynamically in INR',
      () {
        const food = FoodItem(
          id: 'food_1',
          restaurantId: 'rest_1',
          name: 'Truffle Mushroom Pizza',
          imageUrl: '',
          description: 'Tasty',
          price: 349.0,
          rating: 4.9,
          isVeg: true,
          category: 'Pizza',
        );

        const largeSize = FoodCustomizationOption(
          id: 'large',
          name: 'Large',
          priceModifier: 150.0,
        );

        const extraCheese = FoodCustomizationOption(
          id: 'cheese',
          name: 'Extra Cheese',
          priceModifier: 50.0,
        );

        final config = CartItemConfig(
          foodItem: food,
          quantity: 2,
          selectedOptions: {
            'size': [largeSize],
            'addons': [extraCheese],
          },
        );

        // Unit price: 349 + 150 + 50 = 549
        expect(config.unitPrice, 549.0);
        expect(config.unitPriceFormatted, '₹549');

        // Total price: 549 * 2 = 1098
        expect(config.totalPrice, 1098.0);
        expect(config.totalPriceFormatted, '₹1098');
      },
    );
  });

  group('Category Model Unit Tests', () {
    test('DefaultCategories contains 8 expected categories', () {
      expect(DefaultCategories.all.length, 8);
      final names = DefaultCategories.all.map((c) => c.name).toList();
      expect(
        names,
        containsAll([
          'Pizza',
          'Burgers',
          'Chicken',
          'Asian',
          'Indian',
          'Healthy',
          'Desserts',
          'Coffee',
        ]),
      );
    });
  });
}
