// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************



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
  'isPinned': instance.isPinned,
  'deletedBy': instance.deletedBy,
};



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
  'product': instance.product,
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
  MessageType.product: 'product',
};
