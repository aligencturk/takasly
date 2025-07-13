import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? avatar;
  final String? bio;
  final Location? location;
  final double rating;
  final int totalTrades;
  final bool isVerified;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final String? birthday;
  final int? gender; // 1-Erkek, 2-Kadın, 3-Belirtilmemiş

  const User({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.avatar,
    this.bio,
    this.location,
    required this.rating,
    required this.totalTrades,
    required this.isVerified,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    this.birthday,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
    String? bio,
    Location? location,
    double? rating,
    int? totalTrades,
    bool? isVerified,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    String? birthday,
    int? gender,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      totalTrades: totalTrades ?? this.totalTrades,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, firstName: $firstName, lastName: $lastName, email: $email, rating: $rating)';
  }
}

@JsonSerializable()
class Location {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String district;
  final String country;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.district,
    required this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  Location copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? district,
    String? country,
  }) {
    return Location(
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