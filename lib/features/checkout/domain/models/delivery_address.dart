/// Represents a user delivery address for QuickBite orders.
class DeliveryAddress {
  final String id;
  final String label; // "Home", "Work", "Other"
  final String recipientName;
  final String streetAddress;
  final String landmark;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.streetAddress,
    required this.landmark,
    required this.city,
    required this.state,
    required this.postalCode,
    this.isDefault = false,
  });

  String get formattedAddress =>
      '$streetAddress, $landmark, $city, $state $postalCode';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'streetAddress': streetAddress,
      'landmark': landmark,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String? ?? 'addr_default',
      label: json['label'] as String? ?? 'Home',
      recipientName: json['recipientName'] as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Standard demo addresses for QuickBite
  static const List<DeliveryAddress> demoAddresses = [
    DeliveryAddress(
      id: 'addr_1',
      label: 'Home',
      recipientName: 'Farhan Ansari',
      streetAddress: 'Flat 402, Royal Residency',
      landmark: 'Near Cathedral School',
      city: 'Hazratganj, Lucknow',
      state: 'Uttar Pradesh',
      postalCode: '226001',
      isDefault: true,
    ),
    DeliveryAddress(
      id: 'addr_2',
      label: 'Work',
      recipientName: 'Farhan Ansari',
      streetAddress: 'Summit Building, 7th Floor, Tech Hub',
      landmark: 'Vibhuti Khand',
      city: 'Gomti Nagar, Lucknow',
      state: 'Uttar Pradesh',
      postalCode: '226010',
      isDefault: false,
    ),
  ];
}
