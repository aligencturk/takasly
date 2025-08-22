// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedUser _$BlockedUserFromJson(Map<String, dynamic> json) => BlockedUser(
  userID: (json['userID'] as num).toInt(),
  userFullname: json['userFullname'] as String,
  profilePhoto: json['profilePhoto'] as String?,
);

Map<String, dynamic> _$BlockedUserToJson(BlockedUser instance) =>
    <String, dynamic>{
      'userID': instance.userID,
      'userFullname': instance.userFullname,
      'profilePhoto': instance.profilePhoto,
    };
