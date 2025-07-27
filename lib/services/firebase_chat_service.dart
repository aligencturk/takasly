import 'package:firebase_database/firebase_database.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../models/trade.dart';
import '../models/product.dart';
import '../utils/logger.dart';

class FirebaseChatService {
  static const String _tag = 'FirebaseChatService';
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Mesaj gönderme
  Future<void> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? replyToId,
    Product? product,
  }) async {
    try {
      final messageRef = _database.child('messages/$chatId').push();
      final messageData = {
        'id': messageRef.key,
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'type': type.name,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'isDeleted': false,
      };

      if (imageUrl != null) messageData['imageUrl'] = imageUrl;
      if (replyToId != null) messageData['replyToId'] = replyToId;
      if (product != null) messageData['product'] = product.toJson();

      await messageRef.set(messageData);
      
      // Son mesajı chat'e güncelle
      await _updateLastMessage(chatId, messageRef.key!, content, type);
      
      Logger.info('Mesaj gönderildi: $chatId', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj gönderme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Mesajları real-time dinleme
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _database
        .child('messages/$chatId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> messagesMap = 
          event.snapshot.value as Map<dynamic, dynamic>;
      
      final List<Message> messages = [];
      
      messagesMap.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          final messageData = Map<String, dynamic>.from(value);
          messageData['id'] = key;
          
          // Timestamp'i DateTime'a çevir
          if (messageData['timestamp'] != null) {
            final timestamp = messageData['timestamp'];
            if (timestamp is int) {
              messageData['createdAt'] = DateTime.fromMillisecondsSinceEpoch(timestamp);
            } else if (timestamp is String) {
              messageData['createdAt'] = DateTime.parse(timestamp);
            } else {
              messageData['createdAt'] = DateTime.now();
            }
            messageData['updatedAt'] = messageData['createdAt'];
          } else {
            messageData['createdAt'] = DateTime.now();
            messageData['updatedAt'] = DateTime.now();
          }
          
          try {
            final message = Message.fromJson(messageData);
            if (!message.isDeleted) {
              messages.add(message);
            }
          } catch (e) {
            Logger.error('Mesaj parse hatası: $e', tag: _tag);
          }
        }
      });
      
      // Timestamp'e göre sırala
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return messages;
    });
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _database
          .child('messages/$chatId/$messageId/isRead')
          .set(true);
      
      Logger.info('Mesaj okundu olarak işaretlendi: $messageId', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj okundu işaretleme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Mesajı sil (soft delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _database
          .child('messages/$chatId/$messageId/isDeleted')
          .set(true);
      
      Logger.info('Mesaj silindi: $messageId', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj silme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Chat oluştur veya mevcut olanı bul
  Future<String> createChat({
    required String tradeId,
    required List<String> participantIds,
  }) async {
    try {
      // Tüm chat'leri al ve client-side filtrele
      final allChatsSnapshot = await _database.child('chats').get();
      
      if (allChatsSnapshot.value != null) {
        final allChats = allChatsSnapshot.value as Map<dynamic, dynamic>;
        
        // Aynı trade ve katılımcılara sahip chat var mı kontrol et
        for (final entry in allChats.entries) {
          final chatData = Map<String, dynamic>.from(entry.value as Map);
          final chatTradeId = chatData['tradeId'] as String?;
          final chatParticipantIds = List<String>.from(chatData['participantIds'] ?? []);
          
          // Trade ID ve katılımcı listesi aynı mı kontrol et
          if (chatTradeId == tradeId &&
              chatParticipantIds.length == participantIds.length &&
              chatParticipantIds.every((id) => participantIds.contains(id))) {
            Logger.info('Mevcut chat bulundu: ${entry.key}', tag: _tag);
            return entry.key as String;
          }
        }
      }
      
      // Mevcut chat yoksa yeni oluştur
      final chatRef = _database.child('chats').push();
      final chatId = chatRef.key!;
      
      final chatData = {
        'id': chatId,
        'tradeId': tradeId,
        'participantIds': participantIds,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'isActive': true,
      };
      
      await chatRef.set(chatData);
      
      Logger.info('Yeni chat oluşturuldu: $chatId', tag: _tag);
      return chatId;
    } catch (e) {
      Logger.error('Chat oluşturma hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Kullanıcı bilgilerini getir
  Future<User?> getUserById(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').get();
      if (snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        userData['id'] = userId;
        
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      Logger.error('Kullanıcı getirme hatası: $e', tag: _tag);
      return null;
    }
  }

  // Kullanıcı kaydet/güncelle
  Future<void> saveUser(User user) async {
    try {
      final userData = user.toJson();
      userData['createdAt'] = user.createdAt.millisecondsSinceEpoch;
      userData['updatedAt'] = user.updatedAt.millisecondsSinceEpoch;
      
      await _database.child('users/${user.id}').set(userData);
      
      Logger.info('Kullanıcı kaydedildi: ${user.id}', tag: _tag);
    } catch (e) {
      Logger.error('Kullanıcı kaydetme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Chat'leri getir
  Stream<List<Chat>> getChatsStream(String userId) {
    return _database
        .child('chats')
        .orderByChild('updatedAt')
        .onValue
        .asyncMap((event) async {
      if (event.snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> chatsMap = 
          event.snapshot.value as Map<dynamic, dynamic>;
      
      final List<Chat> chats = [];
      
      for (final entry in chatsMap.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is Map<dynamic, dynamic>) {
          final chatData = Map<String, dynamic>.from(value);
          chatData['id'] = key;
          

          
          // Sadece kullanıcının katıldığı chat'leri filtrele
          final List<String> participantIds = 
              List<String>.from(chatData['participantIds'] ?? []);
          
          if (participantIds.contains(userId)) {
            try {
              // Kullanıcı bilgilerini getir
              final List<User> participants = [];
              for (final participantId in participantIds) {
                final user = await getUserById(participantId);
                if (user != null) {
                  participants.add(user);
                }
              }
              
              // Geçici Trade objesi oluştur
              final emptyUser = User(
                id: '',
                name: '',
                email: '',
                isVerified: false,
                isOnline: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              final trade = Trade(
                id: chatData['tradeId'],
                offererUserId: '',
                offererUser: emptyUser,
                receiverUserId: '',
                receiverUser: emptyUser,
                offeredProductIds: [],
                offeredProducts: [],
                requestedProductIds: [],
                requestedProducts: [],
                status: TradeStatus.pending,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              // DateTime'ları manuel olarak parse et
              DateTime parseChatDateTime(dynamic value) {
                if (value is DateTime) return value;
                if (value is String) return DateTime.parse(value);
                if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
                return DateTime.now();
              }
              
              final chat = Chat(
                id: chatData['id'],
                tradeId: chatData['tradeId'],
                trade: trade,
                participantIds: participantIds,
                participants: participants,
                createdAt: parseChatDateTime(chatData['createdAt']),
                updatedAt: parseChatDateTime(chatData['updatedAt']),
                lastReadTimes: {},
                isActive: chatData['isActive'] ?? true,
              );
              
              chats.add(chat);
            } catch (e) {
              Logger.error('Chat parse hatası: $e', tag: _tag);
            }
          }
        }
      }
      
      // Son güncelleme zamanına göre sırala
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return chats;
    });
  }

  // Son mesajı güncelle
  Future<void> _updateLastMessage(
    String chatId, 
    String messageId, 
    String content, 
    MessageType type,
  ) async {
    try {
      await _database.child('chats/$chatId').update({
        'lastMessageId': messageId,
        'lastMessageContent': content,
        'lastMessageType': type.name,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      Logger.error('Son mesaj güncelleme hatası: $e', tag: _tag);
    }
  }

  // Okunmamış mesaj sayısını getir
  Stream<int> getUnreadCountStream(String userId) {
    return _database
        .child('messages')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return 0;
      
      int unreadCount = 0;
      final Map<dynamic, dynamic> messagesMap = 
          event.snapshot.value as Map<dynamic, dynamic>;
      
      messagesMap.forEach((chatId, chatMessages) {
        if (chatMessages is Map<dynamic, dynamic>) {
          chatMessages.forEach((messageId, messageData) {
            if (messageData is Map<dynamic, dynamic>) {
              final message = Map<String, dynamic>.from(messageData);
              
              // Kendi mesajlarını sayma ve silinmemiş mesajları kontrol et
              if (message['senderId'] != userId && 
                  message['isRead'] == false && 
                  message['isDeleted'] != true) {
                unreadCount++;
              }
            }
          });
        }
      });
      
      return unreadCount;
    });
  }
} 