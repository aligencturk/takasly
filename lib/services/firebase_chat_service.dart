import 'package:firebase_database/firebase_database.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../models/trade.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_auth_service.dart';

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
          'catname': product.catname,
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
      await _updateLastMessage(
        chatId,
        messageRef.key!,
        content,
        type,
        senderId,
      );

      // Mesaj geldiğinde bildirim gönder
      await _sendChatNotification(chatId, senderId, content, type);

      Logger.info('Mesaj gönderildi: $chatId', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj gönderme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Chat bildirimi gönder
  Future<void> _sendChatNotification(
    String chatId,
    String senderId,
    String content,
    MessageType type,
  ) async {
    try {
      // Chat bilgilerini al
      final chatSnapshot = await _database.child('chats/$chatId').get();
      if (chatSnapshot.value == null) {
        Logger.warning('⚠️ Chat bulunamadı: $chatId', tag: _tag);
        return;
      }

      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
      final List<String> participantIds = List<String>.from(
        chatData['participantIds'] ?? [],
      );

      // Gönderen hariç diğer katılımcıyı bul (ALICI)
      final String? recipientId = participantIds
          .where((id) => id != senderId)
          .firstOrNull;

      if (recipientId == null) {
        Logger.warning('⚠️ Alıcı bulunamadı: $chatId', tag: _tag);
        return;
      }

      Logger.info('👤 Gönderen ID: $senderId', tag: _tag);
      Logger.info('👥 Alıcı ID: $recipientId', tag: _tag);

      // Gönderen bilgilerini al
      final senderSnapshot = await _database.child('users/$senderId').get();
      if (senderSnapshot.value == null) {
        Logger.warning(
          '⚠️ Gönderen kullanıcı bulunamadı: $senderId',
          tag: _tag,
        );
        return;
      }

      final senderData = Map<String, dynamic>.from(senderSnapshot.value as Map);
      final String senderName = senderData['name'] ?? 'Bilinmeyen Kullanıcı';

      // Mesaj içeriğini kısalt
      String messageContent = content;
      if (type == MessageType.text && content.length > 100) {
        messageContent = '${content.substring(0, 97)}...';
      } else if (type == MessageType.image) {
        messageContent = '📷 Fotoğraf';
      } else if (type == MessageType.product) {
        messageContent = '🛍️ Ürün';
      }

      Logger.info('🔍 Alıcının FCM token\'ı aranıyor: $recipientId', tag: _tag);

      // ALICININ FCM token'ını al (gönderenin değil!)
      final fcmTokenPath = 'users/$recipientId/fcmToken';
      final fcmTokenSnapshot = await _database.child(fcmTokenPath).get();

      // Gönderenin FCM token'ını da kontrol et (debug için)
      final senderFcmTokenPath = 'users/$senderId/fcmToken';
      final senderFcmTokenSnapshot = await _database
          .child(senderFcmTokenPath)
          .get();

      Logger.info('🔍 FCM Token Karşılaştırması:', tag: _tag);
      Logger.info(
        '👤 Gönderen ($senderId) FCM token: ${senderFcmTokenSnapshot.value?.toString().substring(0, 20) ?? 'null'}...',
        tag: _tag,
      );
      Logger.info(
        '👥 Alıcı ($recipientId) FCM token: ${fcmTokenSnapshot.value?.toString().substring(0, 20) ?? 'null'}...',
        tag: _tag,
      );

      if (fcmTokenSnapshot.value != null) {
        // Yeni yapı: tokenData objesi içinde token var
        final tokenData = fcmTokenSnapshot.value;
        String fcmToken;

        if (tokenData is Map) {
          // Yeni yapı: {token: "...", deviceInfo: "...", lastUpdated: ...}
          fcmToken = tokenData['token']?.toString() ?? '';
          final deviceInfo = tokenData['deviceInfo']?.toString() ?? 'unknown';
          Logger.info('📱 Alıcı cihaz bilgisi: $deviceInfo', tag: _tag);
        } else {
          // Eski yapı: direkt string token
          fcmToken = tokenData.toString();
          Logger.info('📱 Alıcı eski token formatında', tag: _tag);
        }

        // FCM token validasyonu
        if (fcmToken.isEmpty || fcmToken.length < 100) {
          Logger.warning(
            '⚠️ Geçersiz FCM token uzunluğu: ${fcmToken.length}',
            tag: _tag,
          );
          // Geçersiz token'ı sil ve yenilemeye çalış
          await _database.child(fcmTokenPath).remove();
          Logger.info(
            '🔄 Geçersiz FCM token silindi, yenileme deneniyor...',
            tag: _tag,
          );
        } else {
          Logger.info(
            '✅ Alıcının FCM token\'ı bulundu: ${fcmToken.substring(0, 20)}...',
            tag: _tag,
          );

          // Gönderen token'ını da yeni yapıya göre oku
          String senderFcmToken = '';
          if (senderFcmTokenSnapshot.value != null) {
            final senderTokenData = senderFcmTokenSnapshot.value;
            if (senderTokenData is Map) {
              senderFcmToken = senderTokenData['token']?.toString() ?? '';
            } else {
              senderFcmToken = senderTokenData.toString();
            }
          }

          // Token'lar aynı mı kontrol et
          if (senderFcmToken.isNotEmpty && senderFcmToken == fcmToken) {
            Logger.warning(
              '⚠️ DİKKAT: Gönderen ve alıcının FCM token\'ları aynı!',
              tag: _tag,
            );
            Logger.warning(
              '⚠️ Bu, aynı cihazda iki farklı kullanıcı giriş yapıldığı anlamına gelebilir',
              tag: _tag,
            );
            Logger.info(
              '🔍 DEBUG: Gönderen token: ${senderFcmToken.substring(0, 20)}...',
              tag: _tag,
            );
            Logger.info(
              '🔍 DEBUG: Alıcı token: ${fcmToken.substring(0, 20)}...',
              tag: _tag,
            );

            // Aynı token'ları temizle ve yeniden oluştur
            Logger.info(
              '🔄 Aynı FCM token\'lar temizleniyor ve yeniden oluşturuluyor...',
              tag: _tag,
            );

            try {
              // NotificationService'den yeni token al
              final notificationService = NotificationService.instance;
              final newToken = await notificationService.getFCMToken();

              if (newToken != null && newToken.isNotEmpty) {
                Logger.info(
                  '⚠️ Aynı FCM token tespit edildi, her iki kullanıcının da token\'ı temizleniyor...',
                  tag: _tag,
                );

                // HER İKİ kullanıcının da token'ını temizle
                await _database.child(fcmTokenPath).remove(); // Alıcı
                await _database.child(senderFcmTokenPath).remove(); // Gönderen

                Logger.info(
                  '✅ Her iki kullanıcının FCM token\'ı temizlendi',
                  tag: _tag,
                );
                Logger.info(
                  '👤 Gönderen token temizlendi: $senderId',
                  tag: _tag,
                );
                Logger.info(
                  '👥 Alıcı token temizlendi: $recipientId',
                  tag: _tag,
                );

                // Bildirim gönderilemeyecek çünkü her iki kullanıcının da token\'ı yok
                Logger.warning(
                  '⚠️ Her iki kullanıcının da FCM token\'ı temizlendi, bildirim gönderilemedi',
                  tag: _tag,
                );
                Logger.warning(
                  '💡 Her iki kullanıcı da uygulamayı açtığında yeni benzersiz FCM token\'lar kaydedilecek',
                  tag: _tag,
                );

                // CRITICAL: Burada kesinlikle çıkılmalı!
                Logger.info(
                  '🛑 Aynı token nedeniyle bildirim gönderimi durduruldu',
                  tag: _tag,
                );
                Logger.info(
                  '🔍 DEBUG: return statement çalıştırılıyor...',
                  tag: _tag,
                );
                return; // Bildirim gönderilemedi, çık
              }
            } catch (tokenError) {
              Logger.error('❌ Token temizleme hatası: $tokenError', tag: _tag);
              // Hata durumunda da çık
              Logger.warning(
                '🛑 Token temizleme hatası nedeniyle bildirim gönderimi durduruldu',
                tag: _tag,
              );
              Logger.info(
                '🔍 DEBUG: Token temizleme hatası sonrası return çalıştırılıyor...',
                tag: _tag,
              );
              return;
            }

            // Eğer yukarıdaki return'lar çalışmadıysa, burada da çık
            Logger.warning(
              '🛑 Aynı token nedeniyle bildirim gönderimi durduruldu (fallback)',
              tag: _tag,
            );
            Logger.info(
              '🔍 DEBUG: Fallback return statement çalıştırılıyor...',
              tag: _tag,
            );
            return;
          }

          // Eğer buraya kadar geldiyse, token'lar farklı demektir
          Logger.info(
            '✅ Token\'lar farklı, bildirim gönderimi devam ediyor...',
            tag: _tag,
          );

          // SON KONTROL: Token hala geçerli mi?
          if (fcmToken.isEmpty || fcmToken.length < 100) {
            Logger.error(
              '❌ CRITICAL: FCM token geçersiz hale geldi!',
              tag: _tag,
            );
            Logger.error('📏 Token uzunluğu: ${fcmToken.length}', tag: _tag);
            Logger.error('🔑 Token: $fcmToken', tag: _tag);
            return;
          }

          Logger.info('🔍 SON KONTROL: FCM token geçerli', tag: _tag);
          Logger.info('📏 Token uzunluğu: ${fcmToken.length}', tag: _tag);
          Logger.info('🔑 Token: ${fcmToken.substring(0, 30)}...', tag: _tag);

          // Cloud Function'a bildirim gönder (ALICIYA!)
          await _sendFCMNotificationToCloudFunction(
            fcmToken: fcmToken,
            title: 'Yeni Mesaj - $senderName',
            body: messageContent,
            recipientId: recipientId, // ALICI ID
            chatId: chatId,
            senderId: senderId, // GÖNDEREN ID
          );

          Logger.info(
            '✅ FCM chat bildirimi ALICIYA gönderildi: $recipientId',
            tag: _tag,
          );
          return; // Başarılı, çık
        }
      }

      // FCM token bulunamadı veya geçersiz, yenilemeye çalış
      Logger.warning(
        '⚠️ Alıcının FCM token\'ı bulunamadı veya geçersiz: $fcmTokenPath',
        tag: _tag,
      );
      Logger.info('🔄 FCM token yenileme deneniyor...', tag: _tag);

      // Burada alıcının token'ını yenilemeye çalışamayız çünkü
      // alıcı farklı cihazda olabilir. Sadece log yazalım.
      Logger.error(
        '❌ Alıcının FCM token\'ı bulunamadı, bildirim gönderilemedi: $recipientId',
        tag: _tag,
      );
      Logger.error(
        '💡 Alıcı uygulamayı açtığında FCM token otomatik olarak kaydedilecek',
        tag: _tag,
      );
    } catch (e) {
      Logger.error('❌ FCM chat bildirimi hatası: $e', error: e, tag: _tag);
    }
  }

  // FCM ile chat bildirimi gönder - ESKİ METOD, KALDIRILDI
  // Artık _sendChatNotification metodu kullanılıyor
  // Bu metod kaldırıldı çünkü duplicate kod ve karışıklık yaratıyordu

  // Cloud Functions ile FCM bildirimi gönder
  Future<void> _sendFCMNotificationToCloudFunction({
    required String fcmToken,
    required String title,
    required String body,
    required String recipientId,
    required String chatId,
    required String senderId,
    Map<String, dynamic>? data,
  }) async {
    try {
      Logger.info('🚀 FCM bildirimi gönderiliyor...', tag: _tag);
      Logger.info('👤 Gönderen ID: $senderId', tag: _tag);
      Logger.info('👥 Alıcı ID: $recipientId', tag: _tag);
      Logger.info(
        '🔑 Kullanılan FCM token: ${fcmToken.substring(0, 20)}...',
        tag: _tag,
      );
      Logger.info('📝 Token uzunluğu: ${fcmToken.length}', tag: _tag);

      // FCM token validasyonu
      if (fcmToken.isEmpty || fcmToken.length < 100) {
        Logger.warning(
          '⚠️ Geçersiz FCM token: ${fcmToken.length} karakter',
          tag: _tag,
        );
        return;
      }

      Logger.info(
        '🔍 FCM token validasyonu geçti: ${fcmToken.substring(0, 20)}...',
        tag: _tag,
      );

      // Firebase Auth token'ını al
      final firebaseAuthService = FirebaseAuthService();
      final authToken = await firebaseAuthService.getIdToken();

      if (authToken == null) {
        Logger.warning(
          '⚠️ Firebase Auth token alınamadı, auth olmadan devam ediliyor...',
          tag: _tag,
        );
        // Auth token olmadan devam et, Cloud Function'da auth kontrolü yapılacak
      } else {
        Logger.info(
          '🔐 Firebase Auth token alındı: ${authToken.substring(0, 20)}...',
          tag: _tag,
        );
      }

      // Cloud Functions'ı çağır
      final functions = FirebaseFunctions.instance;

      // Cloud Function parametreleri
      final Map<String, dynamic> notificationData = {
        'recipientId': recipientId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'chatId': chatId,
        'senderId': senderId,
        'messageType': 'chat_message',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      Logger.info('📤 Cloud Function çağrılıyor...', tag: _tag);
      Logger.info('📋 Gönderilen veriler:', tag: _tag);
      Logger.info('   👥 recipientId: $recipientId', tag: _tag);
      Logger.info('   🔑 fcmToken: ${fcmToken.substring(0, 20)}...', tag: _tag);
      Logger.info('   👤 senderId: $senderId', tag: _tag);

      // Cloud Function'ı çağır (auth token ile)
      final result = await functions
          .httpsCallable('sendChatNotification')
          .call(notificationData);

      Logger.info('✅ Cloud Function başarılı: ${result.data}', tag: _tag);
      Logger.info('🎯 FCM bildirimi başarıyla gönderildi!', tag: _tag);
      Logger.info('👥 Alıcı ID: $recipientId', tag: _tag);
      Logger.info(
        '🔑 Kullanılan token: ${fcmToken.substring(0, 20)}...',
        tag: _tag,
      );
    } catch (e) {
      Logger.error('❌ Cloud Function hatası: $e', tag: _tag);

      // Hata tipine göre özel işlemler
      if (e.toString().contains('FCM token geçersiz')) {
        Logger.warning(
          '⚠️ FCM token geçersiz, kullanıcıya bildirim gönderilemiyor',
          tag: _tag,
        );
        // Bu durumda kullanıcının FCM token'ını yenilemesi gerekebilir
        return;
      }

      if (e.toString().contains('FCM token kayıtlı değil')) {
        Logger.warning(
          '⚠️ FCM token kayıtlı değil, kullanıcıya bildirim gönderilemiyor',
          tag: _tag,
        );
        return;
      }

      // FALLBACK KALDIRILDI: Local notification gösterilmeyecek
      Logger.warning(
        '⚠️ Cloud Function hatası nedeniyle bildirim gönderilemedi',
        tag: _tag,
      );
      Logger.warning(
        '💡 Local notification gösterilmeyecek (kullanıcı isteği)',
        tag: _tag,
      );
      Logger.warning('🔍 Hata detayı: $e', tag: _tag);
    }
  }

  // FCM token'ı test et
  Future<void> testFCMToken(String userId) async {
    try {
      Logger.info('🧪 FCM token test başlatılıyor...', tag: _tag);

      // Firebase'den FCM token'ı al
      final fcmTokenPath = 'users/$userId/fcmToken';
      final fcmTokenSnapshot = await _database.child(fcmTokenPath).get();

      if (fcmTokenSnapshot.value != null) {
        final fcmToken = fcmTokenSnapshot.value.toString();
        Logger.info(
          '✅ Firebase\'de FCM token bulundu: ${fcmToken.substring(0, 20)}...',
          tag: _tag,
        );
        Logger.info('📏 Token uzunluğu: ${fcmToken.length}', tag: _tag);

        // Token formatını kontrol et
        if (fcmToken.length < 100) {
          Logger.warning('⚠️ FCM token çok kısa, geçersiz olabilir', tag: _tag);
        }

        Logger.info('✅ FCM token test başarılı', tag: _tag);
      } else {
        Logger.warning(
          '⚠️ Firebase\'de FCM token bulunamadı: $fcmTokenPath',
          tag: _tag,
        );

        // NotificationService'den token almayı dene
        final notificationService = NotificationService.instance;
        final localToken = await notificationService.getFCMToken();

        if (localToken != null && localToken.isNotEmpty) {
          Logger.info(
            '✅ Local FCM token bulundu: ${localToken.substring(0, 20)}...',
            tag: _tag,
          );
          Logger.info(
            '📏 Local token uzunluğu: ${localToken.length}',
            tag: _tag,
          );

          // Local token'ı Firebase'e kaydet
          await _database.child(fcmTokenPath).set(localToken);
          Logger.info('✅ Local FCM token Firebase\'e kaydedildi', tag: _tag);

          Logger.info('✅ FCM token test ve yenileme başarılı', tag: _tag);
        } else {
          Logger.error('❌ Local FCM token da bulunamadı', tag: _tag);
        }
      }
    } catch (e) {
      Logger.error('❌ FCM token test hatası: $e', error: e, tag: _tag);
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
                  messageData['createdAt'] =
                      DateTime.fromMillisecondsSinceEpoch(timestamp);
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
      await _database.child('messages/$chatId/$messageId/isRead').set(true);

      Logger.info('Mesaj okundu olarak işaretlendi: $messageId', tag: _tag);
    } catch (e) {
      Logger.error('Mesaj okundu işaretleme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Mesajı sil (soft delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _database.child('messages/$chatId/$messageId/isDeleted').set(true);

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
      Logger.info(
        'Chat oluşturma isteği: tradeId=$tradeId, participants=$participantIds',
        tag: _tag,
      );

      // Tüm chat'leri al ve client-side filtrele
      final allChatsSnapshot = await _database.child('chats').get();

      if (allChatsSnapshot.value != null) {
        final allChats = allChatsSnapshot.value as Map<dynamic, dynamic>;
        Logger.info('Mevcut chat sayısı: ${allChats.length}', tag: _tag);

        // Aynı trade ve katılımcılara sahip chat var mı kontrol et
        for (final entry in allChats.entries) {
          final chatData = Map<String, dynamic>.from(entry.value as Map);
          final chatTradeId = chatData['tradeId'] as String?;
          final chatParticipantIds = List<String>.from(
            chatData['participantIds'] ?? [],
          );

          Logger.debug(
            'Chat kontrol: ${entry.key} - tradeId=$chatTradeId, participants=$chatParticipantIds',
            tag: _tag,
          );

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
      Logger.info('Yeni chat oluşturuluyor...', tag: _tag);
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
    Logger.info(
      'FirebaseChatService: Chat stream başlatılıyor... userId=$userId',
      tag: _tag,
    );

    return _database.child('chats').orderByChild('updatedAt').onValue.asyncMap((
      event,
    ) async {
      if (event.snapshot.value == null) {
        Logger.info('FirebaseChatService: Hiç chat bulunamadı', tag: _tag);
        return [];
      }

      final Map<dynamic, dynamic> chatsMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      Logger.info(
        'FirebaseChatService: ${chatsMap.length} chat Firebase\'den alındı',
        tag: _tag,
      );

      final List<Chat> chats = [];

      for (final entry in chatsMap.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is Map<dynamic, dynamic>) {
          final chatData = Map<String, dynamic>.from(value);
          chatData['id'] = key;

          // Sadece kullanıcının katıldığı chat'leri filtrele
          final List<String> participantIds = List<String>.from(
            chatData['participantIds'] ?? [],
          );

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
                if (value is int)
                  return DateTime.fromMillisecondsSinceEpoch(value);
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
                    createdAt: parseChatDateTime(
                      chatData['lastMessageTimestamp'] ?? chatData['updatedAt'],
                    ),
                    updatedAt: parseChatDateTime(
                      chatData['lastMessageTimestamp'] ?? chatData['updatedAt'],
                    ),
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
                isPinned: chatData['isPinned'] ?? false,
                deletedBy:
                    (chatData['deletedBy'] as List<dynamic>?)
                        ?.map((e) => e as String)
                        .toList() ??
                    [],
              );

              // Kullanıcının silmediği chat'leri filtrele
              if (!chat.deletedBy.contains(userId)) {
                // Tüm chat'leri ekle (son mesaj kontrolü kaldırıldı)
                chats.add(chat);
              } else {}
            } catch (e) {
              Logger.error('Chat parse hatası: $e', tag: _tag);
            }
          } else {}
        }
      }

      // Son güncelleme zamanına göre sırala
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      Logger.info(
        'FirebaseChatService: ${chats.length} chat döndürülüyor',
        tag: _tag,
      );
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
    return _database.child('messages').onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final Map<dynamic, dynamic> allMessages =
          event.snapshot.value as Map<dynamic, dynamic>;

      int totalUnreadCount = 0;

      allMessages.forEach((chatId, chatMessages) {
        if (chatMessages is Map) {
          chatMessages.forEach((messageId, messageData) {
            if (messageData is Map) {
              final Map<String, dynamic> message = Map<String, dynamic>.from(
                messageData,
              );

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

      Logger.info(
        'Toplam okunmamış mesaj sayısı: $totalUnreadCount',
        tag: _tag,
      );
      return totalUnreadCount;
    });
  }

  // Belirli bir chat'teki okunmamış mesaj sayısını getir
  Stream<int> getChatUnreadCountStream(String chatId, String userId) {
    return _database.child('messages/$chatId').onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final Map<dynamic, dynamic> messagesMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      int unreadCount = 0;

      messagesMap.forEach((messageId, messageData) {
        if (messageData is Map) {
          final Map<String, dynamic> message = Map<String, dynamic>.from(
            messageData,
          );

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
  Future<List<Message>> loadOlderMessages(
    String chatId,
    DateTime beforeTime, {
    int limit = 20,
  }) async {
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
              messageData['createdAt'] = DateTime.fromMillisecondsSinceEpoch(
                timestamp,
              );
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

  // Chat silme
  Future<void> deleteChat(String chatId) async {
    try {
      // Chat'i sil
      await _database.child('chats/$chatId').remove();
      // Mesajları sil
      await _database.child('messages/$chatId').remove();
      Logger.info('Chat ve mesajları silindi: $chatId', tag: _tag);
    } catch (e) {
      Logger.error('Chat silme hatası: $e', tag: _tag);
      rethrow;
    }
  }

  // Chat deletedBy listesini güncelle
  Future<void> updateChatDeletedBy(
    String chatId,
    List<String> deletedBy,
  ) async {
    try {
      Logger.info(
        'FirebaseChatService: Chat deletedBy güncelleniyor - chatId=$chatId, deletedBy=$deletedBy',
        tag: _tag,
      );

      await _database.child('chats/$chatId/deletedBy').set(deletedBy);

      Logger.info(
        'FirebaseChatService: Chat deletedBy başarıyla güncellendi - chatId=$chatId',
        tag: _tag,
      );
    } catch (e) {
      Logger.error(
        'FirebaseChatService: Chat deletedBy güncelleme hatası: $e',
        tag: _tag,
      );
      rethrow;
    }
  }

  // Chat'i id ile getir
  Future<Chat?> getChatById(String chatId) async {
    try {
      final snapshot = await _database.child('chats/$chatId').get();
      if (snapshot.value != null) {
        final chatData = Map<String, dynamic>.from(snapshot.value as Map);
        chatData['id'] = chatId;
        // Katılımcı kullanıcıları getir
        final List<String> participantIds = List<String>.from(
          chatData['participantIds'] ?? [],
        );
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
        DateTime parseChatDateTime(dynamic value) {
          if (value is DateTime) return value;
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          if (value is String)
            return DateTime.tryParse(value) ?? DateTime.now();
          return DateTime.now();
        }

        final chat = Chat(
          id: chatData['id'],
          tradeId: chatData['tradeId'],
          trade: trade,
          participantIds: participantIds,
          participants: participants,
          lastMessageId: chatData['lastMessageId'],
          lastMessage: null, // Detaylı mesajı ayrıca çekmek gerekebilir
          createdAt: parseChatDateTime(chatData['createdAt']),
          updatedAt: parseChatDateTime(chatData['updatedAt']),
          lastReadTimes: {},
          isActive: chatData['isActive'] ?? true,
          isPinned: chatData['isPinned'] ?? false,
          deletedBy:
              (chatData['deletedBy'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
        );
        return chat;
      }
      return null;
    } catch (e) {
      Logger.error('getChatById hatası: $e', tag: _tag);
      return null;
    }
  }
}
