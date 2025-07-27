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
  final bool isVerified;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final String? birthday;
  final String? gender; // Erkek, Kadın, Belirtilmemiş
  final String? token; // Kullanıcı token'ı

  const User({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.avatar,
    required this.isVerified,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    this.birthday,
    this.gender,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    // Güvenli string dönüşümü
    String safeString(dynamic value) {
      if (value is String) return value;
      if (value != null) return value.toString();
      return '';
    }

    // Güvenli bool dönüşümü
    bool safeBool(dynamic value, {bool defaultValue = false}) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value != 0;
      return defaultValue;
    }

    return User(
      id: safeString(json['id']),
      name: safeString(json['name']),
      firstName: json['firstName'] != null ? safeString(json['firstName']) : null,
      lastName: json['lastName'] != null ? safeString(json['lastName']) : null,
      email: safeString(json['email']),
      phone: json['phone'] != null ? safeString(json['phone']) : null,
      avatar: json['avatar'] != null ? safeString(json['avatar']) : null,
      isVerified: safeBool(json['isVerified']),
      isOnline: safeBool(json['isOnline']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      lastSeenAt: json['lastSeenAt'] != null ? parseDateTime(json['lastSeenAt']) : null,
      birthday: json['birthday'] != null ? safeString(json['birthday']) : null,
      gender: json['gender'] != null ? safeString(json['gender']) : null,
      token: json['token'] != null ? safeString(json['token']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    final json = _$UserToJson(this);
    // DateTime'ları string'e çevir
    json['createdAt'] = createdAt.toIso8601String();
    json['updatedAt'] = updatedAt.toIso8601String();
    if (lastSeenAt != null) {
      json['lastSeenAt'] = lastSeenAt!.toIso8601String();
    }
    return json;
  }

  User copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
    bool? isVerified,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    String? birthday,
    String? gender,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      token: token ?? this.token,
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
    return 'User(id: $id, name: $name, firstName: $firstName, lastName: $lastName, email: $email)';
  }
}