import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  // Global navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Sonsuz döngüyü önlemek için flag
  static bool _isHandlingForbiddenError = false;

  // 403 hatası durumunda otomatik logout ve login'e yönlendirme
  static void handleForbiddenError(BuildContext? context) {
    // Eğer zaten işlem yapılıyorsa çık
    if (_isHandlingForbiddenError) {
      Logger.warning('⚠️ 403 error handler already running, skipping...');
      return;
    }
    
    _isHandlingForbiddenError = true;
    Logger.warning('🚨 Global 403 Forbidden error handler triggered');
    
    try {
      // Önce SharedPreferences'ı temizle
      _clearUserData();
      
      // Context varsa AuthViewModel'i güncelle
      if (context != null) {
        try {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          authViewModel.handleForbiddenError();
          Logger.info('✅ AuthViewModel updated for 403 error');
        } catch (e) {
          Logger.error('❌ Error updating AuthViewModel: $e', error: e);
        }
      } else {
        // Context yoksa navigator key'den context almaya çalış
        if (navigatorKey.currentState != null) {
          try {
            final context = navigatorKey.currentState!.context;
            final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
            authViewModel.handleForbiddenError();
            Logger.info('✅ AuthViewModel updated for 403 error via navigator context');
          } catch (e) {
            Logger.error('❌ Error updating AuthViewModel via navigator context: $e', error: e);
          }
        }
      }

      // Navigator key ile login'e yönlendir
      if (navigatorKey.currentState != null) {
        Logger.info('🔄 Navigating to login due to 403 error');
        
        // Önce mevcut route'u kontrol et
        final currentRoute = navigatorKey.currentState!.widget.initialRoute;
        Logger.info('🔄 Current route: $currentRoute');
        
        // Eğer zaten login sayfasında değilse yönlendir
        if (currentRoute != '/login') {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false, // Tüm route'ları temizle
          );
        } else {
          Logger.info('🔄 Already on login page, no navigation needed');
        }
      } else {
        Logger.warning('⚠️ Navigator key is null, cannot navigate');
      }
    } catch (e) {
      Logger.error('❌ Error in global 403 handler: $e', error: e);
    } finally {
      // İşlem tamamlandıktan sonra flag'i sıfırla
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingForbiddenError = false;
        Logger.info('✅ 403 error handler flag reset');
      });
    }
  }

  // Kullanıcı verilerini temizle
  static Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userTokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userDataKey);
      Logger.info('✅ User data cleared in global error handler');
    } catch (e) {
      Logger.error('❌ Error clearing user data in global error handler: $e', error: e);
    }
  }

  // 401 hatası durumunda otomatik logout ve login'e yönlendirme
  static void handleUnauthorizedError(BuildContext? context) {
    // Eğer zaten işlem yapılıyorsa çık
    if (_isHandlingForbiddenError) {
      Logger.warning('⚠️ Unauthorized error handler already running, skipping...');
      return;
    }
    
    _isHandlingForbiddenError = true;
    Logger.warning('🚨 Global 401 Unauthorized error handler triggered');
    
    try {
      // Context varsa AuthViewModel'i güncelle
      if (context != null) {
        try {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          authViewModel.handleForbiddenError(); // Aynı metodu kullan
          Logger.info('✅ AuthViewModel updated for 401 error');
        } catch (e) {
          Logger.error('❌ Error updating AuthViewModel: $e', error: e);
        }
      }

      // Navigator key ile login'e yönlendir
      if (navigatorKey.currentState != null) {
        Logger.info('🔄 Navigating to login due to 401 error');
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false, // Tüm route'ları temizle
        );
      } else {
        Logger.warning('⚠️ Navigator key is null, cannot navigate');
      }
    } catch (e) {
      Logger.error('❌ Error in global 401 handler: $e', error: e);
    } finally {
      // İşlem tamamlandıktan sonra flag'i sıfırla
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingForbiddenError = false;
        Logger.info('✅ Unauthorized error handler flag reset');
      });
    }
  }
} 