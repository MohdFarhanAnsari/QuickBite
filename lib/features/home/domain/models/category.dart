/// Represents a food category/craving displayed on the Home screen.
class Category {
  final String id;
  final String name;
  final String emoji;

  const Category({required this.id, required this.name, required this.emoji});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Static list of popular craving categories for Day 1.
abstract class DefaultCategories {
  static const List<Category> all = [
    Category(id: 'pizza', name: 'Pizza', emoji: '🍕'),
    Category(id: 'burgers', name: 'Burgers', emoji: '🍔'),
    Category(id: 'chicken', name: 'Chicken', emoji: '🍗'),
    Category(id: 'asian', name: 'Asian', emoji: '🍜'),
    Category(id: 'indian', name: 'Indian', emoji: '🍛'),
    Category(id: 'healthy', name: 'Healthy', emoji: '🥗'),
    Category(id: 'desserts', name: 'Desserts', emoji: '🍰'),
    Category(id: 'coffee', name: 'Coffee', emoji: '☕'),
  ];
}
