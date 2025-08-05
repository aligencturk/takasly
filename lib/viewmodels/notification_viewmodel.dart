import 'package:flutter/foundation.dart';
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

  // Getters
  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  bool get hasNotifications => _notifications.isNotEmpty;

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

  /// ViewModel'i temizler
  void dispose() {
    _notifications.clear();
    super.dispose();
  }
} 