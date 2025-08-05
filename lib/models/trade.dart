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
  final int? isConfirm; // 1: Mevcut kullanıcı teklifi gönderen, 0: Mevcut kullanıcı teklifi alan, null: Belirsiz
  final TradeProduct? myProduct;
  final TradeProduct? theirProduct;
  final String? cancelDesc; // Reddetme sebebi (API'den cancelDesc olarak geliyor)
  final int? rating; // Yorum puanı
  final String? comment; // Yorum metni
  final bool? hasReview; // Yorum yapılıp yapılmadığı

  const UserTrade({
    required this.offerID,
    required this.statusID,
    required this.statusTitle,
    required this.deliveryType,
    this.meetingLocation,
    required this.createdAt,
    this.completedAt,
    this.isConfirm,
    this.myProduct,
    this.theirProduct,
    this.cancelDesc,
    this.rating,
    this.comment,
    this.hasReview,
  });

  factory UserTrade.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: JSON verisini logla
      print('🔍 UserTrade.fromJson - JSON data: $json');
      
      final offerID = json['offerID'] as int? ?? 0;
      final senderUserID = json['senderUserID'] as int? ?? 0;
      final receiverUserID = json['receiverUserID'] as int? ?? 0;
      final senderStatusID = json['senderStatusID'] as int? ?? 0;
      final receiverStatusID = json['receiverStatusID'] as int? ?? 0;
      final senderStatusTitle = json['senderStatusTitle'] as String? ?? '';
      final receiverStatusTitle = json['receiverStatusTitle'] as String? ?? '';
      final deliveryType = json['deliveryType'] as String? ?? '';
      final meetingLocation = json['meetingLocation'] as String?;
      final createdAt = json['createdAt'] as String? ?? '';
      final completedAt = json['completedAt'] as String?;
      // isConfirm alanını güvenli şekilde parse et
      final isConfirm = _parseIsConfirm(json['isConfirm']);
      
      // Mevcut kullanıcının ID'sini al (AuthService'den)
      // Bu değer TradeViewModel'de set edilecek
      final currentUserId = json['currentUserId'] as int? ?? 0;
      
      // Mevcut kullanıcının sender mı receiver mı olduğunu belirle
      bool isSender = false;
      bool isReceiver = false;
      int statusID = 0;
      String statusTitle = '';
      
      if (currentUserId > 0) {
        if (currentUserId == senderUserID) {
          isSender = true;
          statusID = senderStatusID;
          statusTitle = senderStatusTitle;
        } else if (currentUserId == receiverUserID) {
          isReceiver = true;
          statusID = receiverStatusID;
          statusTitle = receiverStatusTitle;
        }
      }
      
      // Eğer currentUserId belirlenemezse, varsayılan olarak sender durumunu kullan
      if (statusID == 0) {
        statusID = senderStatusID;
        statusTitle = senderStatusTitle;
      }
      
      // myProduct güvenli parse
      TradeProduct? myProduct;
      try {
        if (json['myProduct'] != null) {
          myProduct = TradeProduct.fromJson(json['myProduct'] as Map<String, dynamic>);
        }
      } catch (e) {
        // Logger.debug('⚠️ UserTrade.fromJson - myProduct parse error: $e', tag: 'Trade');
        myProduct = null;
      }
      
      // theirProduct güvenli parse
      TradeProduct? theirProduct;
      try {
        if (json['theirProduct'] != null) {
          theirProduct = TradeProduct.fromJson(json['theirProduct'] as Map<String, dynamic>);
        }
      } catch (e) {
        print('⚠️ UserTrade.fromJson - theirProduct parse error: $e');
        theirProduct = null;
      }
      
      final cancelDesc = json['cancelDesc'] as String?;
      print('🔍 UserTrade.fromJson - cancelDesc: "$cancelDesc"');
      print('🔍 UserTrade.fromJson - JSON keys: ${json.keys.toList()}');
      print('🔍 UserTrade.fromJson - JSON contains cancelDesc: ${json.containsKey('cancelDesc')}');
      
      final userTrade = UserTrade(
        offerID: offerID,
        statusID: statusID,
        statusTitle: statusTitle,
        deliveryType: deliveryType,
        meetingLocation: meetingLocation,
        createdAt: createdAt,
        completedAt: completedAt,
        isConfirm: isConfirm,
        myProduct: myProduct,
        theirProduct: theirProduct,
        cancelDesc: cancelDesc,
      );
      
      print('✅ UserTrade.fromJson - Successfully created: offerID=$offerID, statusID=$statusID, statusTitle="$statusTitle"');
      return userTrade;
    } catch (e) {
      // JSON parse hatası durumunda varsayılan değerlerle oluştur
      print('⚠️ UserTrade.fromJson error: $e');
      print('⚠️ JSON data: $json');
      return UserTrade(
        offerID: json['offerID'] as int? ?? 0,
        statusID: json['statusID'] as int? ?? 0,
        statusTitle: json['statusTitle'] as String? ?? 'Bilinmeyen',
        deliveryType: json['deliveryType'] as String? ?? 'Bilinmeyen',
        meetingLocation: json['meetingLocation'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        completedAt: json['completedAt'] as String?,
        isConfirm: _parseIsConfirm(json['isConfirm']),
        myProduct: null,
        theirProduct: null,
        cancelDesc: json['cancelDesc'] as String?,
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'offerID': offerID,
    'statusID': statusID,
    'statusTitle': statusTitle,
    'deliveryType': deliveryType,
    if (meetingLocation != null) 'meetingLocation': meetingLocation,
    'createdAt': createdAt,
    if (completedAt != null) 'completedAt': completedAt,
    if (isConfirm != null) 'isConfirm': isConfirm,
    if (myProduct != null) 'myProduct': myProduct!.toJson(),
    if (theirProduct != null) 'theirProduct': theirProduct!.toJson(),
    if (cancelDesc != null) 'cancelDesc': cancelDesc,
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

  // isConfirm alanını güvenli şekilde parse eden yardımcı metod
  static int? _parseIsConfirm(dynamic value) {
    if (value == null) {
      return null; // null ise null döndür
    } else if (value is bool) {
      return value ? 1 : 0;
    } else if (value is int) {
      return value;
    } else {
      return null; // Diğer durumlar için null döndür
    }
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
    try {
      // Debug: JSON verisini logla
      print('🔍 TradeProduct.fromJson - JSON data: $json');
      
      final productID = json['productID'] as int? ?? 0;
      final productTitle = json['productTitle'] as String? ?? '';
      final productDesc = json['productDesc'] as String? ?? '';
      final productImage = json['productImage'] as String? ?? '';
      final productCondition = json['productCondition'] as String? ?? '';
      final tradeFor = json['tradeFor'] as String? ?? '';
      final categoryTitle = json['categoryTitle'] as String? ?? '';
      final userID = json['userID'] as int? ?? 0;
      final categoryID = json['categoryID'] as int? ?? 0;
      final conditionID = json['conditionID'] as int? ?? 0;
      final cityID = json['cityID'] as int? ?? 0;
      final districtID = json['districtID'] as int? ?? 0;
      final cityTitle = json['cityTitle'] as String? ?? '';
      final districtTitle = json['districtTitle'] as String?;
      final createdAt = json['createdAt'] as String? ?? '';
      final isFavorite = json['isFavorite'] as bool? ?? false;
      
      final tradeProduct = TradeProduct(
        productID: productID,
        productTitle: productTitle,
        productDesc: productDesc,
        productImage: productImage,
        productCondition: productCondition,
        tradeFor: tradeFor,
        categoryTitle: categoryTitle,
        userID: userID,
        categoryID: categoryID,
        conditionID: conditionID,
        cityID: cityID,
        districtID: districtID,
        cityTitle: cityTitle,
        districtTitle: districtTitle,
        createdAt: createdAt,
        isFavorite: isFavorite,
      );
      
      print('✅ TradeProduct.fromJson - Successfully created: productID=$productID, productTitle=$productTitle');
      return tradeProduct;
    } catch (e) {
      // JSON parse hatası durumunda varsayılan değerlerle oluştur
      print('⚠️ TradeProduct.fromJson error: $e');
      print('⚠️ JSON data: $json');
      return TradeProduct(
        productID: 0,
        productTitle: 'Bilinmeyen Ürün',
        productDesc: '',
        productImage: '',
        productCondition: 'Bilinmeyen',
        tradeFor: '',
        categoryTitle: '',
        userID: 0,
        categoryID: 0,
        conditionID: 0,
        cityID: 0,
        districtID: 0,
        cityTitle: '',
        createdAt: '',
        isFavorite: false,
      );
    }
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
    try {
      // Debug: JSON verisini logla
      print('🔍 UserTradesResponse.fromJson - JSON data: $json');
      
      final error = json['error'] as bool? ?? false;
      final success = json['success'] as bool? ?? false;
      
      UserTradesData? data;
      try {
        if (json['data'] != null) {
          data = UserTradesData.fromJson(json['data'] as Map<String, dynamic>);
        }
      } catch (e) {
        print('⚠️ UserTradesResponse.fromJson - data parse error: $e');
        data = UserTradesData(trades: []);
      }
      
      final response = UserTradesResponse(
        error: error,
        success: success,
        data: data,
      );
      
      print('✅ UserTradesResponse.fromJson - Successfully created: error=$error, success=$success, tradesCount=${data?.trades?.length ?? 0}');
      return response;
    } catch (e) {
      // JSON parse hatası durumunda boş response döndür
      print('⚠️ UserTradesResponse.fromJson error: $e');
      print('⚠️ JSON data: $json');
      return UserTradesResponse(
        error: false,
        success: true,
        data: UserTradesData(trades: []),
      );
    }
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
    try {
      print('🔍 UserTradesData.fromJson - JSON data: $json');
      
      List<UserTrade>? trades;
      try {
        if (json['trades'] != null) {
          final tradesList = json['trades'] as List;
          print('🔍 UserTradesData.fromJson - Found ${tradesList.length} trades in JSON');
          
          trades = <UserTrade>[];
          for (int i = 0; i < tradesList.length; i++) {
            try {
              final tradeJson = tradesList[i] as Map<String, dynamic>;
              print('🔍 UserTradesData.fromJson - Parsing trade $i: $tradeJson');
              
              // currentUserId'yi ekle (AuthService'den alınacak)
              // Bu değer TradeViewModel'de set edilecek
              final currentUserId = json['currentUserId'] as int? ?? 0;
              tradeJson['currentUserId'] = currentUserId;
              
              final trade = UserTrade.fromJson(tradeJson);
              trades.add(trade);
              print('✅ UserTradesData.fromJson - Successfully parsed trade $i: offerID=${trade.offerID}, rejectionReason="${trade.cancelDesc}"');
            } catch (e) {
              print('⚠️ UserTradesData.fromJson - Failed to parse trade $i: $e');
              // Hatalı trade'i atla
            }
          }
        }
      } catch (e) {
        print('⚠️ UserTradesData.fromJson - trades parse error: $e');
        trades = [];
      }
      
      final data = UserTradesData(trades: trades);
      print('✅ UserTradesData.fromJson - Successfully created with ${trades?.length ?? 0} trades');
      return data;
    } catch (e) {
      // JSON parse hatası durumunda boş liste döndür
      print('⚠️ UserTradesData.fromJson error: $e');
      print('⚠️ JSON data: $json');
      return UserTradesData(trades: []);
    }
  }

  @override
  String toString() {
    return 'UserTradesData(tradesCount: ${trades?.length ?? 0})';
  }
} 

/// Takas onaylama request modeli
class ConfirmTradeRequest {
  final String userToken;
  final int offerID;
  final int isConfirm; // 1: Onaylıyor, 0: Onaylamıyor
  final String cancelDesc; // Onaylamadıysa reddetme sebebi

  ConfirmTradeRequest({
    required this.userToken,
    required this.offerID,
    required this.isConfirm,
    required this.cancelDesc,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'offerID': offerID,
      'isConfirm': isConfirm,
      'cancelDesc': cancelDesc,
    };
  }

  factory ConfirmTradeRequest.fromJson(Map<String, dynamic> json) {
    return ConfirmTradeRequest(
      userToken: json['userToken'] ?? '',
      offerID: json['offerID'] ?? 0,
      isConfirm: json['isConfirm'] ?? 0,
      cancelDesc: json['cancelDesc'] ?? '',
    );
  }
}

/// Takas onaylama response modeli
class ConfirmTradeResponse {
  final bool error;
  final bool success;
  final ConfirmTradeData? data;
  final String? status410;

  ConfirmTradeResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
  });

  factory ConfirmTradeResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmTradeResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: json['data'] != null ? ConfirmTradeData.fromJson(json['data']) : null,
      status410: json['410'],
    );
  }
}

/// Takas onaylama data modeli
class ConfirmTradeData {
  final String message;

  ConfirmTradeData({
    required this.message,
  });

  factory ConfirmTradeData.fromJson(Map<String, dynamic> json) {
    return ConfirmTradeData(
      message: json['message'] ?? '',
    );
  }
}

/// Takas kontrolü request modeli
class CheckTradeStatusRequest {
  final String userToken;
  final int senderProductID;
  final int receiverProductID;

  const CheckTradeStatusRequest({
    required this.userToken,
    required this.senderProductID,
    required this.receiverProductID,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'senderProductID': senderProductID,
    'receiverProductID': receiverProductID,
  };

  @override
  String toString() {
    return 'CheckTradeStatusRequest(senderProductID: $senderProductID, receiverProductID: $receiverProductID)';
  }
}

/// Takas kontrolü response modeli
class CheckTradeStatusResponse {
  final bool error;
  final CheckTradeStatusData? data;
  final String? status410;

  const CheckTradeStatusResponse({
    required this.error,
    this.data,
    this.status410,
  });

  factory CheckTradeStatusResponse.fromJson(Map<String, dynamic> json) {
    return CheckTradeStatusResponse(
      error: json['error'] as bool? ?? false,
      data: json['data'] != null 
          ? CheckTradeStatusData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      status410: json['410'] as String?,
    );
  }

  @override
  String toString() {
    return 'CheckTradeStatusResponse(error: $error, success: ${data?.success}, message: ${data?.message})';
  }
}

/// Takas kontrolü data modeli
class CheckTradeStatusData {
  final bool success;
  final bool isSender;
  final bool isReceiver;
  final bool showButtons;
  final String message;
  final String statusID;

  const CheckTradeStatusData({
    required this.success,
    required this.isSender,
    required this.isReceiver,
    required this.showButtons,
    required this.message,
    required this.statusID,
  });

  factory CheckTradeStatusData.fromJson(Map<String, dynamic> json) {
    return CheckTradeStatusData(
      success: json['success'] as bool? ?? false,
      isSender: json['isSender'] as bool? ?? false,
      isReceiver: json['isReceiver'] as bool? ?? false,
      showButtons: json['showButtons'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      statusID: json['statusID'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'CheckTradeStatusData(success: $success, isSender: $isSender, isReceiver: $isReceiver, showButtons: $showButtons, statusID: $statusID, message: $message)';
  }
} 

/// Basit takas tamamlama request modeli (sadece userToken ve offerID)
class TradeCompleteSimpleRequest {
  final String userToken;
  final int offerID;

  const TradeCompleteSimpleRequest({
    required this.userToken,
    required this.offerID,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'offerID': offerID,
  };

  @override
  String toString() {
    return 'TradeCompleteSimpleRequest(offerID: $offerID)';
  }
}

/// Basit takas tamamlama response modeli
class TradeCompleteSimpleResponse {
  final bool error;
  final bool success;
  final TradeCompleteSimpleData? data;
  final String? status410;

  const TradeCompleteSimpleResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
  });

  factory TradeCompleteSimpleResponse.fromJson(Map<String, dynamic> json) {
    return TradeCompleteSimpleResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? TradeCompleteSimpleData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      status410: json['410'] as String?,
    );
  }

  @override
  String toString() {
    return 'TradeCompleteSimpleResponse(error: $error, success: $success, message: ${data?.message})';
  }
}

/// Basit takas tamamlama data modeli
class TradeCompleteSimpleData {
  final String message;

  const TradeCompleteSimpleData({
    required this.message,
  });

  factory TradeCompleteSimpleData.fromJson(Map<String, dynamic> json) {
    return TradeCompleteSimpleData(
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'TradeCompleteSimpleData(message: $message)';
  }
} 

/// Takas değerlendirme request modeli
class TradeReviewRequest {
  final String userToken;
  final int offerID;
  final int rating;
  final String? comment; // Opsiyonel

  const TradeReviewRequest({
    required this.userToken,
    required this.offerID,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'offerID': offerID,
    'rating': rating,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
  };

  @override
  String toString() {
    return 'TradeReviewRequest(offerID: $offerID, rating: $rating, comment: $comment)';
  }
}

/// Takas değerlendirme response modeli
class TradeReviewResponse {
  final bool error;
  final bool success;
  final TradeReviewData? data;
  final String? status410;

  const TradeReviewResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
  });

  factory TradeReviewResponse.fromJson(Map<String, dynamic> json) {
    return TradeReviewResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null 
          ? TradeReviewData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      status410: json['410'] as String?,
    );
  }

  @override
  String toString() {
    return 'TradeReviewResponse(error: $error, success: $success, message: ${data?.message})';
  }
}

/// Takas değerlendirme data modeli
class TradeReviewData {
  final String message;

  const TradeReviewData({
    required this.message,
  });

  factory TradeReviewData.fromJson(Map<String, dynamic> json) {
    return TradeReviewData(
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'TradeReviewData(message: $message)';
  }
} 