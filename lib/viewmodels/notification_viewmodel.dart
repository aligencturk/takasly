import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification.dart' as AppNotification;
import '../services/notification_service.dart';
import '../services/user_service.dart';

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
} 