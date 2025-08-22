import 'package:json_annotation/json_annotation.dart';

part 'user_block.g.dart';

@JsonSerializable()
class UserBlock {
  final int blockedUserID;
  final String? reason;
  final DateTime? blockedAt;
  final String? message;

  UserBlock({
    required this.blockedUserID,
    this.reason,
    this.blockedAt,
    this.message,
  });

  factory UserBlock.fromJson(Map<String, dynamic> json) => _$UserBlockFromJson(json);

  Map<String, dynamic> toJson() => _$UserBlockToJson(this);

  UserBlock copyWith({
    int? blockedUserID,
    String? reason,
    DateTime? blockedAt,
    String? message,
  }) {
    return UserBlock(
      blockedUserID: blockedUserID ?? this.blockedUserID,
      reason: reason ?? this.reason,
      blockedAt: blockedAt ?? this.blockedAt,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'UserBlock(blockedUserID: $blockedUserID, reason: $reason, blockedAt: $blockedAt, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserBlock &&
        other.blockedUserID == blockedUserID &&
        other.reason == reason &&
        other.blockedAt == blockedAt &&
        other.message == message;
  }

  @override
  int get hashCode {
    return blockedUserID.hashCode ^
        reason.hashCode ^
        blockedAt.hashCode ^
        message.hashCode;
  }
}
