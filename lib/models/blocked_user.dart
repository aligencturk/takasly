import 'package:json_annotation/json_annotation.dart';

part 'blocked_user.g.dart';

@JsonSerializable()
class BlockedUser {
  final int userID;
  final String userFullname;
  final String? profilePhoto;

  BlockedUser({
    required this.userID,
    required this.userFullname,
    this.profilePhoto,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => _$BlockedUserFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedUserToJson(this);

  BlockedUser copyWith({
    int? userID,
    String? userFullname,
    String? profilePhoto,
  }) {
    return BlockedUser(
      userID: userID ?? this.userID,
      userFullname: userFullname ?? this.userFullname,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }

  @override
  String toString() {
    return 'BlockedUser(userID: $userID, userFullname: $userFullname, profilePhoto: $profilePhoto)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockedUser &&
        other.userID == userID &&
        other.userFullname == userFullname &&
        other.profilePhoto == profilePhoto;
  }

  @override
  int get hashCode {
    return userID.hashCode ^
        userFullname.hashCode ^
        profilePhoto.hashCode;
  }
}
