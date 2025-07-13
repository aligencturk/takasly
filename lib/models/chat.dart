import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
import 'trade.dart';

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

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
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
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
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
} 