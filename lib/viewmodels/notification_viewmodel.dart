import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // Okundu olarak işaretlenen bildirim ID'lerini takip et
  Set<int> _readNotificationIds = {};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRefreshing = false;
  
  // FCM state variables
  String? _fcmToken;
  bool _isPermissionGranted = false;
  bool _isTopicSubscribed = false;
  bool _fcmInitialized = false;

  // Notification Settings state variables
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isChatNotificationsEnabled = true;
  bool _isTradeNotificationsEnabled = true;
  bool _isSystemNotificationsEnabled = true;

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

  // Notification Settings Getters
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isChatNotificationsEnabled => _isChatNotificationsEnabled;
  bool get isTradeNotificationsEnabled => _isTradeNotificationsEnabled;
  bool get isSystemNotificationsEnabled => _isSystemNotificationsEnabled;

  /// Bildirimleri yükler
  Future<void> loadNotifications() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Okundu olarak işaretlenen bildirim ID'lerini yükle
      await _loadReadNotificationIds();

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
        final newNotifications = List<AppNotification.Notification>.from(response.data!);
        
        // Yeni bildirimleri kontrol et ve okunmamış olarak işaretle
        for (final notification in newNotifications) {
          if (!_readNotificationIds.contains(notification.id)) {
            // Bu yeni bir bildirim, okunmamış olarak kalacak
          }
        }
        
        _notifications = newNotifications;
        _clearError();
      } else {
        _setError(response.error ?? 'Bildirimler yüklenemedi');
      }
    } catch (e) {
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
      
      // Okundu olarak işaretlenen bildirim ID'lerini yükle
      await _loadReadNotificationIds();

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
        final newNotifications = List<AppNotification.Notification>.from(response.data!);
        
        // Yeni bildirimleri kontrol et ve okunmamış olarak işaretle
        for (final notification in newNotifications) {
          if (!_readNotificationIds.contains(notification.id)) {
            // Bu yeni bir bildirim, okunmamış olarak kalacak
          }
        }
        
        _notifications = newNotifications;
        _clearError();
      } else {
        _setError(response.error ?? 'Bildirimler yenilenemedi');
      }
    } catch (e) {
     
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
    // Okundu olarak işaretlenen bildirimleri çıkar
    return _notifications.where((notification) => 
      !_readNotificationIds.contains(notification.id)
    ).length;
  }

  /// Okundu olarak işaretlenen bildirim ID'lerini SharedPreferences'a kaydeder
  Future<void> _saveReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIdsList = _readNotificationIds.toList();
      await prefs.setStringList('readNotificationIds', 
        readIdsList.map((id) => id.toString()).toList()
      );
      Logger.debug('Okundu bildirim ID\'leri kaydedildi: $_readNotificationIds', tag: _tag);
    } catch (e) {
      Logger.error('Okundu bildirim ID\'leri kaydedilemedi: $e', tag: _tag);
    }
  }

  /// SharedPreferences'dan okundu olarak işaretlenen bildirim ID'lerini yükler
  Future<void> _loadReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIdsList = prefs.getStringList('readNotificationIds') ?? [];
      _readNotificationIds = readIdsList
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toSet();
      Logger.debug('Okundu bildirim ID\'leri yüklendi: $_readNotificationIds', tag: _tag);
    } catch (e) {
      Logger.error('Okundu bildirim ID\'leri yüklenemedi: $e', tag: _tag);
    }
  }

  /// Bildirimleri okundu olarak işaretler (badge'i sıfırlar)
  Future<void> markAllAsRead() async {
    try {
      Logger.info('Tüm bildirimler okundu olarak işaretleniyor...', tag: _tag);
      
      // Kullanıcı token'ını al
      final userToken = await _userService.getUserToken();
      if (userToken == null || userToken.isEmpty) {
        Logger.error('Kullanıcı token bulunamadı', tag: _tag);
        return;
      }

      // API'ye bildirimleri okundu olarak işaretleme isteği gönder
      final response = await _notificationService.markAllNotificationsAsRead(
        userToken: userToken,
      );

      if (response.isSuccess) {
        Logger.info('Tüm bildirimler başarıyla okundu olarak işaretlendi', tag: _tag);
        // Tüm mevcut bildirimleri okundu olarak işaretle
        for (final notification in _notifications) {
          _readNotificationIds.add(notification.id);
        }
        // SharedPreferences'a kaydet
        await _saveReadNotificationIds();
        notifyListeners();
      } else {
        Logger.error('Bildirimler okundu olarak işaretlenemedi: ${response.error}', tag: _tag);
        // Hata durumunda da tüm bildirimleri okundu olarak işaretle (kullanıcı deneyimi için)
        for (final notification in _notifications) {
          _readNotificationIds.add(notification.id);
        }
        // SharedPreferences'a kaydet
        await _saveReadNotificationIds();
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Mark all as read error: $e', tag: _tag);
      // Hata durumunda da tüm bildirimleri okundu olarak işaretle (kullanıcı deneyimi için)
      for (final notification in _notifications) {
        _readNotificationIds.add(notification.id);
      }
      // SharedPreferences'a kaydet
      await _saveReadNotificationIds();
      notifyListeners();
    }
  }

  /// Tüm bildirimleri siler
  Future<void> deleteAllNotifications() async {
    try {
      Logger.info('Tüm bildirimler siliniyor...', tag: _tag);
      
      // Kullanıcı token'ını al
      final userToken = await _userService.getUserToken();
      if (userToken == null || userToken.isEmpty) {
        Logger.error('Kullanıcı token bulunamadı', tag: _tag);
        return;
      }

      // API'ye tüm bildirimleri silme isteği gönder
      final response = await _notificationService.deleteAllNotifications(
        userToken: userToken,
      );

      if (response.isSuccess) {
        Logger.info('Tüm bildirimler başarıyla silindi', tag: _tag);
        // Local state'i temizle
        _notifications.clear();
        _readNotificationIds.clear();
        // SharedPreferences'dan da temizle
        await _clearReadNotificationIds();
        notifyListeners();
      } else {
        Logger.error('Bildirimler silinemedi: ${response.error}', tag: _tag);
      }
    } catch (e) {
      Logger.error('Delete all notifications error: $e', tag: _tag);
    }
  }

  /// Belirli bir bildirimi siler
  Future<void> deleteNotification(int notificationId) async {
    try {
      Logger.info('Bildirim siliniyor: $notificationId', tag: _tag);
      
      // Kullanıcı token'ını al
      final userToken = await _userService.getUserToken();
      if (userToken == null || userToken.isEmpty) {
        Logger.error('Kullanıcı token bulunamadı', tag: _tag);
        return;
      }

      // API'ye bildirim silme isteği gönder
      final response = await _notificationService.deleteNotification(
        userToken: userToken,
        notificationId: notificationId,
      );

      if (response.isSuccess) {
        Logger.info('Bildirim başarıyla silindi: $notificationId', tag: _tag);
        // Local state'den kaldır
        _notifications.removeWhere((notification) => notification.id == notificationId);
        _readNotificationIds.remove(notificationId);
        // SharedPreferences'dan da kaldır
        await _saveReadNotificationIds();
        notifyListeners();
      } else {
        Logger.error('Bildirim silinemedi: ${response.error}', tag: _tag);
      }
    } catch (e) {
      Logger.error('Delete notification error: $e', tag: _tag);
    }
  }

  /// SharedPreferences'dan okundu bildirim ID'lerini temizler
  Future<void> _clearReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('readNotificationIds');
      Logger.debug('Okundu bildirim ID\'leri temizlendi', tag: _tag);
    } catch (e) {
      Logger.error('Okundu bildirim ID\'leri temizlenemedi: $e', tag: _tag);
    }
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
      // Platform kontrolü
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
 
      }
      
      // İzin iste
      final permissionGranted = await _notificationService.requestNotificationPermissions();
      _isPermissionGranted = permissionGranted;
      
      if (permissionGranted) {
        // NotificationService içinde FLN ve dinleyicileri başlat
        try {
          await _notificationService.init();
        } catch (e) {
       
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
        } catch (_) {}
        
        _fcmInitialized = true;
        
        // iOS için ek bilgilendirme
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {

    
         
        }
      } else {
        }
      
      notifyListeners();
    } catch (e) {
   
      _setError('Bildirim servisi başlatılamadı');
    }
  }
  
  /// FCM Token'ını yeniler
  Future<void> _refreshFCMToken() async {
    try {
      final token = await _notificationService.getFCMToken();
      _fcmToken = token;
    } catch (e) {
     
    }
  }
  
  /// Kullanıcının topic'ine abone ol (retry ile)
  Future<void> _subscribeToUserTopicWithRetry() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser?.id != null) {
        // Retry logic ile topic subscription
        int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
                  try {
          final success = await _notificationService.subscribeToTopic(currentUser!.id);
          _isTopicSubscribed = success;
            
            if (success) {
              return;
            } else {
              
            }
          } catch (e) {
           
          }
          
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
          }
        }
        
  
      }
    } catch (e) {
    
    }
  }
  
  /// Message listener'larını kurar
  void _setupMessageListeners() {
    // Foreground mesajları dinle
    _notificationService.onMessage().listen((RemoteMessage message) {
      // Bildirim alındığında notification listesini yenile
      refreshNotifications();
    });
    
    // Token yenileme dinle
    _notificationService.onTokenRefresh().listen((String newToken) {
      _fcmToken = newToken;
      notifyListeners();
    });
  }
  
  /// Belirli bir topic'e abone ol
  Future<bool> subscribeToTopic(String topic) async {
    try {
      final success = await _notificationService.subscribeToTopic(topic);
      return success;
    } catch (e) {
     
      return false;
    }
  }
  
  /// Belirli bir topic aboneliğini iptal et
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      final success = await _notificationService.unsubscribeFromTopic(topic);
      return success;
    } catch (e) {
     
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
      final success = await _notificationService.sendFCMMessage(
        accessToken: accessToken,
        topic: topic,
        token: token,
        title: title,
        body: body,
        data: data,
      );
      
      return success;
    } catch (e) {
     
      return false;
    }
  }

  /// Test bildirimi gönder
  Future<bool> sendTestNotification() async {
    try {
      final success = await _notificationService.sendTestNotification();
      return success;
    } catch (e) {
     
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
   
        return false;
      }
      
      final masked = bearer.length > 12 ? '${bearer.substring(0, 6)}...${bearer.substring(bearer.length - 6)}' : '***';

      // Kullanıcı ID topic'ini al ve garanti abonelik
      final user = await _userService.getCurrentUser();
      if (user == null || user.id.isEmpty) {

        return false;
      }
      
      // Topic'e abone olmayı dene
      try {
        final subscribed = await _notificationService.subscribeToTopic(user.id);
        if (subscribed) {
        } else {
        }
      } catch (e) {
      }

      String? token;
      String? topic;
      if (toDevice) {
        token = await _notificationService.getFCMToken();
        if (token == null || token.isEmpty) {
          return false;
        }
      } else {
        topic = 'test_topic';
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
      } else {
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }
  
  /// ViewModel'i temizler
  @override
  void dispose() {
    _notifications.clear();
    super.dispose();
  }

  // MARK: - Notification Settings Methods

  /// Bildirim ayarlarını yükler
  Future<void> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isSoundEnabled = prefs.getBool('notification_sound') ?? true;
      _isVibrationEnabled = prefs.getBool('notification_vibration') ?? true;
      _isChatNotificationsEnabled = prefs.getBool('notification_chat') ?? true;
      _isTradeNotificationsEnabled = prefs.getBool('notification_trade') ?? true;
      _isSystemNotificationsEnabled = prefs.getBool('notification_system') ?? true;
      
      notifyListeners();
    } catch (e) {
      Logger.error('Bildirim ayarları yüklenirken hata: $e', tag: _tag);
    }
  }

  /// Bildirim ayarını günceller
  Future<void> updateNotificationSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      
      // State'i güncelle
      switch (key) {
        case 'notification_sound':
          _isSoundEnabled = value;
          break;
        case 'notification_vibration':
          _isVibrationEnabled = value;
          break;
        case 'notification_chat':
          _isChatNotificationsEnabled = value;
          break;
        case 'notification_trade':
          _isTradeNotificationsEnabled = value;
          break;
        case 'notification_system':
          _isSystemNotificationsEnabled = value;
          break;
      }
      
      notifyListeners();
      Logger.info('Bildirim ayarı güncellendi: $key = $value', tag: _tag);
    } catch (e) {
      Logger.error('Bildirim ayarı güncellenirken hata: $e', tag: _tag);
    }
  }

  /// Tüm bildirim ayarlarını sıfırlar
  Future<void> resetNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('notification_sound');
      await prefs.remove('notification_vibration');
      await prefs.remove('notification_chat');
      await prefs.remove('notification_trade');
      await prefs.remove('notification_system');
      
      // State'i varsayılan değerlere sıfırla
      _isSoundEnabled = true;
      _isVibrationEnabled = true;
      _isChatNotificationsEnabled = true;
      _isTradeNotificationsEnabled = true;
      _isSystemNotificationsEnabled = true;
      
      notifyListeners();
      Logger.info('Bildirim ayarları sıfırlandı', tag: _tag);
    } catch (e) {
      Logger.error('Bildirim ayarları sıfırlanırken hata: $e', tag: _tag);
    }
  }

  /// Bildirim izin durumunu kontrol eder
  Future<bool> checkNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      
      final hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                           settings.authorizationStatus == AuthorizationStatus.provisional;
      
      _isPermissionGranted = hasPermission;
      notifyListeners();
      
      return hasPermission;
    } catch (e) {
      Logger.error('Bildirim izni kontrol edilirken hata: $e', tag: _tag);
      return false;
    }
  }
} 