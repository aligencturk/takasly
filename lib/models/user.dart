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

    // isVerified için farklı field isimlerini kontrol et
    bool getIsVerified(Map<String, dynamic> json) {
      // API'den gelebilecek farklı field isimleri
      if (json.containsKey('isVerified')) return safeBool(json['isVerified']);
      if (json.containsKey('userVerified')) return safeBool(json['userVerified']);
      if (json.containsKey('isApproved')) return safeBool(json['isApproved']);
      if (json.containsKey('verified')) return safeBool(json['verified']);
      return false; // Varsayılan olarak doğrulanmamış
    }

    // isOnline için farklı field isimlerini kontrol et
    bool getIsOnline(Map<String, dynamic> json) {
      if (json.containsKey('isOnline')) return safeBool(json['isOnline']);
      if (json.containsKey('userOnline')) return safeBool(json['userOnline']);
      if (json.containsKey('userStatus')) {
        final status = json['userStatus'];
        if (status is String) return status.toLowerCase() == 'active';
        return safeBool(status);
      }
      return true; // Varsayılan olarak online kabul et
    }

    // ID için farklı field isimlerini kontrol et
    String getId(Map<String, dynamic> json) {
      if (json.containsKey('id')) return safeString(json['id']);
      if (json.containsKey('userID')) return safeString(json['userID']);
      return '';
    }

    // Name için farklı field isimlerini kontrol et
    String getName(Map<String, dynamic> json) {
      if (json.containsKey('name')) return safeString(json['name']);
      if (json.containsKey('userName')) return safeString(json['userName']);
      if (json.containsKey('userFullname')) return safeString(json['userFullname']);
      if (json.containsKey('username')) return safeString(json['username']);
      
      // firstName ve lastName'den name oluştur
      final firstName = json['firstName'] ?? json['userFirstname'];
      final lastName = json['lastName'] ?? json['userLastname'];
      if (firstName != null && lastName != null) {
        return '${safeString(firstName)} ${safeString(lastName)}';
      } else if (firstName != null) {
        return safeString(firstName);
      } else if (lastName != null) {
        return safeString(lastName);
      }
      
      return 'Kullanıcı';
    }

    // Email için farklı field isimlerini kontrol et
    String getEmail(Map<String, dynamic> json) {
      if (json.containsKey('email')) return safeString(json['email']);
      if (json.containsKey('userEmail')) return safeString(json['userEmail']);
      return '';
    }

    // Phone için farklı field isimlerini kontrol et
    String? getPhone(Map<String, dynamic> json) {
      if (json.containsKey('phone')) return safeString(json['phone']);
      if (json.containsKey('userPhone')) return safeString(json['userPhone']);
      return null;
    }

    // Avatar için farklı field isimlerini kontrol et
    String? getAvatar(Map<String, dynamic> json) {
      if (json.containsKey('avatar')) return safeString(json['avatar']);
      if (json.containsKey('userAvatar')) return safeString(json['userAvatar']);
      if (json.containsKey('profilePhoto')) return safeString(json['profilePhoto']);
      return null;
    }

    return User(
      id: getId(json),
      name: getName(json),
      firstName: json['firstName'] != null ? safeString(json['firstName']) : 
                 json['userFirstname'] != null ? safeString(json['userFirstname']) : null,
      lastName: json['lastName'] != null ? safeString(json['lastName']) : 
                json['userLastname'] != null ? safeString(json['userLastname']) : null,
      email: getEmail(json),
      phone: getPhone(json),
      avatar: getAvatar(json),
      isVerified: getIsVerified(json),
      isOnline: getIsOnline(json),
      createdAt: parseDateTime(json['createdAt'] ?? json['userCreatedAt']),
      updatedAt: parseDateTime(json['updatedAt'] ?? json['userUpdatedAt']),
      lastSeenAt: json['lastSeenAt'] != null ? parseDateTime(json['lastSeenAt']) : 
                  json['userLastSeenAt'] != null ? parseDateTime(json['userLastSeenAt']) : null,
      birthday: json['birthday'] != null ? safeString(json['birthday']) : 
                json['userBirthday'] != null ? safeString(json['userBirthday']) : null,
      gender: json['gender'] != null ? safeString(json['gender']) : 
              json['userGender'] != null ? safeString(json['userGender']) : null,
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