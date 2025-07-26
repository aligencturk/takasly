// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['name'] as String,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  avatar: json['avatar'] as String?,
  bio: json['bio'] as String?,
  location: json['location'] == null
      ? null
      : Location.fromJson(json['location'] as Map<String, dynamic>),
  rating: (json['rating'] as num).toDouble(),
  totalTrades: (json['totalTrades'] as num).toInt(),
  isVerified: json['isVerified'] as bool,
  isOnline: json['isOnline'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  lastSeenAt: json['lastSeenAt'] == null
      ? null
      : DateTime.parse(json['lastSeenAt'] as String),
  birthday: json['birthday'] as String?,
  gender: json['gender'] as String?,
  token: json['token'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phone': instance.phone,
  'avatar': instance.avatar,
  'bio': instance.bio,
  'location': instance.location,
  'rating': instance.rating,
  'totalTrades': instance.totalTrades,
  'isVerified': instance.isVerified,
  'isOnline': instance.isOnline,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'lastSeenAt': instance.lastSeenAt?.toIso8601String(),
  'birthday': instance.birthday,
  'gender': instance.gender,
  'token': instance.token,
};
