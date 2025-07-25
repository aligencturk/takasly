import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location {
  final String? cityId;
  final String? districtId;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? district;
  final String? country;

  const Location({
    this.cityId,
    this.districtId,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.district,
    this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  Location copyWith({
    String? cityId,
    String? districtId,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? district,
    String? country,
  }) {
    return Location(
      cityId: cityId ?? this.cityId,
      districtId: districtId ?? this.districtId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() {
    return 'Location(city: $city, district: $district, address: $address)';
  }
}