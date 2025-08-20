// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../core/http_client.dart';
import '../models/notification.dart' as AppNotification;
import '../utils/logger.dart';
import 'error_handler_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'NotificationService';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  late AndroidNotificationChannel _androidChannel;
  bool _isInitialized = false;

  // Navigation guard - aynı navigation'ın çok kısa sürede tekrarlanmasını engeller
  String? _lastNavigatedProductId;
  DateTime? _lastNavigationTime;
  static const Duration _navigationCooldown = Duration(seconds: 2);

  // Uygulama içinde yönlendirme için callback (type, id)
  void Function(String type, String id)? onNavigate;

  Future<void> init({void Function(String, String)? onNavigate}) async {
    if (_isInitialized) return;
    
    this.onNavigate = onNavigate;

    // iOS izinleri
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    // iOS: ön planda da banner sesi vs.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // Android channel
    _androidChannel = const AndroidNotificationChannel(
      'high_importance_channel',
      'Bildirimler',
      description: 'Önemli bildirimler için kanal',
      importance: Importance.high,
    );

    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Local notifications init (tıklama yakalama)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        _handlePayload(resp.payload);
      },
    );

    // Foreground: mesaj geldiğinde local notification göster
    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      _showForegroundNotification(m);
    });

    // Bildirime tıklayıp uygulama açıldı (arka plandan -> öne)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Bildirime tıklayıp soğuk başlatma
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _handleMessageTap(initial);
    }
    
    _isInitialized = true;
  }
  
  /// NotificationService'in init edildiğinden emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  /// Topic aboneliği (sizde server 'topic': user_id gönderiyor)
  Future<void> subscribeUserTopic(String userId) async {
    // Topic regex: [a-zA-Z0-9-_.~%]+  -> gerekirse temizleyin
    await _fcm.subscribeToTopic(userId);
  }

  Future<void> unsubscribeUserTopic(String userId) async {
    await _fcm.unsubscribeFromTopic(userId);
  }
  
  /// Compatibility method - delegates to subscribeToTopic
  Future<bool> subscribeUserTopicCompat(String userId) async {
    try {
      await subscribeUserTopic(userId);
      return true;
    } catch (e) {
      Logger.error('Subscribe user topic compat error: $e', tag: _tag);
      return false;
    }
  }

  // Ön planda local notif göster
  Future<void> _showForegroundNotification(RemoteMessage m) async {
    final title = m.notification?.title ?? 'Bildirim';
    final body  = m.notification?.body  ?? '';
    final payload = _buildPayload(m);


    // Bildirim türüne göre özel kategori belirle
    final (type, _) = _extractData(m.data);
    String? categoryIdentifier;
    if (type.isNotEmpty) {
      categoryIdentifier = 'notification_$type';
    }

    await _fln.show(
      m.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          // Android için özel ses ve titreşim
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: categoryIdentifier,
          threadIdentifier: type.isNotEmpty ? type : 'default',
        ),
      ),
      payload: payload,
    );
    
    Logger.debug('Foreground notification shown: $title', tag: _tag);
  }

  // Tıklamada yönlendirme
  void _handleMessageTap(RemoteMessage m) {
    final data = _extractData(m.data);
    if (data.$1.isNotEmpty) {
      _navigateBasedOnType(data.$1, data.$2);
    }
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final type = (map['type'] ?? '').toString();
      final id   = (map['id'] ?? '').toString();
      if (type.isNotEmpty) {
        _navigateBasedOnType(type, id);
      }
    } catch (_) {}
  }

  /// Bildirim türüne göre yönlendirme yapar
  void _navigateBasedOnType(String type, String id) {
    Logger.debug('Navigating based on type: $type, id: $id', tag: _tag);
    
    // Eğer custom navigation callback varsa önce onu kullan
    if (onNavigate != null) {
      onNavigate!(type, id);
      return;
    }
    
    // Bildirim türlerine göre yönlendirme
    switch (type.toLowerCase()) {
      case 'new_trade_offer':
      case 'trade_offer_approved':
      case 'trade_offer_rejected':
      case 'trade_completed':
        // Teklif detayına git
        if (id.isNotEmpty) {
          _navigateToTradeDetail(id);
        }
        break;
        
      case 'sponsor_expired':
        // İlan detayına veya düzenlemeye git
        if (id.isNotEmpty) {
          _navigateToProductDetail(id);
        }
        break;
        
      default:
        Logger.debug('Unknown notification type: $type', tag: _tag);
        // Varsayılan olarak bildirimler sayfasına git
        _navigateToNotifications();
        break;
    }
  }
  
  /// Teklif detayına yönlendir
  void _navigateToTradeDetail(String offerId) {
    try {
      final context = _getCurrentContext();
      if (context != null) {
        Navigator.pushNamed(
          context,
          '/trade-detail',
          arguments: {'offerID': int.tryParse(offerId) ?? 0},
        );
        Logger.debug('Navigated to trade detail: $offerId', tag: _tag);
      }
    } catch (e) {
      Logger.error('Navigation to trade detail failed: $e', tag: _tag);
    }
  }
  
  /// İlan detayına yönlendir
  void _navigateToProductDetail(String productId) {
    try {
      // Navigation guard - aynı productId ile çok kısa sürede navigation yapılmasını engeller
      final now = DateTime.now();
      if (_lastNavigatedProductId == productId && 
          _lastNavigationTime != null &&
          now.difference(_lastNavigationTime!) < _navigationCooldown) {
        Logger.debug('Navigation blocked - too soon after last navigation: $productId', tag: _tag);
        return;
      }
      
      final context = _getCurrentContext();
      if (context != null) {
        _lastNavigatedProductId = productId;
        _lastNavigationTime = now;
        
        Navigator.pushNamed(
          context,
          '/edit-product',
          arguments: {'productId': productId},
        );
        Logger.debug('Navigated to edit product: $productId', tag: _tag);
      }
    } catch (e) {
      Logger.error('Navigation to edit product failed: $e', tag: _tag);
    }
  }
  
  /// Bildirimler sayfasına yönlendir
  void _navigateToNotifications() {
    try {
      final context = _getCurrentContext();
      if (context != null) {
        Navigator.pushNamed(context, '/notifications');
        Logger.debug('Navigated to notifications', tag: _tag);
      }
    } catch (e) {
      Logger.error('Navigation to notifications failed: $e', tag: _tag);
    }
  }
  
  /// Mevcut context'i al
  BuildContext? _getCurrentContext() {
    // ErrorHandlerService'den navigator key kullan
    try {
      // ErrorHandlerService import edilmişse onun navigator key'ini kullan
      final navigatorKey = _getNavigatorKey();
      return navigatorKey?.currentContext;
    } catch (e) {
      Logger.error('Failed to get current context: $e', tag: _tag);
      return null;
    }
  }
  
  /// Navigator key'i al (ErrorHandlerService'den)
  GlobalKey<NavigatorState>? _getNavigatorKey() {
    try {
      return ErrorHandlerService.navigatorKey;
    } catch (e) {
      return null;
    }
  }

  /// Server tarafı `data.keysandvalues` içinde JSON **string** yolluyor.
  /// Burada parse edip (type,id) döndürüyoruz.
  /// Eğer keysandvalues boşsa, data içindeki type ve id'yi direkt kontrol eder.
  (String, String) _extractData(Map<String, dynamic> data) {
    try {
      // Önce keysandvalues içindeki JSON'u kontrol et
      final raw = data['keysandvalues'];
      if (raw is String && raw.isNotEmpty && raw != '{}') {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final type = (m['type'] ?? '').toString();
        final id   = (m['id']   ?? '').toString();
        if (type.isNotEmpty) {
          return (type, id);
        }
      }
      
      // Eğer keysandvalues boşsa, data içindeki type ve id'yi direkt kontrol et
      final directType = (data['type'] ?? '').toString();
      final directId = (data['id'] ?? '').toString();
      if (directType.isNotEmpty) {
        return (directType, directId);
      }
      
      // Notification title'dan bildirim türünü çıkarmaya çalış
      final title = data['title'] ?? '';
      if (title is String) {
        if (title.contains('Yeni Takas Teklifi') || title.contains('New Trade Offer')) {
          return ('new_trade_offer', directId);
        } else if (title.contains('Takas Onaylandı') || title.contains('Trade Approved')) {
          return ('trade_offer_approved', directId);
        } else if (title.contains('Teklif Reddedildi') || title.contains('Trade Rejected')) {
          return ('trade_offer_rejected', directId);
        } else if (title.contains('Takas Tamamlandı') || title.contains('Trade Completed')) {
          return ('trade_completed', directId);
        } else if (title.contains('Süre doldu') || title.contains('Sponsor Expired') || title.contains('Öne Çıkarma')) {
          return ('sponsor_expired', directId);
        }
      }
      
    } catch (e) {
      Logger.error('Extract data error: $e', tag: _tag);
    }
    return ('','');
  }

  String _buildPayload(RemoteMessage m) {
    final (type, id) = _extractData(m.data);
    return jsonEncode({'type': type, 'id': id});
  }
  
  /// Kullanıcının bildirimlerini API'den alır
  /// GET /service/user/{userId}/notifications
  Future<ApiResponse<List<AppNotification.Notification>>> getNotifications({
    required String userToken,
    required int userId,
  }) async {
    try {
      Logger.debug('Loading notifications for user: $userId', tag: _tag);
      
      final response = await _httpClient.getWithBasicAuth(
        '/service/user/account/$userId/notifications',
        fromJson: (json) {
          Logger.debug('Notifications fromJson - Raw data: $json', tag: _tag);
          
          if (json is Map<String, dynamic>) {
            // Yeni API formatı: { "error": false, "success": true, "data": { "notifications": [...] } }
            if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
              final dataField = json['data'] as Map<String, dynamic>;
              
              // Eğer notifications field'ı içinde liste varsa
              if (dataField.containsKey('notifications') && dataField['notifications'] is List) {
                final notificationsList = dataField['notifications'] as List;
                Logger.debug('Found ${notificationsList.length} notifications in data.notifications', tag: _tag);
                return notificationsList
                    .map((notificationJson) => AppNotification.Notification.fromJson(notificationJson))
                    .toList();
              }
              
              // Eğer data field'ı direkt notification listesi içeriyorsa
              if (dataField.containsKey('id') || dataField.containsKey('title')) {
                Logger.debug('Found single notification in data field', tag: _tag);
                return [AppNotification.Notification.fromJson(dataField)];
              }
              
              Logger.debug('No notifications found in data field', tag: _tag);
              return <AppNotification.Notification>[];
            }
            // Eski format: direkt notifications field'ı
            else if (json.containsKey('notifications') && json['notifications'] is List) {
              final notificationsList = json['notifications'] as List;
              Logger.debug('Found ${notificationsList.length} notifications in notifications field', tag: _tag);
              return notificationsList
                  .map((notificationJson) => AppNotification.Notification.fromJson(notificationJson))
                  .toList();
            }
            // Eğer direkt liste gelirse
            else if (json is List) {
              Logger.debug('Found ${json.length} notifications in direct list', tag: _tag);
              return (json as List)
                  .map((notificationJson) => AppNotification.Notification.fromJson(notificationJson))
                  .toList();
            }
          }
          
          // Eğer direkt liste gelirse
          if (json is List) {
            return json
                .map((notificationJson) => AppNotification.Notification.fromJson(notificationJson))
                .toList();
          }
          
          return <AppNotification.Notification>[];
        },
      );
      
      Logger.debug('Notifications response: success=${response.isSuccess}', tag: _tag);
      return response;
    } catch (e) {
      Logger.error('Get notifications error: $e', tag: _tag);
      return ApiResponse<List<AppNotification.Notification>>.error('Bildirimler yüklenemedi: $e');
    }
  }
  
  /// FCM için bildirim izinleri ister
  Future<bool> requestNotificationPermissions() async {
    try {
      Logger.debug('Requesting FCM permissions...', tag: _tag);
      
      // iOS için daha kapsamlı izinler
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true, // iOS 12+ için provisional izin
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                     settings.authorizationStatus == AuthorizationStatus.provisional;
      
      Logger.debug('FCM permission status: ${settings.authorizationStatus}', tag: _tag);
      Logger.debug('FCM permission granted: $granted', tag: _tag);
      
      if (granted) {
        // iOS foreground notification presentation options
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        Logger.debug('Foreground notification options set', tag: _tag);
      }
      
      return granted;
    } catch (e) {
      Logger.error('Request FCM permissions error: $e', tag: _tag);
      return false;
    }
  }
  
  /// Badge sayısını ayarlar (iOS)
  Future<void> setBadgeCount(int count) async {
    try {
      await _ensureInitialized();
      
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS badge count API Firebase Messaging üzerinden yapılacak
        // await FirebaseMessaging.instance.setBadgeCount(count); // Bu method mevcut değil
        Logger.debug('Badge count setting attempted for iOS: $count', tag: _tag);
      }
    } catch (e) {
      Logger.error('Set badge count error: $e', tag: _tag);
    }
  }
  
  /// FCM Token'ını alır
  Future<String?> getFCMToken() async {
    try {
      Logger.debug('Getting FCM token...', tag: _tag);
      final token = await _fcm.getToken();
      
      if (token != null) {
        Logger.debug('FCM token retrieved: ${token.substring(0, 20)}...', tag: _tag);
      } else {
        Logger.warning('FCM token is null', tag: _tag);
      }
      
      return token;
    } catch (e) {
      Logger.error('Get FCM token error: $e', tag: _tag);
      return null;
    }
  }
  
  /// Belirli bir topic'e abone ol
  Future<bool> subscribeToTopic(String topic) async {
    try {
      Logger.debug('Subscribing to topic: $topic', tag: _tag);
      await _fcm.subscribeToTopic(topic);
      Logger.debug('Successfully subscribed to topic: $topic', tag: _tag);
      return true;
    } catch (e) {
      Logger.error('Subscribe to topic error: $e', tag: _tag);
      return false;
    }
  }
  
  /// Belirli bir topic aboneliğini iptal et
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      Logger.debug('Unsubscribing from topic: $topic', tag: _tag);
      await _fcm.unsubscribeFromTopic(topic);
      Logger.debug('Successfully unsubscribed from topic: $topic', tag: _tag);
      return true;
    } catch (e) {
      Logger.error('Unsubscribe from topic error: $e', tag: _tag);
      return false;
    }
  }
  
  /// Foreground mesajları için stream
  Stream<RemoteMessage> onMessage() {
    return FirebaseMessaging.onMessage;
  }
  
  /// Background'dan açılan mesajları için stream
  Stream<RemoteMessage> onMessageOpenedApp() {
    return FirebaseMessaging.onMessageOpenedApp;
  }
  
  /// Token yenileme için stream
  Stream<String> onTokenRefresh() {
    return _fcm.onTokenRefresh;
  }
  
  /// FCM mesajı gönder (OAuth 2.0 Bearer token ile)
  Future<bool> sendFCMMessage({
    required String accessToken,
    String? topic,
    String? token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      Logger.debug('Sending FCM message...', tag: _tag);
      
      // Firebase Project ID'yi buradan alabilirsiniz
      
      final url = 'https://fcm.googleapis.com/v1/projects/takasla-b2aa5/messages:send';
      
      // Data mapping için debug log - güvenli mapping
      Map<String, String>? mappedData;
      if (data != null) {
        Logger.debug('Original data: $data', tag: _tag);
        Logger.debug('Original data type: ${data.runtimeType}', tag: _tag);
        
        mappedData = <String, String>{};
        data.forEach((key, value) {
          Logger.debug('Processing key: $key, value: $value (${value.runtimeType})', tag: _tag);
          mappedData![key] = value.toString();
        });
        
        Logger.debug('Mapped data: $mappedData', tag: _tag);
      }

      // Message yapısını adım adım oluştur
      Logger.debug('Building message structure...', tag: _tag);
      
      Map<String, dynamic> messageContent = {};
      
      // Notification kısmını ekle
      messageContent['notification'] = {
        'title': title,
        'body': body,
      };
      Logger.debug('Notification added: ${messageContent['notification']}', tag: _tag);
      
      // Data kısmını ekle - geçici olarak boş bırakılıyor
      try {
        Logger.debug('Attempting to add data...', tag: _tag);
        if (mappedData != null && mappedData.isNotEmpty) {
          Logger.debug('MappedData is not null and not empty', tag: _tag);
          messageContent['data'] = mappedData;
          Logger.debug('Data added successfully', tag: _tag);
        } else {
          Logger.debug('MappedData is null or empty, using empty map', tag: _tag);
          messageContent['data'] = <String, String>{};
        }
        Logger.debug('Data section completed', tag: _tag);
      } catch (e) {
        Logger.error('Error adding data: $e', tag: _tag);
        // Data olmadan devam et
      }
      
      // Topic veya token hedef belirle
      if (topic != null) {
        Logger.debug('Adding topic: $topic', tag: _tag);
        messageContent['topic'] = topic;
      } else if (token != null) {
        Logger.debug('Adding token: $token', tag: _tag);
        messageContent['token'] = token;
      } else {
        Logger.error('Either topic or token must be provided', tag: _tag);
        return false;
      }
      
      try {
        Logger.debug('Message content complete: $messageContent', tag: _tag);
      } catch (e) {
        Logger.error('Error logging message content: $e', tag: _tag);
      }
      
      // Final message wrapper
      // iOS güvenilirliği için APNs override ekle
      final Map<String, dynamic> apnsOverride = {
        'headers': {
          'apns-priority': '10',
          'apns-push-type': 'alert',
          // iOS için bundle id'yi topic olarak belirt (APNs doğrulaması)
          'apns-topic': 'com.rivorya.takaslyapp',
          // Anında teslim
          'apns-expiration': '0',
        },
        'payload': {
          'aps': {
            'sound': 'default',
            // Foreground gösterimi için mutable-content (rich notification desteği)
            'mutable-content': 1,
          }
        }
      };

      Map<String, dynamic> message = {
        'message': {
          ...messageContent,
          'apns': apnsOverride,
        },
      };
      Logger.debug('Final message wrapper created', tag: _tag);
      
      try {
        Logger.debug('Final message structure: $message', tag: _tag);
      } catch (e) {
        Logger.error('Error logging final message: $e', tag: _tag);
        Logger.debug('Message keys: ${message.keys.toList()}', tag: _tag);
      }
      
      String jsonBody;
      try {
        jsonBody = jsonEncode(message);
        Logger.debug('JSON encoded successfully', tag: _tag);
      } catch (e) {
        Logger.error('JSON encoding error: $e', tag: _tag);
        return false;
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonBody,
      );
      
      Logger.debug('FCM message response: ${response.statusCode}', tag: _tag);
      Logger.debug('FCM message response body: ${response.body}', tag: _tag);

      if (response.statusCode == 401) {
        Logger.error('FCM yetkilendirme hatası (401). APNs/FCM yapılandırmasını kontrol edin. "THIRD_PARTY_AUTH_ERROR" genellikle Firebase projesine APNs Auth Key (.p8) yüklenmediğinde, TeamID/KeyID hatalı olduğunda veya bundleId eşleşmediğinde görülür.', tag: _tag);
      }
      
      // Status code kontrolü - 410 ve 200 başarılı sayılıyor
      if (response.statusCode == 410 || response.statusCode == 200) {
        // Response body'de hata mesajı var mı kontrol et
        String trimmedBody = response.body.trim();
        if (trimmedBody.contains('Method geçersiz') || 
            trimmedBody.contains('geçersiz') ||
            trimmedBody.contains('invalid') ||
            trimmedBody.contains('error')) {
          Logger.warning('FCM message failed with error: $trimmedBody', tag: _tag);
          return false;
        }
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Send FCM message error: $e', tag: _tag);
      return false;
    }
  }
  
  /// Test bildirimi gönder
  Future<bool> sendTestNotification({String? type, String? id}) async {
    try {
      Logger.debug('Sending test notification...', tag: _tag);
      
      // NotificationService init edilmemişse init et
      await _ensureInitialized();
      
      // Test için varsayılan değerler
      final testType = type ?? 'new_trade_offer';
      final testId = id ?? '123';
      
      String title = 'Test Bildirimi';
      String body = 'Bu bir test bildirimidir';
      
      // Test türüne göre mesaj ayarla
      switch (testType) {
        case 'new_trade_offer':
          title = 'Yeni Takas Teklifi 🔄';
          body = 'İlanınız için yeni bir takas teklifi var! Hemen kontrol edin 👀';
          break;
        case 'trade_offer_approved':
          title = 'Takas Onaylandı ✅';
          body = 'Harika! Takas teklifiniz kabul edildi. Artık takas yapabilirsiniz 🎉';
          break;
        case 'trade_offer_rejected':
          title = 'Teklif Reddedildi ❌';
          body = 'Takas teklifiniz reddedildi. Başka fırsatları keşfedin! 🔍';
          break;
        case 'trade_completed':
          title = 'Takas Tamamlandı 🎊';
          body = 'Takasınız başarıyla tamamlandı! Yeni bir takas yapmaya ne dersiniz? 🚀';
          break;
        case 'sponsor_expired':
          title = 'Süre doldu ⏳';
          body = 'İlanın öne çıkma süresi sona erdi. Ama merak etme, tek tıkla tekrar öne çıkarabilirsin 🚀';
          break;
      }
      
      // iOS için özel test bildirimi
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        Logger.debug('iOS platform detected, sending iOS-specific test notification', tag: _tag);
        
        await _fln.show(
          999,
          title,
          body,
          NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              badgeNumber: 1,
              attachments: null,
              categoryIdentifier: 'notification_$testType',
              threadIdentifier: testType,
            ),
          ),
          payload: jsonEncode({
            'type': testType,
            'id': testId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'platform': 'ios',
          }),
        );
      } else {
        // Android için normal bildirim
        await _fln.show(
          999,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode({
            'type': testType,
            'id': testId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          }),
        );
      }
      
      Logger.debug('Test notification sent successfully: $testType', tag: _tag);
      return true;
    } catch (e) {
      Logger.error('Send test notification error: $e', tag: _tag);
      return false;
    }
  }
}
