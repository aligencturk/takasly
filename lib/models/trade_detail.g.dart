// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeDetail _$TradeDetailFromJson(Map<String, dynamic> json) => TradeDetail(
  offerID: (json['offerID'] as num).toInt(),
  statusID: (json['statusID'] as num).toInt(),
  statusTitle: json['statusTitle'] as String,
  createdAt: json['createdAt'] as String,
  completedAt: json['completedAt'] as String,
  deliveryTypeID: (json['deliveryTypeID'] as num).toInt(),
  deliveryTypeTitle: json['deliveryTypeTitle'] as String,
  meetingLocation: json['meetingLocation'] as String,
  cancelDesc: json['cancelDesc'] as String,
  isConfirm: TradeDetail._boolFromDynamic(json['isConfirm']),
  sender: TradeParticipant.fromJson(json['sender'] as Map<String, dynamic>),
  receiver: TradeParticipant.fromJson(json['receiver'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TradeDetailToJson(TradeDetail instance) =>
    <String, dynamic>{
      'offerID': instance.offerID,
      'statusID': instance.statusID,
      'statusTitle': instance.statusTitle,
      'createdAt': instance.createdAt,
      'completedAt': instance.completedAt,
      'deliveryTypeID': instance.deliveryTypeID,
      'deliveryTypeTitle': instance.deliveryTypeTitle,
      'meetingLocation': instance.meetingLocation,
      'cancelDesc': instance.cancelDesc,
      'isConfirm': instance.isConfirm,
      'sender': instance.sender,
      'receiver': instance.receiver,
    };

TradeParticipant _$TradeParticipantFromJson(Map<String, dynamic> json) =>
    TradeParticipant(
      userID: (json['userID'] as num).toInt(),
      userName: json['userName'] as String,
      profilePhoto: json['profilePhoto'] as String,
      product: TradeProduct.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TradeParticipantToJson(TradeParticipant instance) =>
    <String, dynamic>{
      'userID': instance.userID,
      'userName': instance.userName,
      'profilePhoto': instance.profilePhoto,
      'product': instance.product,
    };

TradeProduct _$TradeProductFromJson(Map<String, dynamic> json) => TradeProduct(
  productID: (json['productID'] as num).toInt(),
  productCode: json['productCode'] as String,
  productTitle: json['productTitle'] as String,
  productDesc: json['productDesc'] as String,
  productImage: json['productImage'] as String,
  productCondition: json['productCondition'] as String,
  categoryList: (json['categoryList'] as List<dynamic>)
      .map((e) => TradeCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  userID: (json['userID'] as num).toInt(),
  categoryID: (json['categoryID'] as num).toInt(),
  conditionID: (json['conditionID'] as num).toInt(),
  cityID: (json['cityID'] as num).toInt(),
  districtID: (json['districtID'] as num).toInt(),
  cityTitle: json['cityTitle'] as String,
  districtTitle: json['districtTitle'] as String,
  productLat: json['productLat'] as String,
  productLong: json['productLong'] as String,
  userFullname: json['userFullname'] as String,
  userFirstname: json['userFirstname'] as String,
  userLastname: json['userLastname'] as String,
  createdAt: json['createdAt'] as String,
  isFavorite: TradeProduct._boolFromDynamic(json['isFavorite']),
  isSponsor: TradeProduct._boolFromDynamic(json['isSponsor']),
  isTrade: TradeProduct._boolFromDynamic(json['isTrade']),
);

Map<String, dynamic> _$TradeProductToJson(TradeProduct instance) =>
    <String, dynamic>{
      'productID': instance.productID,
      'productCode': instance.productCode,
      'productTitle': instance.productTitle,
      'productDesc': instance.productDesc,
      'productImage': instance.productImage,
      'productCondition': instance.productCondition,
      'categoryList': instance.categoryList,
      'userID': instance.userID,
      'categoryID': instance.categoryID,
      'conditionID': instance.conditionID,
      'cityID': instance.cityID,
      'districtID': instance.districtID,
      'cityTitle': instance.cityTitle,
      'districtTitle': instance.districtTitle,
      'productLat': instance.productLat,
      'productLong': instance.productLong,
      'userFullname': instance.userFullname,
      'userFirstname': instance.userFirstname,
      'userLastname': instance.userLastname,
      'createdAt': instance.createdAt,
      'isFavorite': instance.isFavorite,
      'isSponsor': instance.isSponsor,
      'isTrade': instance.isTrade,
    };

TradeCategory _$TradeCategoryFromJson(Map<String, dynamic> json) =>
    TradeCategory(
      catID: (json['catID'] as num).toInt(),
      catName: json['catName'] as String,
    );

Map<String, dynamic> _$TradeCategoryToJson(TradeCategory instance) =>
    <String, dynamic>{'catID': instance.catID, 'catName': instance.catName};
