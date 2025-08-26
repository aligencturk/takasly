// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************



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







