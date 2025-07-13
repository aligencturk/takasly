// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) => Chat(
  id: json['id'] as String,
  tradeId: json['tradeId'] as String,
  trade: Trade.fromJson(json['trade'] as Map<String, dynamic>),
  participantIds: (json['participantIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  participants: (json['participants'] as List<dynamic>)
      .map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastMessageId: json['lastMessageId'] as String?,
  lastMessage: json['lastMessage'] == null
      ? null
      : Message.fromJson(json['lastMessage'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  lastReadTimes: (json['lastReadTimes'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, DateTime.parse(e as String)),
  ),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
  'id': instance.id,
  'tradeId': instance.tradeId,
  'trade': instance.trade,
  'participantIds': instance.participantIds,
  'participants': instance.participants,
  'lastMessageId': instance.lastMessageId,
  'lastMessage': instance.lastMessage,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'lastReadTimes': instance.lastReadTimes.map(
    (k, e) => MapEntry(k, e.toIso8601String()),
  ),
  'isActive': instance.isActive,
};

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  chatId: json['chatId'] as String,
  senderId: json['senderId'] as String,
  sender: User.fromJson(json['sender'] as Map<String, dynamic>),
  content: json['content'] as String,
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  imageUrl: json['imageUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isRead: json['isRead'] as bool,
  isDeleted: json['isDeleted'] as bool,
  replyToId: json['replyToId'] as String?,
  replyTo: json['replyTo'] == null
      ? null
      : Message.fromJson(json['replyTo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'chatId': instance.chatId,
  'senderId': instance.senderId,
  'sender': instance.sender,
  'content': instance.content,
  'type': _$MessageTypeEnumMap[instance.type]!,
  'imageUrl': instance.imageUrl,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isRead': instance.isRead,
  'isDeleted': instance.isDeleted,
  'replyToId': instance.replyToId,
  'replyTo': instance.replyTo,
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.system: 'system',
  MessageType.tradeOffer: 'tradeOffer',
  MessageType.tradeAccepted: 'tradeAccepted',
  MessageType.tradeRejected: 'tradeRejected',
  MessageType.tradeCompleted: 'tradeCompleted',
  MessageType.tradeCancelled: 'tradeCancelled',
};
