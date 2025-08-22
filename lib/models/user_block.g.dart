// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserBlock _$UserBlockFromJson(Map<String, dynamic> json) => UserBlock(
  blockedUserID: (json['blockedUserID'] as num).toInt(),
  reason: json['reason'] as String?,
  blockedAt: json['blockedAt'] == null
      ? null
      : DateTime.parse(json['blockedAt'] as String),
  message: json['message'] as String?,
);

Map<String, dynamic> _$UserBlockToJson(UserBlock instance) => <String, dynamic>{
  'blockedUserID': instance.blockedUserID,
  'reason': instance.reason,
  'blockedAt': instance.blockedAt?.toIso8601String(),
  'message': instance.message,
};
