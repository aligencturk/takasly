import 'package:json_annotation/json_annotation.dart';

part 'trade_detail.g.dart';

@JsonSerializable()
class TradeDetail {
  final int offerID;
  final int statusID;
  final String statusTitle;
  final String createdAt;
  final String completedAt;
  final int deliveryTypeID;
  final String deliveryTypeTitle;
  final String meetingLocation;
  final String cancelDesc;
  @JsonKey(fromJson: _boolFromDynamic)
  final bool isConfirm;
  final TradeParticipant sender;
  final TradeParticipant receiver;

  TradeDetail({
    required this.offerID,
    required this.statusID,
    required this.statusTitle,
    required this.createdAt,
    required this.completedAt,
    required this.deliveryTypeID,
    required this.deliveryTypeTitle,
    required this.meetingLocation,
    required this.cancelDesc,
    required this.isConfirm,
    required this.sender,
    required this.receiver,
  });

  factory TradeDetail.fromJson(Map<String, dynamic> json) => _$TradeDetailFromJson(json);
  Map<String, dynamic> toJson() => _$TradeDetailToJson(this);
  
  // Bool field'lar için helper metod
  static bool _boolFromDynamic(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

@JsonSerializable()
class TradeParticipant {
  final int userID;
  final String userName;
  final String profilePhoto;
  final TradeProduct product;

  TradeParticipant({
    required this.userID,
    required this.userName,
    required this.profilePhoto,
    required this.product,
  });

  factory TradeParticipant.fromJson(Map<String, dynamic> json) => _$TradeParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$TradeParticipantToJson(this);
}

@JsonSerializable()
class TradeProduct {
  final int productID;
  final String productCode;
  final String productTitle;
  final String productDesc;
  final String productImage;
  final String productCondition;
  final List<TradeCategory> categoryList;
  final int userID;
  final int categoryID;
  final int conditionID;
  final int cityID;
  final int districtID;
  final String cityTitle;
  final String districtTitle;
  final String productLat;
  final String productLong;
  final String userFullname;
  final String userFirstname;
  final String userLastname;
  final String createdAt;
  @JsonKey(fromJson: _boolFromDynamic)
  final bool isFavorite;
  @JsonKey(fromJson: _boolFromDynamic)
  final bool isSponsor;
  @JsonKey(fromJson: _boolFromDynamic)
  final bool isTrade;

  TradeProduct({
    required this.productID,
    required this.productCode,
    required this.productTitle,
    required this.productDesc,
    required this.productImage,
    required this.productCondition,
    required this.categoryList,
    required this.userID,
    required this.categoryID,
    required this.conditionID,
    required this.cityID,
    required this.districtID,
    required this.cityTitle,
    required this.districtTitle,
    required this.productLat,
    required this.productLong,
    required this.userFullname,
    required this.userFirstname,
    required this.userLastname,
    required this.createdAt,
    required this.isFavorite,
    required this.isSponsor,
    required this.isTrade,
  });

  factory TradeProduct.fromJson(Map<String, dynamic> json) => _$TradeProductFromJson(json);
  Map<String, dynamic> toJson() => _$TradeProductToJson(this);
  
  // Bool field'lar için helper metod
  static bool _boolFromDynamic(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

@JsonSerializable()
class TradeCategory {
  final int catID;
  final String catName;

  TradeCategory({
    required this.catID,
    required this.catName,
  });

  factory TradeCategory.fromJson(Map<String, dynamic> json) => _$TradeCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$TradeCategoryToJson(this);
} 