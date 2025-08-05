import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/notification.dart';
import '../utils/logger.dart';

class NotificationService {
  final HttpClient _httpClient = HttpClient();
  static const String _tag = 'NotificationService';

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
} 