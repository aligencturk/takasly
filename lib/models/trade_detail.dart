class TradeDetail {
  final int? offerID;
  final int? senderUserID;
  final int? receiverUserID;
  final int? senderStatusID;
  final int? receiverStatusID;
  final String senderStatusTitle;
  final String receiverStatusTitle;
  final int? deliveryTypeID;
  final String deliveryTypeTitle;
  final String meetingLocation;
  final String senderCancelDesc;
  final String receiverCancelDesc;
  final String createdAt;
  final String completedAt;
  final bool isConfirm;
  final TradeParticipant sender;
  final TradeParticipant receiver;

  TradeDetail({
    this.offerID,
    this.senderUserID,
    this.receiverUserID,
    this.senderStatusID,
    this.receiverStatusID,
    required this.senderStatusTitle,
    required this.receiverStatusTitle,
    this.deliveryTypeID,
    required this.deliveryTypeTitle,
    required this.meetingLocation,
    required this.senderCancelDesc,
    required this.receiverCancelDesc,
    required this.createdAt,
    required this.completedAt,
    required this.isConfirm,
    required this.sender,
    required this.receiver,
  });

  factory TradeDetail.fromJson(Map<String, dynamic> json) {
    return TradeDetail(
      offerID: json['offerID'] as int?,
      senderUserID: json['senderUserID'] as int?,
      receiverUserID: json['receiverUserID'] as int?,
      senderStatusID: json['senderStatusID'] as int?,
      receiverStatusID: json['receiverStatusID'] as int?,
      senderStatusTitle: json['senderStatusTitle'] as String? ?? '',
      receiverStatusTitle: json['receiverStatusTitle'] as String? ?? '',
      deliveryTypeID: json['deliveryTypeID'] as int?,
      deliveryTypeTitle: json['deliveryTypeTitle'] as String? ?? '',
      meetingLocation: json['meetingLocation'] as String? ?? '',
      senderCancelDesc: json['senderCancelDesc'] as String? ?? '',
      receiverCancelDesc: json['receiverCancelDesc'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      completedAt: json['completedAt'] as String? ?? '',
      isConfirm: json['isConfirm'] == true,
      sender: TradeParticipant.fromJson(json['sender'] as Map<String, dynamic>),
      receiver: TradeParticipant.fromJson(json['receiver'] as Map<String, dynamic>),
    );
  }
}

class TradeParticipant {
  final int? userID;
  final String userName;
  final String profilePhoto;
  final TradeProduct product;

  TradeParticipant({
    this.userID,
    required this.userName,
    required this.profilePhoto,
    required this.product,
  });

  factory TradeParticipant.fromJson(Map<String, dynamic> json) {
    return TradeParticipant(
      userID: json['userID'] as int?,
      userName: json['userName'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      product: TradeProduct.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}

class TradeProduct {
  final int? productID;
  final String productCode;
  final String productTitle;
  final String productDesc;
  final String productImage;
  final String productCondition;
  final List<TradeCategory> categoryList;
  final int? userID;
  final int? categoryID;
  final int? conditionID;
  final int? cityID;
  final int? districtID;
  final String cityTitle;
  final String districtTitle;
  final String productLat;
  final String productLong;
  final String userFullname;
  final String userFirstname;
  final String userLastname;
  final String createdAt;
  final bool isFavorite;
  final bool isSponsor;
  final bool isTrade;

  TradeProduct({
    this.productID,
    required this.productCode,
    required this.productTitle,
    required this.productDesc,
    required this.productImage,
    required this.productCondition,
    required this.categoryList,
    this.userID,
    this.categoryID,
    this.conditionID,
    this.cityID,
    this.districtID,
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

  factory TradeProduct.fromJson(Map<String, dynamic> json) {
    return TradeProduct(
      productID: json['productID'] as int?,
      productCode: json['productCode'] as String? ?? '',
      productTitle: json['productTitle'] as String? ?? '',
      productDesc: json['productDesc'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      productCondition: json['productCondition'] as String? ?? '',
      categoryList: (json['categoryList'] as List<dynamic>? ?? [])
          .map((e) => TradeCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      userID: json['userID'] as int?,
      categoryID: json['categoryID'] as int?,
      conditionID: json['conditionID'] as int?,
      cityID: json['cityID'] as int?,
      districtID: json['districtID'] as int?,
      cityTitle: json['cityTitle'] as String? ?? '',
      districtTitle: json['districtTitle'] as String? ?? '',
      productLat: json['productLat'] as String? ?? '',
      productLong: json['productLong'] as String? ?? '',
      userFullname: json['userFullname'] as String? ?? '',
      userFirstname: json['userFirstname'] as String? ?? '',
      userLastname: json['userLastname'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      isFavorite: _boolFromDynamic(json['isFavorite']),
      isSponsor: _boolFromDynamic(json['isSponsor']),
      isTrade: _boolFromDynamic(json['isTrade']),
    );
  }

  static bool _boolFromDynamic(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

class TradeCategory {
  final int? catID;
  final String catName;

  TradeCategory({
    this.catID,
    required this.catName,
  });

  factory TradeCategory.fromJson(Map<String, dynamic> json) {
    return TradeCategory(
      catID: json['catID'] as int?,
      catName: json['catName'] as String? ?? '',
    );
  }
} 