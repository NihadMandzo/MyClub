import 'package:myclub_desktop/models/city.dart';

class ShippingDetails {
  final String address;
  final City city;

  ShippingDetails({
    required this.address,
    required this.city,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    return ShippingDetails(
      address: json['address'] as String,
      city: City.fromJson(json['city'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city.toJson(),
    };
  }
}
