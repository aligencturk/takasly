import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification.dart' as AppNotification;
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService.instance;
  final UserService _userService = UserService();
  static const String _tag = 'NotificationViewModel';

  // State variables
  List<AppNotification.Notification> _notifications = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRefreshing = false;
  
  // FCM state variables
  String? _fcmToken;
  bool _isPermissionGranted = false;
  bool _isTopicSubscribed = false;
  bool _fcmInitialized = false;

  // Getters
  List<AppNotification.Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  bool get hasNotifications => _notifications.isNotEmpty;
  
  // FCM Getters
  String? get fcmToken => _fcmToken;
  bool get isPermissionGranted => _isPermissionGranted;
  bool get isTopicSubscribed => _isTopicSubscribed;
  bool get fcmInitialized => _fcmInitialized;

  /// Bildirimleri yükler
  Future<void> loadNotifications() async {
    try {
      _setLoading(true);
      _clearError();

      Logger.debug('Loading notifications...', tag: _tag);

      // Kullanıcı token'ını al
      final userToken = await _userService.getUserToken();
      if (userToken == null || userToken.isEmpty) {
        _setError('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Mevcut kullanıcıyı al
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        _setError('Kullanıcı bilgileri bulunamadı');
        return;
      }

      // User ID'yi int'e çevir
      final userId = int.tryParse(currentUser.id);
      if (userId == null) {
        _setError('Geçersiz kullanıcı ID');
        return;
      }

      Logger.debug('User ID: $userId, Token: ${userToken.substring(0, 20)}...', tag: _tag);

      // Bildirimleri API'den al
      final response = await _notificationService.getNotifications(
        userToken: userToken,
        userId: userId,
      );

      if (response.isSuccess && response.data != null) {
        _notifications = List<AppNotification.Notification>.from(response.data!);
        Logger.debug('Loaded ${_notifications.length} notifications', tag: _tag);
        _clearError();
      } else {
        _setError(response.error ?? 'Bildirimler yüklenemedi');
      }
    } catch (e) {
      Logger.error('Error loading notifications: $e', tag: _tag);
      _setError('Bildirimler yüklenirken hata oluştu');
    } finally {
      _setLoading(false);
    }
  }

  /// Bildirimleri yeniler (pull-to-refresh için)
  Future<void> refreshNotifications() async {
    try {
      _setRefreshing(true);
      _clearError();

      Logger.debug('Refreshing notifications...', tag: _tag);

      // Kullanıcı token'ını al
      final userToken = await _userService.getUserToken();
      if (userToken == null || userToken.isEmpty) {
        _setError('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Mevcut kullanıcıyı al
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        _setError('Kullanıcı bilgileri bulunamadı');
        return;
      }

      // User ID'yi int'e çevir
      final userId = int.tryParse(currentUser.id);
      if (userId == null) {
        _setError('Geçersiz kullanıcı ID');
        return;
      }

      // Bildirimleri API'den al
      final response = await _notificationService.getNotifications(
        userToken: userToken,
        userId: userId,
      );

      if (response.isSuccess && response.data != null) {
        _notifications = List<AppNotification.Notification>.from(response.data!);
        Logger.debug('Refreshed ${_notifications.length} notifications', tag: _tag);
        _clearError();
      } else {
        _setError(response.error ?? 'Bildirimler yenilenemedi');
      }
    } catch (e) {
      Logger.error('Error refreshing notifications: $e', tag: _tag);
      _setError('Bildirimler yenilenirken hata oluştu');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Belirli bir bildirimi bulur
  AppNotification.Notification? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((notification) => notification.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Bildirim tipine göre filtreleme
  List<AppNotification.Notification> getNotificationsByType(String type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  /// Yeni takas teklifi bildirimlerini alır
  List<AppNotification.Notification> get newTradeOfferNotifications {
    return getNotificationsByType('new_trade_offer');
  }

  /// Takas tamamlanma bildirimlerini alır
  List<AppNotification.Notification> get tradeCompletedNotifications {
    return getNotificationsByType('trade_completed');
  }

  /// Okunmamış bildirim sayısını alır
  int get unreadCount {
    // Şimdilik tüm bildirimleri okunmamış sayıyoruz
    // Gelecekte notification model'ine isRead field'ı eklenebilir
    return _notifications.length;
  }

  /// Bildirimleri okundu olarak işaretler (badge'i sıfırlar)
  void markAllAsRead() {
    // Şimdilik sadece bildirimleri temizliyoruz
    // Gelecekte API'ye bildirimleri okundu olarak işaretleme isteği gönderilebilir
    _notifications.clear();
    notifyListeners();
  }

  /// State management methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  /// FCM'i başlatır ve gerekli ayarları yapar
  Future<void> initializeFCM() async {
    try {
      Logger.debug('🚀 FCM Başlatılıyor...', tag: _tag);
      
      // Platform kontrolü
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        Logger.warning('📱 iOS PLATFORM TESPIT EDİLDİ', tag: _tag);
        Logger.warning('⚠️ iOS Simülatörde PUSH BİLDİRİMLER ÇALIŞMAZ!', tag: _tag);
        Logger.info('💡 Gerçek iOS cihazında test etmeniz gerekiyor', tag: _tag);
      }
      
      // İzin iste
      final permissionGranted = await _notificationService.requestNotificationPermissions();
      _isPermissionGranted = permissionGranted;
      Logger.debug('🔐 Bildirim İzni: ${permissionGranted ? "VERİLDİ ✅" : "REDDEDİLDİ ❌"}', tag: _tag);
      
      if (permissionGranted) {
        // NotificationService içinde FLN ve dinleyicileri başlat
        try {
          await _notificationService.init();
          Logger.debug('✅ NotificationService.init() çağrıldı', tag: _tag);
        } catch (e) {
          Logger.warning('⚠️ NotificationService.init() hatası: $e', tag: _tag);
        }

        // iOS foreground bildirim gösterimi için sunum seçeneklerini ayarla
        await _notificationService.setBadgeCount(0);
        
        // FCM Token'ını al
        await _refreshFCMToken();
        
        // Message listener'larını başlat
        _setupMessageListeners();
        
        // Kullanıcı ID'sine abone ol (retry ile)
        await _subscribeToUserTopicWithRetry();
        
        // Testler için 'test_topic' topic'ine de abone ol (debug amaçlı)
        try {
          await _notificationService.subscribeToTopic('test_topic');
          Logger.debug('✅ test_topic aboneliği eklendi', tag: _tag);
        } catch (_) {}
        
        _fcmInitialized = true;
        Logger.debug('✅ FCM BAŞARIYLA BAŞLATILDI!', tag: _tag);
        
        // iOS için ek bilgilendirme
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          Logger.info('📋 iOS BİLDİRİM TEST REHBERİ:', tag: _tag);
          Logger.info('1️⃣ Gerçek iOS cihazı kullanın (simülatör değil)', tag: _tag);
          Logger.info('2️⃣ Firebase Console\'da APNs sertifikası ekleyin', tag: _tag);
          Logger.info('3️⃣ Development/Production entitlements doğru ayarlayın', tag: _tag);
          Logger.info('4️⃣ App Store Connect\'te Bundle ID tanımlayın', tag: _tag);
        }
      } else {
        Logger.warning('⚠️ FCM izinleri verilmediği için başlatılamadı', tag: _tag);
        Logger.info('💡 İzinleri manuel olarak Ayarlar > Bildirimler\'den verebilirsiniz', tag: _tag);
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('❌ FCM başlatma hatası: $e', tag: _tag);
      _setError('Bildirim servisi başlatılamadı');
    }
  }
  
  /// FCM Token'ını yeniler
  Future<void> _refreshFCMToken() async {
    try {
      final token = await _notificationService.getFCMToken();
      _fcmToken = token;
      
      if (token != null) {
        Logger.debug('FCM Token güncellendi: ${token.substring(0, 20)}...', tag: _tag);
      }
    } catch (e) {
      Logger.error('FCM Token yenileme hatası: $e', tag: _tag);
    }
  }
  
  /// Kullanıcının topic'ine abone ol (retry ile)
  Future<void> _subscribeToUserTopicWithRetry() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser?.id != null) {
        Logger.debug('Kullanıcı topic\'ine abone olunuyor: ${currentUser!.id}', tag: _tag);
        
        // Retry logic ile topic subscription
        int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
          try {
            final success = await _notificationService.subscribeToTopic(currentUser.id);
            _isTopicSubscribed = success;
            
            if (success) {
              Logger.debug('✅ Kullanıcı topic\'ine abone olundu: ${currentUser.id}', tag: _tag);
              return;
            } else {
              Logger.warning('⚠️ Topic aboneliği başarısız, deneme $attempt/$maxAttempts', tag: _tag);
            }
          } catch (e) {
            Logger.warning('⚠️ Topic aboneliği hatası (deneme $attempt/$maxAttempts): $e', tag: _tag);
          }
          
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
          }
        }
        
        Logger.error('❌ Kullanıcı topic\'ine abone olunamadı: ${currentUser.id}', tag: _tag);
      }
    } catch (e) {
      Logger.error('Kullanıcı topic abone olma hatası: $e', tag: _tag);
    }
  }
  
  /// Message listener'larını kurar
  void _setupMessageListeners() {
    // Foreground mesajları dinle
    _notificationService.onMessage().listen((RemoteMessage message) {
      Logger.debug('Foreground mesaj alındı: ${message.notification?.title}', tag: _tag);
      
      // Bildirim alındığında notification listesini yenile
      refreshNotifications();
    });
    
    // Token yenileme dinle
    _notificationService.onTokenRefresh().listen((String newToken) {
      Logger.debug('FCM Token yenilendi: ${newToken.substring(0, 20)}...', tag: _tag);
      _fcmToken = newToken;
      notifyListeners();
    });
  }
  
  /// Belirli bir topic'e abone ol
  Future<bool> subscribeToTopic(String topic) async {
    try {
      Logger.debug('Topic\'e abone olunuyor: $topic', tag: _tag);
      
      final success = await _notificationService.subscribeToTopic(topic);
      
      if (success) {
        Logger.debug('✅ Topic\'e başarıyla abone olundu: $topic', tag: _tag);
      }
      
      return success;
    } catch (e) {
      Logger.error('Topic abone olma hatası: $e', tag: _tag);
      return false;
    }
  }
  
  /// Belirli bir topic aboneliğini iptal et
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      Logger.debug('Topic aboneliği iptal ediliyor: $topic', tag: _tag);
      
      final success = await _notificationService.unsubscribeFromTopic(topic);
      
      if (success) {
        Logger.debug('✅ Topic aboneliği başarıyla iptal edildi: $topic', tag: _tag);
      }
      
      return success;
    } catch (e) {
      Logger.error('Topic abonelik iptali hatası: $e', tag: _tag);
      return false;
    }
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
      Logger.debug('FCM mesajı gönderiliyor...', tag: _tag);
      
      final success = await _notificationService.sendFCMMessage(
        accessToken: accessToken,
        topic: topic,
        token: token,
        title: title,
        body: body,
        data: data,
      );
      
      if (success) {
        Logger.debug('✅ FCM mesajı başarıyla gönderildi', tag: _tag);
      }
      
      return success;
    } catch (e) {
      Logger.error('FCM mesaj gönderme hatası: $e', tag: _tag);
      return false;
    }
  }

  /// Test bildirimi gönder
  Future<bool> sendTestNotification() async {
    try {
      Logger.debug('Test bildirimi gönderiliyor...', tag: _tag);
      
      final success = await _notificationService.sendTestNotification();
      
      if (success) {
        Logger.debug('✅ Test bildirimi başarıyla gönderildi', tag: _tag);
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Test bildirimi gönderme hatası: $e', tag: _tag);
      return false;
    }
  }

  /// Sadece test amaçlı: Elle girilen Bearer ile KULLANICI ID topic'ine gönderir
  Future<bool> sendTestNotificationWithBearer({
    required String bearer,
    bool toDevice = true,
  }) async {
    try {
      if (bearer.trim().isEmpty) {
        Logger.warning('⚠️ Boş bearer token', tag: _tag);
        return false;
      }
      
      final masked = bearer.length > 12 ? '${bearer.substring(0, 6)}...${bearer.substring(bearer.length - 6)}' : '***';
      Logger.debug('Bearer test bildirimi gönderiliyor... ($masked) - hedef: ${toDevice ? 'cihaz token' : 'kullanıcı topic'}', tag: _tag);

      // Kullanıcı ID topic'ini al ve garanti abonelik
      final user = await _userService.getCurrentUser();
      if (user == null || user.id.isEmpty) {
        Logger.warning('⚠️ Kullanıcı bulunamadı, topic belirlenemedi', tag: _tag);
        return false;
      }
      
      Logger.debug('Kullanıcı ID: ${user.id}, Topic: ${user.id}', tag: _tag);
      
      // Topic'e abone olmayı dene
      try {
        final subscribed = await _notificationService.subscribeToTopic(user.id);
        if (subscribed) {
          Logger.debug('✅ Topic aboneliği başarılı: ${user.id}', tag: _tag);
        } else {
          Logger.warning('⚠️ Topic aboneliği başarısız: ${user.id}', tag: _tag);
        }
      } catch (e) {
        Logger.warning('⚠️ Topic aboneliği hatası: $e', tag: _tag);
      }

      String? token;
      String? topic;
      if (toDevice) {
        token = await _notificationService.getFCMToken();
        if (token == null || token.isEmpty) {
          Logger.error('❌ FCM token alınamadı, token ile gönderilemedi', tag: _tag);
          return false;
        }
        Logger.debug('🎯 Hedef token: ${token.substring(0, 16)}...', tag: _tag);
      } else {
        topic = 'test_topic';
        Logger.debug('🎯 Hedef topic: $topic', tag: _tag);
      }

      // Basit test mesajı gönder
      final success = await _notificationService.sendFCMMessage(
        accessToken: bearer,
        token: token,
        topic: topic,
        title: 'Test Bildirimi',
        body: 'Ali ıslak kek yaptım yicen mi - ${DateTime.now().toString().substring(11, 19)}',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
      
      if (success) {
        Logger.debug('✅ Bearer test bildirimi gönderildi', tag: _tag);
      } else {
        Logger.error('❌ Bearer test bildirimi gönderilemedi', tag: _tag);
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Bearer ile test bildirim hatası: $e', tag: _tag);
      return false;
    }
  }
  
  /// ViewModel'i temizler
  @override
  void dispose() {
    _notifications.clear();
    super.dispose();
  }
} 