import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
import 'trade.dart';
import 'product.dart';

part 'chat.g.dart';

@JsonSerializable()
class Chat {
  final String id;
  final String tradeId;
  final Trade trade;
  final List<String> participantIds;
  final List<User> participants;
  final String? lastMessageId;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, DateTime> lastReadTimes;
  final bool isActive;
  final bool isPinned;
  final List<String> deletedBy;

  const Chat({
    required this.id,
    required this.tradeId,
    required this.trade,
    required this.participantIds,
    required this.participants,
    this.lastMessageId,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.lastReadTimes,
    required this.isActive,
    this.isPinned = false,
    this.deletedBy = const [],
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return Chat(
      id: json['id'] as String,
      tradeId: json['tradeId'] as String,
      trade: json['trade'] != null 
          ? Trade.fromJson(json['trade'] as Map<String, dynamic>)
          : Trade(
              id: json['tradeId'] as String,
              offererUserId: '',
              offererUser: User(
                id: '',
                name: '',
                email: '',
                isVerified: false,
                isOnline: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              receiverUserId: '',
              receiverUser: User(
                id: '',
                name: '',
                email: '',
                isVerified: false,
                isOnline: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              offeredProductIds: [],
              offeredProducts: [],
              requestedProductIds: [],
              requestedProducts: [],
              status: TradeStatus.pending,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      lastMessageId: json['lastMessageId'] as String?,
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      lastReadTimes: (json['lastReadTimes'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, parseDateTime(e)))
          ?? {},
      isActive: json['isActive'] as bool? ?? true,
      isPinned: json['isPinned'] as bool? ?? false,
      deletedBy: (json['deletedBy'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
  Map<String, dynamic> toJson() => _$ChatToJson(this)
    ..addAll({
      'isPinned': isPinned,
      'deletedBy': deletedBy,
    });

  Chat copyWith({
    String? id,
    String? tradeId,
    Trade? trade,
    List<String>? participantIds,
    List<User>? participants,
    String? lastMessageId,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, DateTime>? lastReadTimes,
    bool? isActive,
    bool? isPinned,
    List<String>? deletedBy,
  }) {
    return Chat(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      trade: trade ?? this.trade,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReadTimes: lastReadTimes ?? this.lastReadTimes,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chat(id: $id, tradeId: $tradeId, participants: ${participants.length})';
  }
}

@JsonSerializable()
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final User sender;
  final String content;
  final MessageType type;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final bool isDeleted;
  final String? replyToId;
  final Message? replyTo;
  final Product? product;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.sender,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isRead,
    required this.isDeleted,
    this.replyToId,
    this.replyTo,
    this.product,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    // Geçici kullanıcı oluştur (sender null ise)
    User createTempUser(String userId) {
      return User(
        id: userId,
        name: 'Kullanıcı',
        email: '',
        isVerified: false,
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Güvenli string dönüşümü
    String safeString(dynamic value) {
      if (value is String) return value;
      if (value != null) return value.toString();
      return '';
    }

    // Güvenli bool dönüşümü
    bool safeBool(dynamic value, {bool defaultValue = false}) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value != 0;
      return defaultValue;
    }

    // Güvenli Map dönüşümü
    Map<String, dynamic>? safeMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        final Map<String, dynamic> result = {};
        value.forEach((k, v) {
          if (k is String) {
            result[k] = v;
          }
        });
        return result;
      }
      return null;
    }

    return Message(
      id: safeString(json['id']),
      chatId: safeString(json['chatId']),
      senderId: safeString(json['senderId']),
      sender: safeMap(json['sender']) != null 
          ? User.fromJson(safeMap(json['sender'])!)
          : createTempUser(safeString(json['senderId'])),
      content: safeString(json['content']),
      type: MessageType.values.firstWhere(
        (e) => e.name == safeString(json['type']),
        orElse: () => MessageType.text,
      ),
      imageUrl: json['imageUrl'] != null ? safeString(json['imageUrl']) : null,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      isRead: safeBool(json['isRead']),
      isDeleted: safeBool(json['isDeleted']),
      replyToId: json['replyToId'] != null ? safeString(json['replyToId']) : null,
      replyTo: safeMap(json['replyTo']) != null 
          ? Message.fromJson(safeMap(json['replyTo'])!)
          : null,
      product: safeMap(json['product']) != null 
          ? _parseProductFromFirebase(safeMap(json['product'])!)
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  // Firebase'den gelen product verilerini parse et
  static Product _parseProductFromFirebase(Map<String, dynamic> productData) {
    // DateTime'ları güvenli şekilde parse et
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    // Güvenli string dönüşümü
    String safeString(dynamic value) {
      if (value is String) return value;
      if (value != null) return value.toString();
      return '';
    }

    // Güvenli liste dönüşümü
    List<String> safeStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => safeString(e)).toList();
      }
      return [];
    }

    return Product(
      id: safeString(productData['id']),
      title: safeString(productData['title']),
      description: safeString(productData['description']),
      images: safeStringList(productData['images']),
      categoryId: safeString(productData['categoryId']),
      categoryName: safeString(productData['categoryName']),
      category: Category(
        id: safeString(productData['categoryId']),
        name: safeString(productData['categoryName']),
        icon: '',
        isActive: true,
        order: 0,
      ),
      condition: safeString(productData['condition']),
      brand: productData['brand'] != null ? safeString(productData['brand']) : null,
      model: productData['model'] != null ? safeString(productData['model']) : null,
      estimatedValue: (productData['estimatedValue'] as num?)?.toDouble(),
      ownerId: safeString(productData['ownerId']),
      owner: User(
        id: safeString(productData['ownerId']),
        name: safeString(productData['ownerName']),
        email: '',
        isVerified: false,
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tradePreferences: safeStringList(productData['tradePreferences']),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == safeString(productData['status']),
        orElse: () => ProductStatus.active,
      ),
      cityId: safeString(productData['cityId']),
      cityTitle: safeString(productData['cityTitle']),
      districtId: safeString(productData['districtId']),
      districtTitle: safeString(productData['districtTitle']),
      createdAt: parseDateTime(productData['createdAt']),
      updatedAt: parseDateTime(productData['updatedAt']),
    );
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    User? sender,
    String? content,
    MessageType? type,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    bool? isDeleted,
    String? replyToId,
    Message? replyTo,
    Product? product,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      product: product ?? this.product,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, sender: ${sender.name}, content: $content)';
  }
}

enum MessageType {
  text,
  image,
  system,
  tradeOffer,
  tradeAccepted,
  tradeRejected,
  tradeCompleted,
  tradeCancelled,
  product,
} 