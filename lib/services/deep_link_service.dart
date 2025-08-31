import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Deep Link Servisi
/// Uygulama açıkken ve kapalıyken gelen deep link'leri yakalar
/// ve işler
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  
  /// Deep link callback fonksiyonu
  Function(String)? onDeepLinkReceived;
  
  /// Servisi başlat
  Future<void> initialize() async {
    try {
      Logger.info('Deep Link Service başlatılıyor...');
      
      // Initial link'i yakala (uygulama kapalıyken açıldığında)
      await _handleInitialLink();
      
      // Runtime link'leri dinle (uygulama açıkken)
      await _handleRuntimeLinks();
      
      Logger.info('Deep Link Service başarıyla başlatıldı');
    } catch (e) {
      Logger.error('Deep Link Service başlatılırken hata: $e');
    }
  }
  
  /// Initial link'i yakala (uygulama kapalıyken açıldığında)
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        Logger.info('Initial deep link yakalandı: $initialLink');
        _processDeepLink(initialLink.toString());
      }
    } catch (e) {
      Logger.error('Initial link yakalanırken hata: $e');
    }
  }
  
  /// Runtime link'leri dinle (uygulama açıkken)
  Future<void> _handleRuntimeLinks() async {
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          Logger.info('Runtime deep link yakalandı: $uri');
          _processDeepLink(uri.toString());
        }
      }, onError: (error) {
        Logger.error('Runtime link stream hatası: $error');
      });
    } catch (e) {
      Logger.error('Runtime links dinlenirken hata: $e');
    }
  }
  
  /// Deep link'i işle ve parse et
  void _processDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      Logger.info('Deep link parse ediliyor: $uri');
      
      // Link türünü belirle
      if (_isProductDetailLink(uri)) {
        final productId = _extractProductId(uri);
        if (productId != null) {
          Logger.info('Ürün detay deep link\'i işleniyor. Product ID: $productId');
          onDeepLinkReceived?.call(productId);
        }
      } else {
        Logger.warning('Bilinmeyen deep link formatı: $link');
      }
    } catch (e) {
      Logger.error('Deep link işlenirken hata: $e');
    }
  }
  
  /// Link'in ürün detay link'i olup olmadığını kontrol et
  bool _isProductDetailLink(Uri uri) {
    // HTTPS/HTTP link kontrolü
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return uri.host == 'www.takasly.tr' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'ilan';
    }
    
    // Custom scheme kontrolü
    if (uri.scheme == 'takasly') {
      return uri.host == 'ilan';
    }
    
    return false;
  }
  
  /// URI'dan product ID'yi çıkar
  String? _extractProductId(Uri uri) {
    try {
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        // https://www.takasly.tr/ilan/1234 formatı
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'ilan') {
          return uri.pathSegments[1];
        }
      } else if (uri.scheme == 'takasly') {
        // takasly://ilan/1234 formatı
        if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.first;
        }
      }
    } catch (e) {
      Logger.error('Product ID çıkarılırken hata: $e');
    }
    return null;
  }
  
  /// Servisi durdur
  void dispose() {
    try {
      _linkSubscription?.cancel();
      Logger.info('Deep Link Service durduruldu');
    } catch (e) {
      Logger.error('Deep Link Service durdurulurken hata: $e');
    }
  }
}
