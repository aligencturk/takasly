// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trade _$TradeFromJson(Map<String, dynamic> json) => Trade(
  id: json['id'] as String,
  offererUserId: json['offererUserId'] as String,
  offererUser: User.fromJson(json['offererUser'] as Map<String, dynamic>),
  receiverUserId: json['receiverUserId'] as String,
  receiverUser: User.fromJson(json['receiverUser'] as Map<String, dynamic>),
  offeredProductIds: (json['offeredProductIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  offeredProducts: (json['offeredProducts'] as List<dynamic>)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList(),
  requestedProductIds: (json['requestedProductIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  requestedProducts: (json['requestedProducts'] as List<dynamic>)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: $enumDecode(_$TradeStatusEnumMap, json['status']),
  message: json['message'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  cancellationReason: json['cancellationReason'] as String?,
);

Map<String, dynamic> _$TradeToJson(Trade instance) => <String, dynamic>{
  'id': instance.id,
  'offererUserId': instance.offererUserId,
  'offererUser': instance.offererUser,
  'receiverUserId': instance.receiverUserId,
  'receiverUser': instance.receiverUser,
  'offeredProductIds': instance.offeredProductIds,
  'offeredProducts': instance.offeredProducts,
  'requestedProductIds': instance.requestedProductIds,
  'requestedProducts': instance.requestedProducts,
  'status': _$TradeStatusEnumMap[instance.status]!,
  'message': instance.message,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'cancellationReason': instance.cancellationReason,
};

const _$TradeStatusEnumMap = {
  TradeStatus.pending: 'pending',
  TradeStatus.accepted: 'accepted',
  TradeStatus.rejected: 'rejected',
  TradeStatus.completed: 'completed',
  TradeStatus.cancelled: 'cancelled',
  TradeStatus.expired: 'expired',
};

TradeOffer _$TradeOfferFromJson(Map<String, dynamic> json) => TradeOffer(
  id: json['id'] as String,
  tradeId: json['tradeId'] as String,
  userId: json['userId'] as String,
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  productId: json['productId'] as String,
  product: Product.fromJson(json['product'] as Map<String, dynamic>),
  message: json['message'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$TradeOfferToJson(TradeOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tradeId': instance.tradeId,
      'userId': instance.userId,
      'user': instance.user,
      'productId': instance.productId,
      'product': instance.product,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
    };

StartTradeRequest _$StartTradeRequestFromJson(Map<String, dynamic> json) =>
    StartTradeRequest(
      userToken: json['userToken'] as String,
      senderProductID: (json['senderProductID'] as num).toInt(),
      receiverProductID: (json['receiverProductID'] as num).toInt(),
      deliveryTypeID: (json['deliveryTypeID'] as num).toInt(),
      meetingLocation: json['meetingLocation'] as String?,
    );

Map<String, dynamic> _$StartTradeRequestToJson(StartTradeRequest instance) =>
    <String, dynamic>{
      'userToken': instance.userToken,
      'senderProductID': instance.senderProductID,
      'receiverProductID': instance.receiverProductID,
      'deliveryTypeID': instance.deliveryTypeID,
      'meetingLocation': instance.meetingLocation,
    };

StartTradeResponse _$StartTradeResponseFromJson(Map<String, dynamic> json) =>
    StartTradeResponse(
      error: json['error'] as bool,
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : StartTradeData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StartTradeResponseToJson(StartTradeResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'success': instance.success,
      'data': instance.data,
    };

StartTradeData _$StartTradeDataFromJson(Map<String, dynamic> json) =>
    StartTradeData(message: json['message'] as String);

Map<String, dynamic> _$StartTradeDataToJson(StartTradeData instance) =>
    <String, dynamic>{'message': instance.message};

DeliveryType _$DeliveryTypeFromJson(Map<String, dynamic> json) => DeliveryType(
  deliveryID: (json['deliveryID'] as num).toInt(),
  deliveryTitle: json['deliveryTitle'] as String,
);

Map<String, dynamic> _$DeliveryTypeToJson(DeliveryType instance) =>
    <String, dynamic>{
      'deliveryID': instance.deliveryID,
      'deliveryTitle': instance.deliveryTitle,
    };

DeliveryTypesResponse _$DeliveryTypesResponseFromJson(
  Map<String, dynamic> json,
) => DeliveryTypesResponse(
  error: json['error'] as bool,
  success: json['success'] as bool,
  data: json['data'] == null
      ? null
      : DeliveryTypesData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeliveryTypesResponseToJson(
  DeliveryTypesResponse instance,
) => <String, dynamic>{
  'error': instance.error,
  'success': instance.success,
  'data': instance.data,
};

DeliveryTypesData _$DeliveryTypesDataFromJson(Map<String, dynamic> json) =>
    DeliveryTypesData(
      deliveryTypes: (json['deliveryTypes'] as List<dynamic>?)
          ?.map((e) => DeliveryType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DeliveryTypesDataToJson(DeliveryTypesData instance) =>
    <String, dynamic>{'deliveryTypes': instance.deliveryTypes};

TradeReview _$TradeReviewFromJson(Map<String, dynamic> json) => TradeReview(
  toUserID: (json['toUserID'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String,
);

Map<String, dynamic> _$TradeReviewToJson(TradeReview instance) =>
    <String, dynamic>{
      'toUserID': instance.toUserID,
      'rating': instance.rating,
      'comment': instance.comment,
    };

TradeCompleteRequest _$TradeCompleteRequestFromJson(
  Map<String, dynamic> json,
) => TradeCompleteRequest(
  userToken: json['userToken'] as String,
  offerID: (json['offerID'] as num).toInt(),
  statusID: (json['statusID'] as num).toInt(),
  meetingLocation: json['meetingLocation'] as String?,
  review: json['review'] == null
      ? null
      : TradeReview.fromJson(json['review'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TradeCompleteRequestToJson(
  TradeCompleteRequest instance,
) => <String, dynamic>{
  'userToken': instance.userToken,
  'offerID': instance.offerID,
  'statusID': instance.statusID,
  'meetingLocation': instance.meetingLocation,
  'review': instance.review,
};

TradeCompleteResponse _$TradeCompleteResponseFromJson(
  Map<String, dynamic> json,
) => TradeCompleteResponse(
  error: json['error'] as bool,
  success: json['success'] as bool,
  data: json['data'] == null
      ? null
      : TradeCompleteData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TradeCompleteResponseToJson(
  TradeCompleteResponse instance,
) => <String, dynamic>{
  'error': instance.error,
  'success': instance.success,
  'data': instance.data,
};

TradeCompleteData _$TradeCompleteDataFromJson(Map<String, dynamic> json) =>
    TradeCompleteData(message: json['message'] as String);

Map<String, dynamic> _$TradeCompleteDataToJson(TradeCompleteData instance) =>
    <String, dynamic>{'message': instance.message};

UserTrade _$UserTradeFromJson(Map<String, dynamic> json) => UserTrade(
  offerID: (json['offerID'] as num).toInt(),
  senderUserID: (json['senderUserID'] as num).toInt(),
  receiverUserID: (json['receiverUserID'] as num).toInt(),
  senderStatusID: (json['senderStatusID'] as num).toInt(),
  receiverStatusID: (json['receiverStatusID'] as num).toInt(),
  senderStatusTitle: json['senderStatusTitle'] as String,
  receiverStatusTitle: json['receiverStatusTitle'] as String,
  deliveryType: json['deliveryType'] as String,
  meetingLocation: json['meetingLocation'] as String?,
  createdAt: json['createdAt'] as String,
  completedAt: json['completedAt'] as String?,
  senderCancelDesc: json['senderCancelDesc'] as String?,
  receiverCancelDesc: json['receiverCancelDesc'] as String?,
  isSenderConfirm: json['isSenderConfirm'] as bool,
  isReceiverConfirm: json['isReceiverConfirm'] as bool,
  isTradeConfirm: json['isTradeConfirm'] as bool,
  isTradeStart: json['isTradeStart'] as bool,
  myProduct: json['myProduct'] == null
      ? null
      : TradeProduct.fromJson(json['myProduct'] as Map<String, dynamic>),
  theirProduct: json['theirProduct'] == null
      ? null
      : TradeProduct.fromJson(json['theirProduct'] as Map<String, dynamic>),
  rating: (json['rating'] as num?)?.toInt(),
  comment: json['comment'] as String?,
  hasReview: json['hasReview'] as bool?,
  canGiveReview: json['canGiveReview'] as bool?,
  isSenderReview: json['isSenderReview'] as bool?,
  isReceiverReview: json['isReceiverReview'] as bool?,
);

Map<String, dynamic> _$UserTradeToJson(UserTrade instance) => <String, dynamic>{
  'offerID': instance.offerID,
  'senderUserID': instance.senderUserID,
  'receiverUserID': instance.receiverUserID,
  'senderStatusID': instance.senderStatusID,
  'receiverStatusID': instance.receiverStatusID,
  'senderStatusTitle': instance.senderStatusTitle,
  'receiverStatusTitle': instance.receiverStatusTitle,
  'deliveryType': instance.deliveryType,
  'meetingLocation': instance.meetingLocation,
  'createdAt': instance.createdAt,
  'completedAt': instance.completedAt,
  'senderCancelDesc': instance.senderCancelDesc,
  'receiverCancelDesc': instance.receiverCancelDesc,
  'isSenderConfirm': instance.isSenderConfirm,
  'isReceiverConfirm': instance.isReceiverConfirm,
  'isTradeConfirm': instance.isTradeConfirm,
  'isTradeStart': instance.isTradeStart,
  'myProduct': instance.myProduct,
  'theirProduct': instance.theirProduct,
  'rating': instance.rating,
  'comment': instance.comment,
  'hasReview': instance.hasReview,
  'canGiveReview': instance.canGiveReview,
  'isSenderReview': instance.isSenderReview,
  'isReceiverReview': instance.isReceiverReview,
};

TradeProduct _$TradeProductFromJson(Map<String, dynamic> json) => TradeProduct(
  productID: (json['productID'] as num).toInt(),
  productTitle: json['productTitle'] as String,
  productDesc: json['productDesc'] as String,
  productImage: json['productImage'] as String,
  productCondition: json['productCondition'] as String,
  tradeFor: json['tradeFor'] as String,
  categoryTitle: json['categoryTitle'] as String,
  userID: (json['userID'] as num).toInt(),
  categoryID: (json['categoryID'] as num).toInt(),
  conditionID: (json['conditionID'] as num).toInt(),
  cityID: (json['cityID'] as num).toInt(),
  districtID: (json['districtID'] as num).toInt(),
  cityTitle: json['cityTitle'] as String,
  districtTitle: json['districtTitle'] as String?,
  createdAt: json['createdAt'] as String,
  isFavorite: json['isFavorite'] as bool,
);

Map<String, dynamic> _$TradeProductToJson(TradeProduct instance) =>
    <String, dynamic>{
      'productID': instance.productID,
      'productTitle': instance.productTitle,
      'productDesc': instance.productDesc,
      'productImage': instance.productImage,
      'productCondition': instance.productCondition,
      'tradeFor': instance.tradeFor,
      'categoryTitle': instance.categoryTitle,
      'userID': instance.userID,
      'categoryID': instance.categoryID,
      'conditionID': instance.conditionID,
      'cityID': instance.cityID,
      'districtID': instance.districtID,
      'cityTitle': instance.cityTitle,
      'districtTitle': instance.districtTitle,
      'createdAt': instance.createdAt,
      'isFavorite': instance.isFavorite,
    };

UserTradesResponse _$UserTradesResponseFromJson(Map<String, dynamic> json) =>
    UserTradesResponse(
      error: json['error'] as bool,
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : UserTradesData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserTradesResponseToJson(UserTradesResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'success': instance.success,
      'data': instance.data,
    };

UserTradesData _$UserTradesDataFromJson(Map<String, dynamic> json) =>
    UserTradesData(
      trades: (json['trades'] as List<dynamic>?)
          ?.map((e) => UserTrade.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserTradesDataToJson(UserTradesData instance) =>
    <String, dynamic>{'trades': instance.trades};
