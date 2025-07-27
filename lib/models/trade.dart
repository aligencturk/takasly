import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
import 'product.dart';

part 'trade.g.dart';

@JsonSerializable()
class Trade {
  final String id;
  final String offererUserId;
  final User offererUser;
  final String receiverUserId;
  final User receiverUser;
  final List<String> offeredProductIds;
  final List<Product> offeredProducts;
  final List<String> requestedProductIds;
  final List<Product> requestedProducts;
  final TradeStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final String? cancellationReason;

  const Trade({
    required this.id,
    required this.offererUserId,
    required this.offererUser,
    required this.receiverUserId,
    required this.receiverUser,
    required this.offeredProductIds,
    required this.offeredProducts,
    required this.requestedProductIds,
    required this.requestedProducts,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.completedAt,
    this.cancellationReason,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return Trade(
      id: json['id'] as String,
      offererUserId: json['offererUserId'] as String? ?? '',
      offererUser: json['offererUser'] != null 
          ? User.fromJson(json['offererUser'] as Map<String, dynamic>)
          : User(
              id: '',
              name: '',
              email: '',
              isVerified: false,
              isOnline: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      receiverUserId: json['receiverUserId'] as String? ?? '',
      receiverUser: json['receiverUser'] != null 
          ? User.fromJson(json['receiverUser'] as Map<String, dynamic>)
          : User(
              id: '',
              name: '',
              email: '',
              isVerified: false,
              isOnline: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      offeredProductIds: (json['offeredProductIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      offeredProducts: (json['offeredProducts'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      requestedProductIds: (json['requestedProductIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      requestedProducts: (json['requestedProducts'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      status: TradeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TradeStatus.pending,
      ),
      message: json['message'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      expiresAt: json['expiresAt'] != null ? parseDateTime(json['expiresAt']) : null,
      completedAt: json['completedAt'] != null ? parseDateTime(json['completedAt']) : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$TradeToJson(this);

  Trade copyWith({
    String? id,
    String? offererUserId,
    User? offererUser,
    String? receiverUserId,
    User? receiverUser,
    List<String>? offeredProductIds,
    List<Product>? offeredProducts,
    List<String>? requestedProductIds,
    List<Product>? requestedProducts,
    TradeStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    String? cancellationReason,
  }) {
    return Trade(
      id: id ?? this.id,
      offererUserId: offererUserId ?? this.offererUserId,
      offererUser: offererUser ?? this.offererUser,
      receiverUserId: receiverUserId ?? this.receiverUserId,
      receiverUser: receiverUser ?? this.receiverUser,
      offeredProductIds: offeredProductIds ?? this.offeredProductIds,
      offeredProducts: offeredProducts ?? this.offeredProducts,
      requestedProductIds: requestedProductIds ?? this.requestedProductIds,
      requestedProducts: requestedProducts ?? this.requestedProducts,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trade && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Trade(id: $id, status: $status, offerer: ${offererUser.name}, receiver: ${receiverUser.name})';
  }
}

enum TradeStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
  expired,
}

@JsonSerializable()
class TradeOffer {
  final String id;
  final String tradeId;
  final String userId;
  final User user;
  final String productId;
  final Product product;
  final String? message;
  final DateTime createdAt;

  const TradeOffer({
    required this.id,
    required this.tradeId,
    required this.userId,
    required this.user,
    required this.productId,
    required this.product,
    this.message,
    required this.createdAt,
  });

  factory TradeOffer.fromJson(Map<String, dynamic> json) => _$TradeOfferFromJson(json);
  Map<String, dynamic> toJson() => _$TradeOfferToJson(this);

  TradeOffer copyWith({
    String? id,
    String? tradeId,
    String? userId,
    User? user,
    String? productId,
    Product? product,
    String? message,
    DateTime? createdAt,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeOffer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TradeOffer(id: $id, user: ${user.name}, product: ${product.title})';
  }
} 