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

@JsonSerializable()
class StartTradeRequest {
  final String userToken;
  final int senderProductID;
  final int receiverProductID;
  final int deliveryTypeID;
  final String? meetingLocation;

  const StartTradeRequest({
    required this.userToken,
    required this.senderProductID,
    required this.receiverProductID,
    required this.deliveryTypeID,
    this.meetingLocation,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'senderProductID': senderProductID,
    'receiverProductID': receiverProductID,
    'deliveryTypeID': deliveryTypeID,
    if (meetingLocation != null) 'meetingLocation': meetingLocation,
  };

  @override
  String toString() {
    return 'StartTradeRequest(senderProductID: $senderProductID, receiverProductID: $receiverProductID, deliveryTypeID: $deliveryTypeID)';
  }
}

@JsonSerializable()
class StartTradeResponse {
  final bool error;
  final bool success;
  final StartTradeData? data;

  const StartTradeResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory StartTradeResponse.fromJson(Map<String, dynamic> json) {
    return StartTradeResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? StartTradeData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'StartTradeResponse(error: $error, success: $success, message: ${data?.message})';
  }
}

@JsonSerializable()
class StartTradeData {
  final String message;

  const StartTradeData({
    required this.message,
  });

  factory StartTradeData.fromJson(Map<String, dynamic> json) {
    return StartTradeData(
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'StartTradeData(message: $message)';
  }
}

@JsonSerializable()
class TradeStatusModel {
  final int statusID;
  final String statusTitle;

  const TradeStatusModel({
    required this.statusID,
    required this.statusTitle,
  });

  factory TradeStatusModel.fromJson(Map<String, dynamic> json) {
    return TradeStatusModel(
      statusID: json['statusID'] as int? ?? 0,
      statusTitle: json['statusTitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'statusID': statusID,
    'statusTitle': statusTitle,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeStatusModel && other.statusID == statusID;
  }

  @override
  int get hashCode => statusID.hashCode;

  @override
  String toString() {
    return 'TradeStatusModel(statusID: $statusID, statusTitle: $statusTitle)';
  }
}

@JsonSerializable()
class TradeStatusesResponse {
  final bool error;
  final bool success;
  final TradeStatusesData? data;

  const TradeStatusesResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory TradeStatusesResponse.fromJson(Map<String, dynamic> json) {
    return TradeStatusesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? TradeStatusesData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'TradeStatusesResponse(error: $error, success: $success, statusesCount: ${data?.statuses?.length ?? 0})';
  }
}

@JsonSerializable()
class TradeStatusesData {
  final List<TradeStatusModel>? statuses;

  const TradeStatusesData({
    this.statuses,
  });

  factory TradeStatusesData.fromJson(Map<String, dynamic> json) {
    return TradeStatusesData(
      statuses: json['statuses'] != null
          ? (json['statuses'] as List)
              .map((item) => TradeStatusModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  String toString() {
    return 'TradeStatusesData(statusesCount: ${statuses?.length ?? 0})';
  }
}

@JsonSerializable()
class DeliveryType {
  final int deliveryID;
  final String deliveryTitle;

  const DeliveryType({
    required this.deliveryID,
    required this.deliveryTitle,
  });

  factory DeliveryType.fromJson(Map<String, dynamic> json) {
    return DeliveryType(
      deliveryID: json['deliveryID'] as int? ?? 0,
      deliveryTitle: json['deliveryTitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deliveryID': deliveryID,
    'deliveryTitle': deliveryTitle,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryType && other.deliveryID == deliveryID;
  }

  @override
  int get hashCode => deliveryID.hashCode;

  @override
  String toString() {
    return 'DeliveryType(deliveryID: $deliveryID, deliveryTitle: $deliveryTitle)';
  }
}

@JsonSerializable()
class DeliveryTypesResponse {
  final bool error;
  final bool success;
  final DeliveryTypesData? data;

  const DeliveryTypesResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory DeliveryTypesResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryTypesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? DeliveryTypesData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'DeliveryTypesResponse(error: $error, success: $success, deliveryTypesCount: ${data?.deliveryTypes?.length ?? 0})';
  }
}

@JsonSerializable()
class DeliveryTypesData {
  final List<DeliveryType>? deliveryTypes;

  const DeliveryTypesData({
    this.deliveryTypes,
  });

  factory DeliveryTypesData.fromJson(Map<String, dynamic> json) {
    return DeliveryTypesData(
      deliveryTypes: json['deliveryTypes'] != null
          ? (json['deliveryTypes'] as List)
              .map((item) => DeliveryType.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  String toString() {
    return 'DeliveryTypesData(deliveryTypesCount: ${deliveryTypes?.length ?? 0})';
  }
}

@JsonSerializable()
class TradeReview {
  final int toUserID;
  final int rating;
  final String comment;

  const TradeReview({
    required this.toUserID,
    required this.rating,
    required this.comment,
  });

  factory TradeReview.fromJson(Map<String, dynamic> json) {
    return TradeReview(
      toUserID: json['toUserID'] as int? ?? 0,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'toUserID': toUserID,
    'rating': rating,
    'comment': comment,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeReview && 
           other.toUserID == toUserID && 
           other.rating == rating;
  }

  @override
  int get hashCode => toUserID.hashCode ^ rating.hashCode;

  @override
  String toString() {
    return 'TradeReview(toUserID: $toUserID, rating: $rating, comment: $comment)';
  }
}

@JsonSerializable()
class TradeCompleteRequest {
  final String userToken;
  final int offerID;
  final int statusID;
  final String? meetingLocation;
  final TradeReview? review;

  const TradeCompleteRequest({
    required this.userToken,
    required this.offerID,
    required this.statusID,
    this.meetingLocation,
    this.review,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'offerID': offerID,
    'statusID': statusID,
    if (meetingLocation != null) 'meetingLocation': meetingLocation,
    if (review != null) 'review': review!.toJson(),
  };

  @override
  String toString() {
    return 'TradeCompleteRequest(offerID: $offerID, statusID: $statusID, hasReview: ${review != null})';
  }
}

@JsonSerializable()
class TradeCompleteResponse {
  final bool error;
  final bool success;
  final TradeCompleteData? data;

  const TradeCompleteResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory TradeCompleteResponse.fromJson(Map<String, dynamic> json) {
    return TradeCompleteResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? TradeCompleteData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'TradeCompleteResponse(error: $error, success: $success, message: ${data?.message})';
  }
}

@JsonSerializable()
class TradeCompleteData {
  final String message;

  const TradeCompleteData({
    required this.message,
  });

  factory TradeCompleteData.fromJson(Map<String, dynamic> json) {
    return TradeCompleteData(
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'TradeCompleteData(message: $message)';
  }
}

@JsonSerializable()
class UserTrade {
  final int offerID;
  final int statusID;
  final String statusTitle;
  final String deliveryType;
  final String? meetingLocation;
  final String createdAt;
  final String? completedAt;
  final TradeProduct myProduct;
  final TradeProduct theirProduct;

  const UserTrade({
    required this.offerID,
    required this.statusID,
    required this.statusTitle,
    required this.deliveryType,
    this.meetingLocation,
    required this.createdAt,
    this.completedAt,
    required this.myProduct,
    required this.theirProduct,
  });

  factory UserTrade.fromJson(Map<String, dynamic> json) {
    return UserTrade(
      offerID: json['offerID'] as int? ?? 0,
      statusID: json['statusID'] as int? ?? 0,
      statusTitle: json['statusTitle'] as String? ?? '',
      deliveryType: json['deliveryType'] as String? ?? '',
      meetingLocation: json['meetingLocation'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
      myProduct: TradeProduct.fromJson(json['myProduct'] as Map<String, dynamic>),
      theirProduct: TradeProduct.fromJson(json['theirProduct'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'offerID': offerID,
    'statusID': statusID,
    'statusTitle': statusTitle,
    'deliveryType': deliveryType,
    if (meetingLocation != null) 'meetingLocation': meetingLocation,
    'createdAt': createdAt,
    if (completedAt != null) 'completedAt': completedAt,
    'myProduct': myProduct.toJson(),
    'theirProduct': theirProduct.toJson(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTrade && other.offerID == offerID;
  }

  @override
  int get hashCode => offerID.hashCode;

  @override
  String toString() {
    return 'UserTrade(offerID: $offerID, statusTitle: $statusTitle, deliveryType: $deliveryType)';
  }
}

@JsonSerializable()
class TradeProduct {
  final int productID;
  final String productTitle;
  final String productDesc;
  final String productImage;
  final String productCondition;
  final String tradeFor;
  final String categoryTitle;
  final int userID;
  final int categoryID;
  final int conditionID;
  final int cityID;
  final int districtID;
  final String cityTitle;
  final String? districtTitle;
  final String createdAt;
  final bool isFavorite;

  const TradeProduct({
    required this.productID,
    required this.productTitle,
    required this.productDesc,
    required this.productImage,
    required this.productCondition,
    required this.tradeFor,
    required this.categoryTitle,
    required this.userID,
    required this.categoryID,
    required this.conditionID,
    required this.cityID,
    required this.districtID,
    required this.cityTitle,
    this.districtTitle,
    required this.createdAt,
    required this.isFavorite,
  });

  factory TradeProduct.fromJson(Map<String, dynamic> json) {
    return TradeProduct(
      productID: json['productID'] as int? ?? 0,
      productTitle: json['productTitle'] as String? ?? '',
      productDesc: json['productDesc'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      productCondition: json['productCondition'] as String? ?? '',
      tradeFor: json['tradeFor'] as String? ?? '',
      categoryTitle: json['categoryTitle'] as String? ?? '',
      userID: json['userID'] as int? ?? 0,
      categoryID: json['categoryID'] as int? ?? 0,
      conditionID: json['conditionID'] as int? ?? 0,
      cityID: json['cityID'] as int? ?? 0,
      districtID: json['districtID'] as int? ?? 0,
      cityTitle: json['cityTitle'] as String? ?? '',
      districtTitle: json['districtTitle'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'productID': productID,
    'productTitle': productTitle,
    'productDesc': productDesc,
    'productImage': productImage,
    'productCondition': productCondition,
    'tradeFor': tradeFor,
    'categoryTitle': categoryTitle,
    'userID': userID,
    'categoryID': categoryID,
    'conditionID': conditionID,
    'cityID': cityID,
    'districtID': districtID,
    'cityTitle': cityTitle,
    if (districtTitle != null) 'districtTitle': districtTitle,
    'createdAt': createdAt,
    'isFavorite': isFavorite,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeProduct && other.productID == productID;
  }

  @override
  int get hashCode => productID.hashCode;

  @override
  String toString() {
    return 'TradeProduct(productID: $productID, productTitle: $productTitle)';
  }
}

@JsonSerializable()
class UserTradesResponse {
  final bool error;
  final bool success;
  final UserTradesData? data;

  const UserTradesResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory UserTradesResponse.fromJson(Map<String, dynamic> json) {
    return UserTradesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? UserTradesData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'UserTradesResponse(error: $error, success: $success, tradesCount: ${data?.trades?.length ?? 0})';
  }
}

@JsonSerializable()
class UserTradesData {
  final List<UserTrade>? trades;

  const UserTradesData({
    this.trades,
  });

  factory UserTradesData.fromJson(Map<String, dynamic> json) {
    return UserTradesData(
      trades: json['trades'] != null
          ? (json['trades'] as List)
              .map((item) => UserTrade.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  String toString() {
    return 'UserTradesData(tradesCount: ${trades?.length ?? 0})';
  }
} 