/// Represents a food restaurant partner in the QuickBite platform.
/// Immutable model with helper methods and clean defaults.
class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisine;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final double deliveryFee;
  final String distance;
  final String description;
  final bool isFeatured;
  final bool isOpen;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.distance,
    this.description = '',
    this.isFeatured = false,
    this.isOpen = true,
  });

  /// Human-readable formatted delivery fee text in INR.
  String get deliveryFeeFormatted {
    if (deliveryFee == 0) return 'Free';
    return '₹${deliveryFee.toInt()}';
  }

  /// Formatted reviews label (e.g., "500+").
  String get reviewCountFormatted {
    if (reviewCount >= 1000) {
      return '${(reviewCount / 1000).toStringAsFixed(1)}k+';
    }
    return '$reviewCount+';
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? cuisine,
    double? rating,
    int? reviewCount,
    String? deliveryTime,
    double? deliveryFee,
    String? distance,
    String? description,
    bool? isFeatured,
    bool? isOpen,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      cuisine: cuisine ?? this.cuisine,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      distance: distance ?? this.distance,
      description: description ?? this.description,
      isFeatured: isFeatured ?? this.isFeatured,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      cuisine: json['cuisine'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      deliveryTime: json['deliveryTime'] as String,
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      distance: json['distance'] as String,
      description: json['description'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'cuisine': cuisine,
      'rating': rating,
      'reviewCount': reviewCount,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'distance': distance,
      'description': description,
      'isFeatured': isFeatured,
      'isOpen': isOpen,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Restaurant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
