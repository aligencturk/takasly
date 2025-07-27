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
    );
  }
  Map<String, dynamic> toJson() => _$ChatToJson(this);

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
      if (value is String) return DateTime.parse(value);
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

    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      sender: json['sender'] != null 
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : createTempUser(json['senderId'] as String),
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      imageUrl: json['imageUrl'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      isRead: json['isRead'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] != null 
          ? Message.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null 
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$MessageToJson(this);

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