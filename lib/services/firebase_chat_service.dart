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
      if (product != null) {
        // Product'ı Firebase uyumlu hale getir
        messageData['product'] = {
          'id': product.id,
          'title': product.title,
          'description': product.description,
          'images': product.images,
          'categoryId': product.categoryId,
          'categoryName': product.categoryName,
          'condition': product.condition,
          'brand': product.brand,
          'model': product.model,
          'estimatedValue': product.estimatedValue,
          'ownerId': product.ownerId,
          'ownerName': product.owner.name,
          'tradePreferences': product.tradePreferences,
          'cityId': product.cityId,
          'cityTitle': product.cityTitle,
          'districtId': product.districtId,
          'districtTitle': product.districtTitle,
          'status': product.status.name,
          'createdAt': product.createdAt.toIso8601String(),
          'updatedAt': product.updatedAt.toIso8601String(),
        };
      }

      await messageRef.set(messageData);
      
      // Son mesajı chat'e güncelle
      await _updateLastMessage(chatId, messageRef.key!, content, type, senderId);
      
      Logger.info('Mesaj gönderildi: $chatId', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj gönderme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Mesajları real-time dinleme (sadece son 50 mesaj)
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _database
        .child('messages/$chatId')
        .orderByChild('timestamp')
        .limitToLast(50) // Sadece son 50 mesajı al
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> messagesMap = 
          event.snapshot.value as Map<dynamic, dynamic>;
      
      final List<Message> messages = [];
      
      messagesMap.forEach((key, value) {
        if (value is Map) {
          // Firebase'den gelen Map<Object?, Object?> tipini Map<String, dynamic>'e dönüştür
          final Map<String, dynamic> messageData = {};
          value.forEach((k, v) {
            if (k is String) {
              messageData[k] = v;
            }
          });
          messageData['id'] = key.toString();
          
          // Timestamp'i DateTime'a çevir
          if (messageData['timestamp'] != null) {
            final timestamp = messageData['timestamp'];
            if (timestamp is int) {
              messageData['createdAt'] = DateTime.fromMillisecondsSinceEpoch(timestamp);
            } else if (timestamp is String) {
              try {
                messageData['createdAt'] = DateTime.parse(timestamp);
              } catch (e) {
                messageData['createdAt'] = DateTime.now();
              }
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
              
              // Son mesaj bilgilerini al
              Message? lastMessage;
              if (chatData['lastMessageId'] != null) {
                try {
                  // Geçici kullanıcı oluştur (sender bilgisi yok)
                  final tempUser = User(
                    id: chatData['lastMessageSenderId'] ?? '',
                    name: 'Kullanıcı',
                    email: '',
                    isVerified: false,
                    isOnline: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  lastMessage = Message(
                    id: chatData['lastMessageId'],
                    chatId: chatData['id'],
                    senderId: chatData['lastMessageSenderId'] ?? '',
                    sender: tempUser,
                    content: chatData['lastMessageContent'] ?? '',
                    type: MessageType.values.firstWhere(
                      (e) => e.name == (chatData['lastMessageType'] ?? 'text'),
                      orElse: () => MessageType.text,
                    ),
                    createdAt: parseChatDateTime(chatData['lastMessageTimestamp'] ?? chatData['updatedAt']),
                    updatedAt: parseChatDateTime(chatData['lastMessageTimestamp'] ?? chatData['updatedAt']),
                    isRead: false,
                    isDeleted: false,
                  );
                } catch (e) {
                  Logger.error('Son mesaj parse hatası: $e', tag: _tag);
                }
              }
              
              final chat = Chat(
                id: chatData['id'],
                tradeId: chatData['tradeId'],
                trade: trade,
                participantIds: participantIds,
                participants: participants,
                lastMessageId: chatData['lastMessageId'],
                lastMessage: lastMessage,
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
    String senderId,
  ) async {
    try {
      await _database.child('chats/$chatId').update({
        'lastMessageId': messageId,
        'lastMessageContent': content,
        'lastMessageType': type.name,
        'lastMessageSenderId': senderId,
        'lastMessageTimestamp': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      Logger.error('Son mesaj güncelleme hatası: $e', tag: _tag);
    }
  }

  // Kullanıcının okunmamış mesaj sayısını real-time dinle
  Stream<int> getUnreadCountStream(String userId) {
    return _database
        .child('messages')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return 0;
      
      final Map<dynamic, dynamic> allMessages = 
          event.snapshot.value as Map<dynamic, dynamic>;
      
      int totalUnreadCount = 0;
      
      allMessages.forEach((chatId, chatMessages) {
        if (chatMessages is Map) {
          chatMessages.forEach((messageId, messageData) {
            if (messageData is Map) {
              final Map<String, dynamic> message = Map<String, dynamic>.from(messageData);
              
              // Mesaj bu kullanıcıya ait değilse ve okunmamışsa say
              if (message['senderId'] != userId && 
                  message['isRead'] != true && 
                  message['isDeleted'] != true) {
                totalUnreadCount++;
              }
            }
          });
        }
      });
      
      Logger.info('Toplam okunmamış mesaj sayısı: $totalUnreadCount', tag: _tag);
      return totalUnreadCount;
    });
  }

  // Belirli bir chat'teki okunmamış mesaj sayısını getir
  Stream<int> getChatUnreadCountStream(String chatId, String userId) {
    return _database
        .child('messages/$chatId')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return 0;
      
      final Map<dynamic, dynamic> messagesMap = 
          event.snapshot.value as Map<dynamic, dynamic>;
      
      int unreadCount = 0;
      
      messagesMap.forEach((messageId, messageData) {
        if (messageData is Map) {
          final Map<String, dynamic> message = Map<String, dynamic>.from(messageData);
          
          // Mesaj bu kullanıcıya ait değilse ve okunmamışsa say
          if (message['senderId'] != userId && 
              message['isRead'] != true && 
              message['isDeleted'] != true) {
            unreadCount++;
          }
        }
      });
      
      return unreadCount;
    });
  }

  // Daha eski mesajları yükle (pagination için)
  Future<List<Message>> loadOlderMessages(String chatId, DateTime beforeTime, {int limit = 20}) async {
    try {
      final snapshot = await _database
          .child('messages/$chatId')
          .orderByChild('timestamp')
          .endAt(beforeTime.millisecondsSinceEpoch)
          .limitToLast(limit)
          .get();
      
      if (snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> messagesMap = 
          snapshot.value as Map<dynamic, dynamic>;
      
      final List<Message> messages = [];
      
      messagesMap.forEach((key, value) {
        if (value is Map) {
          final Map<String, dynamic> messageData = {};
          value.forEach((k, v) {
            if (k is String) {
              messageData[k] = v;
            }
          });
          messageData['id'] = key.toString();
          
          // Timestamp'i DateTime'a çevir
          if (messageData['timestamp'] != null) {
            final timestamp = messageData['timestamp'];
            if (timestamp is int) {
              messageData['createdAt'] = DateTime.fromMillisecondsSinceEpoch(timestamp);
            } else if (timestamp is String) {
              try {
                messageData['createdAt'] = DateTime.parse(timestamp);
              } catch (e) {
                messageData['createdAt'] = DateTime.now();
              }
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
      
      Logger.info('${messages.length} eski mesaj yüklendi', tag: _tag);
      return messages;
    } catch (e) {
      Logger.error('Eski mesaj yükleme hatası: $e', tag: _tag);
      rethrow;
    }
  }
} 