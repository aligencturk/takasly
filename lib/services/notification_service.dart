import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as perm;
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/notification.dart';
import '../utils/logger.dart';

class NotificationService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'NotificationService';
  static const String _fcmApiUrl = 'https://fcm.googleapis.com/v1/projects/takasla-b2aa5/messages:send';
  
  // FCM instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Kullanıcının bildirimlerini alır
  /// GET /service/user/account/{userId}/notifications
  Future<ApiResponse<List<Notification>>> getNotifications({
    required String userToken,
    required int userId,
  }) async {
    try {
      Logger.debug('GET NOTIFICATIONS', tag: _tag);
      Logger.debug('User ID: $userId, User Token: ${userToken.substring(0, 20)}...', tag: _tag);

      final response = await _httpClient.getWithBasicAuth(
        '${ApiConstants.userProfileDetail}/$userId/notifications?userToken=$userToken',
        fromJson: (json) {
          Logger.debug('Get Notifications fromJson - Raw data: $json', tag: _tag);

          // Response formatını kontrol et
          if (json is Map<String, dynamic>) {
            // Eğer data field'ı içinde notifications varsa
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              Logger.debug('Get Notifications - Data field format detected', tag: _tag);
              final dataField = json['data'] as Map<String, dynamic>;
              
              // Token güncelleme kontrolü
              if (dataField.containsKey('token') && dataField['token'] != null && dataField['token'].toString().isNotEmpty) {
                final newToken = dataField['token'].toString();
                Logger.debug('Get Notifications - Data field içinde yeni token bulundu: ${newToken.substring(0, 20)}...', tag: _tag);
                _updateTokenInBackground(newToken);
              }
              
              // Notifications array'ini kontrol et
              if (dataField.containsKey('notifications') && dataField['notifications'] is List) {
                final notificationsList = dataField['notifications'] as List;
                Logger.debug('Get Notifications - Found ${notificationsList.length} notifications', tag: _tag);
                
                return notificationsList
                    .map((notificationJson) => Notification.fromJson(notificationJson))
                    .toList();
              } else {
                Logger.warning('Get Notifications - No notifications array found in data field', tag: _tag);
                return <Notification>[];
              }
            }
            // Eğer direkt notifications array'i gelirse
            else if (json.containsKey('notifications') && json['notifications'] is List) {
              Logger.debug('Get Notifications - Direct notifications array format detected', tag: _tag);
              final notificationsList = json['notifications'] as List;
              
              return notificationsList
                  .map((notificationJson) => Notification.fromJson(notificationJson))
                  .toList();
            } else {
              Logger.warning('Get Notifications - Unexpected response format', tag: _tag);
              Logger.warning('Get Notifications - Available keys: ${json.keys.toList()}', tag: _tag);
              return <Notification>[];
            }
          }

          Logger.warning('Get Notifications - Invalid response format', tag: _tag);
          return <Notification>[];
        },
      );

      Logger.debug('✅ Get Notifications Response: ${response.isSuccess}', tag: _tag);
      Logger.debug('🔍 Response Data Count: ${response.data?.length ?? 0}', tag: _tag);
      Logger.debug('🔍 Response Error: ${response.error}', tag: _tag);

      return response;
    } catch (e) {
      Logger.error('❌ Get Notifications Error: $e', tag: _tag);
      return ApiResponse<List<Notification>>.error(ErrorMessages.unknownError);
    }
  }

  /// Token'ı arka planda günceller (async olarak)
  void _updateTokenInBackground(String newToken) {
    // Arka planda token güncelleme işlemini başlat
    Future.microtask(() async {
      try {
        if (newToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final currentToken = prefs.getString(AppConstants.userTokenKey);
          
          // Token farklıysa veya yoksa güncelle
          if (currentToken != newToken) {
            Logger.debug('🔄 NotificationService - Token güncelleniyor: ${newToken.substring(0, 20)}...', tag: _tag);
            await prefs.setString(AppConstants.userTokenKey, newToken);
            Logger.debug('✅ NotificationService - Token başarıyla güncellendi', tag: _tag);
          } else {
            Logger.debug('ℹ️ NotificationService - Token zaten güncel, güncelleme gerekmiyor', tag: _tag);
          }
        } else {
          Logger.warning('⚠️ NotificationService - Boş token, güncelleme yapılmadı', tag: _tag);
        }
      } catch (e) {
        Logger.error('❌ NotificationService - Token güncelleme hatası: $e', tag: _tag);
      }
    });
  }

  /// FCM Token'ını alır
  Future<String?> getFCMToken() async {
    try {
      Logger.debug('Getting FCM token...', tag: _tag);
      
      // iOS'ta APNS token hazır olmadan FCM token alınamaz.
      // APNS token'ı beklemek için küçük bir retry mekaniği ekleyelim.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          // Auto init aktif olsun
          await _firebaseMessaging.setAutoInitEnabled(true);
          
          const int maxAttempts = 15; // ~7.5 saniye bekleme (15 x 500ms)
          String? apnsToken;
          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null && apnsToken.isNotEmpty) {
              Logger.debug('✅ APNS token hazır: ${apnsToken.substring(0, 12)}...', tag: _tag);
              break;
            }
            Logger.debug('⏳ APNS token bekleniyor... ($attempt/$maxAttempts)', tag: _tag);
            await Future.delayed(const Duration(milliseconds: 500));
          }
          if (apnsToken == null || apnsToken.isEmpty) {
            Logger.warning('⚠️ APNS token halen hazır değil, FCM token alınamayabilir', tag: _tag);
            Logger.info('🔄 iOS simülatör: APNS token olmadan FCM token deneniyor...', tag: _tag);
          }
        } catch (e) {
          Logger.warning('⚠️ APNS token hazırlama hatası: $e', tag: _tag);
        }
      }

      String? token;
      try {
        token = await _firebaseMessaging.getToken();
      } catch (e) {
        Logger.error('❌ FCM Token alma hatası: $e', tag: _tag);
        
        // iOS simülatör için alternatif deneme
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          Logger.info('🔄 iOS simülatör: Alternatif FCM token alma deneniyor...', tag: _tag);
          await Future.delayed(const Duration(seconds: 2));
          try {
            token = await _firebaseMessaging.getToken();
            Logger.info('✅ Alternatif deneme başarılı!', tag: _tag);
          } catch (e2) {
            Logger.error('❌ Alternatif deneme de başarısız: $e2', tag: _tag);
            return null;
          }
        } else {
          return null;
        }
      }
      
      if (token != null) {
        Logger.info('✅ FCM Token alındı: $token', tag: _tag);
        
        // Token'ı SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        
        return token;
      } else {
        Logger.warning('⚠️ FCM Token alınamadı', tag: _tag);
        return null;
      }
    } catch (e) {
      Logger.error('❌ FCM Token alma hatası: $e', tag: _tag);
      return null;
    }
  }

  /// Topic'e abone ol
  Future<bool> subscribeToTopic(String userId) async {
    try {
      Logger.debug('Topic\'e abone olunuyor: $userId', tag: _tag);
      
      // FCM token'ın hazır olduğundan emin ol
      String? fcmToken = await getFCMToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        Logger.warning('⚠️ FCM token bulunamadı, topic aboneliği yapılamıyor', tag: _tag);
        return false;
      }
      
      Logger.debug('FCM token hazır, topic aboneliği yapılıyor: ${fcmToken.substring(0, 20)}...', tag: _tag);
      
      await _firebaseMessaging.subscribeToTopic(userId);
      
      Logger.debug('✅ Topic\'e abone olundu: $userId', tag: _tag);
      return true;
    } catch (e) {
      Logger.error('❌ Topic\'e abone olma hatası: $e', tag: _tag);
      return false;
    }
  }

  /// Topic aboneliğini iptal et
  Future<bool> unsubscribeFromTopic(String userId) async {
    try {
      Logger.debug('Topic aboneliğ i iptal ediliyor: $userId', tag: _tag);
      
      await _firebaseMessaging.unsubscribeFromTopic(userId);
      
      Logger.debug('✅ Topic aboneliği iptal edildi: $userId', tag: _tag);
      return true;
    } catch (e) {
      Logger.error('❌ Topic abonelik iptali hatası: $e', tag: _tag);
      return false;
    }
  }

  /// OAuth 2.0 Bearer token ile FCM mesajı gönder
  Future<bool> sendFCMMessage({
    required String accessToken,
    String? topic,
    String? token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      Logger.debug('FCM mesajı gönderiliyor - Topic: $topic, Token: ${token?.substring(0, 20) ?? "null"}...', tag: _tag);
      
      // Platform'a göre farklı mesaj yapısı
      final Map<String, dynamic> msg = {
        "notification": {
          "title": title, 
          "body": body,
        },
        if (data != null) "data": data,
      };
      
      // Android için ek ayarlar
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        msg["android"] = {
          "priority": "high",
          "notification": {
            "channel_id": "high_importance_channel",
            "sound": "default",
            "priority": "high",
            "default_sound": true,
            "default_vibrate_timings": true,
            "default_light_settings": true
          }
        };
      }
      
      // iOS için ek ayarlar
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        msg["apns"] = {
          "headers": {
            "apns-push-type": "alert",
            "apns-priority": "10"
          },
          "payload": {
            "aps": {
              "alert": {
                "title": title,
                "body": body
              },
              "sound": "default",
              "badge": 1
            }
          }
        };
      }
      
      if (token != null && token.isNotEmpty) {
        msg["token"] = token;
        Logger.debug('FCM mesajı TOKEN ile gönderiliyor', tag: _tag);
      } else if (topic != null && topic.isNotEmpty) {
        msg["topic"] = topic;
        Logger.debug('FCM mesajı TOPIC ile gönderiliyor: $topic', tag: _tag);
      } else {
        Logger.error('❌ FCM mesajı için token veya topic gerekli', tag: _tag);
        return false;
      }
      
      final message = {"message": msg};
      
      Logger.debug('FCM Request Body: ${jsonEncode(message)}', tag: _tag);

      final response = await http.post(
        Uri.parse(_fcmApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      Logger.debug('FCM Response Status: ${response.statusCode}', tag: _tag);
      Logger.debug('FCM Response Body: ${response.body}', tag: _tag);

      if (response.statusCode == 200) {
        Logger.debug('✅ FCM mesajı başarıyla gönderildi', tag: _tag);
        return true;
      } else {
        Logger.error('❌ FCM mesaj gönderme hatası: ${response.statusCode} - ${response.body}', tag: _tag);
        return false;
      }
    } catch (e) {
      Logger.error('❌ FCM mesaj gönderme exception: $e', tag: _tag);
      return false;
    }
  }

  /// Notification permissions için izin iste
  Future<bool> requestNotificationPermissions() async {
    try {
      Logger.debug('Notification izinleri isteniyor...', tag: _tag);
      
      // Android 13+ için notification izni
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          final status = await perm.Permission.notification.status;
          if (!status.isGranted) {
            final result = await perm.Permission.notification.request();
            Logger.debug('Android notification permission: $result', tag: _tag);
          }
        } catch (e) {
          Logger.warning('Android notification izni kontrolünde uyarı: $e', tag: _tag);
        }
      }

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Logger.debug('Notification izin durumu: ${settings.authorizationStatus}', tag: _tag);
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        Logger.debug('✅ Notification izinleri verildi', tag: _tag);
        return true;
      } else {
        Logger.warning('⚠️ Notification izinleri reddedildi', tag: _tag);
        return false;
      }
    } catch (e) {
      Logger.error('❌ Notification izin isteme hatası: $e', tag: _tag);
      return false;
    }
  }

  /// FCM token değişikliklerini dinle
  Stream<String> onTokenRefresh() {
    return _firebaseMessaging.onTokenRefresh;
  }

  /// Foreground mesajları dinle
  Stream<RemoteMessage> onMessage() {
    return FirebaseMessaging.onMessage;
  }

  /// Background/terminated mesajları dinle  
  Stream<RemoteMessage> onMessageOpenedApp() {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  /// Notification badge sayısını ayarla (iOS)
  Future<void> setBadgeCount(int count) async {
    try {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      Logger.debug('Badge count ayarlandı: $count', tag: _tag);
    } catch (e) {
      Logger.error('Badge count ayarlama hatası: $e', tag: _tag);
    }
  }
  
  /// Test FCM mesajı gönder (kendi cihaza)
  Future<bool> sendTestNotification() async {
    try {
      Logger.debug('Test FCM mesajı gönderiliyor...', tag: _tag);
      
      // Kendi FCM token'ını al
      final token = await getFCMToken();
      if (token == null) {
        Logger.error('❌ FCM token bulunamadı', tag: _tag);
        return false;
      }
      
      // Test mesajı gönder
      final success = await sendFCMMessage(
        accessToken: 'test_token', // Bu gerçek bir token olmalı
        topic: '4',
        title: 'Test Bildirimi',
        body: 'Bu bir test bildirimidir. FCM çalışıyor!',
        data: {
          'type': 'test',
          'id': '1',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
      
      if (success) {
        Logger.debug('✅ Test FCM mesajı başarıyla gönderildi', tag: _tag);
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Test FCM mesajı gönderme hatası: $e', tag: _tag);
      return false;
    }
  }
} 