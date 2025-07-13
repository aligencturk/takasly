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
