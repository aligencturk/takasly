import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  static const String _tag = 'NotificationViewModel';

  // State variables
  List<Notification> _notifications = [];
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
  List<Notification> get notifications => _notifications;
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
        _notifications = response.data!;
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
        _notifications = response.data!;
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
  Notification? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((notification) => notification.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Bildirim tipine göre filtreleme
  List<Notification> getNotificationsByType(String type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  /// Yeni takas teklifi bildirimlerini alır
  List<Notification> get newTradeOfferNotifications {
    return getNotificationsByType('new_trade_offer');
  }

  /// Takas tamamlanma bildirimlerini alır
  List<Notification> get tradeCompletedNotifications {
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
      Logger.debug('FCM başlatılıyor...', tag: _tag);
      
      // İzin iste
      final permissionGranted = await _notificationService.requestNotificationPermissions();
      _isPermissionGranted = permissionGranted;
      
      if (permissionGranted) {
        // FCM Token'ını al
        await _refreshFCMToken();
        
        // Message listener'larını başlat
        _setupMessageListeners();
        
        // Kullanıcı ID'sine abone ol
        await _subscribeToUserTopic();
        
        _fcmInitialized = true;
        Logger.debug('✅ FCM başarıyla başlatıldı', tag: _tag);
      } else {
        Logger.warning('⚠️ FCM izinleri verilmediği için başlatılamadı', tag: _tag);
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
  
  /// Kullanıcının topic'ine abone ol
  Future<void> _subscribeToUserTopic() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser?.id != null) {
        final success = await _notificationService.subscribeToTopic(currentUser!.id);
        _isTopicSubscribed = success;
        
        if (success) {
          Logger.debug('✅ Kullanıcı topic\'ine abone olundu: ${currentUser.id}', tag: _tag);
        }
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
    
    // Background'dan açılan mesajları dinle
    _notificationService.onMessageOpenedApp().listen((RemoteMessage message) {
      Logger.debug('Background mesajdan uygulama açıldı: ${message.notification?.title}', tag: _tag);
      
      // Mesaj detayına git (isteğe bağlı)
      _handleMessageNavigation(message);
    });
    
    // Token yenileme dinle
    _notificationService.onTokenRefresh().listen((String newToken) {
      Logger.debug('FCM Token yenilendi: ${newToken.substring(0, 20)}...', tag: _tag);
      _fcmToken = newToken;
      notifyListeners();
    });
  }
  
  /// Mesaj navigasyonunu işler
  void _handleMessageNavigation(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('type')) {
        final type = data['type'];
        final id = data['id'];
        
        Logger.debug('Mesaj navigasyon - Type: $type, ID: $id', tag: _tag);
        
        // Mesaj tipine göre navigasyon yapılabilir
        // Bu kısmı UI katmanında handle etmek daha uygun olacaktır
      }
    } catch (e) {
      Logger.error('Mesaj navigasyon hatası: $e', tag: _tag);
    }
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
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      Logger.debug('FCM mesajı gönderiliyor...', tag: _tag);
      
      final success = await _notificationService.sendFCMMessage(
        accessToken: accessToken,
        topic: topic,
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

  /// ViewModel'i temizler
  void dispose() {
    _notifications.clear();
    super.dispose();
  }
} 