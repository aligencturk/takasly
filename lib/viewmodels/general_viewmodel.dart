import 'package:flutter/foundation.dart';
import '../services/general_service.dart';
import '../utils/logger.dart';

class GeneralViewModel extends ChangeNotifier {
  final GeneralService _generalService = GeneralService();

  Map<String, String>? _logos;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, String>? get logos => _logos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Logo bilgilerini API'den yükler
  Future<void> loadLogos() async {
    if (_logos != null) {
      Logger.debug(
        '🔍 GeneralViewModel - Logos already loaded, skipping API call',
        tag: 'GeneralViewModel',
      );
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug(
        '🔍 GeneralViewModel - Loading logos from API...',
        tag: 'GeneralViewModel',
      );

      final logos = await _generalService.getLogos();

      if (logos != null) {
        _logos = logos;
        Logger.info(
          '✅ GeneralViewModel - Logos loaded successfully',
          tag: 'GeneralViewModel',
        );
        Logger.debug(
          '🔍 GeneralViewModel - Logo count: ${_logos!.length}',
          tag: 'GeneralViewModel',
        );
      } else {
        _setError('Logo bilgileri yüklenemedi');
        Logger.error(
          '❌ GeneralViewModel - Failed to load logos',
          tag: 'GeneralViewModel',
        );
      }
    } catch (e) {
      _setError('Logo yükleme hatası: $e');
      Logger.error(
        '❌ GeneralViewModel - Exception: $e',
        tag: 'GeneralViewModel',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Logo bilgilerini zorla yeniler
  Future<void> refreshLogos() async {
    _logos = null;
    await loadLogos();
  }

  /// Belirli bir logo URL'ini alır
  String? getLogoUrl(String logoKey) {
    return _logos?[logoKey];
  }

  /// Ana logo URL'ini alır (logo field'ı)
  String? get mainLogoUrl => getLogoUrl('logo');

  /// Favicon URL'ini alır (Backend'de favicon olarak adlandırılmış ama app icon olarak kullanılıyor)
  String? get faviconUrl => getLogoUrl('favicon');

  /// App Icon URL'ini alır (favicon field'ından)
  String? get appIconUrl => getLogoUrl('favicon');
  
  /// App Icon'u günceller
  Future<void> updateAppIcon() async {
    try {
      Logger.info('🎨 GeneralViewModel - App icon güncelleniyor...', tag: 'GeneralViewModel');
      
      final appIconUrl = this.appIconUrl;
      if (appIconUrl == null || appIconUrl.isEmpty) {
        Logger.warning('⚠️ GeneralViewModel - App icon URL bulunamadı', tag: 'GeneralViewModel');
        return;
      }
      
      // App icon güncelleme işlemi burada yapılacak
      await _updateAppIconFromUrl(appIconUrl);
      
      Logger.info('✅ GeneralViewModel - App icon başarıyla güncellendi', tag: 'GeneralViewModel');
    } catch (e) {
      Logger.error('❌ GeneralViewModel - App icon güncellenirken hata: $e', tag: 'GeneralViewModel');
    }
  }
  
  /// URL'den app icon'u günceller
  Future<void> _updateAppIconFromUrl(String iconUrl) async {
    try {
      // Bu fonksiyon daha sonra implement edilecek
      Logger.debug('🔍 GeneralViewModel - Icon URL: $iconUrl', tag: 'GeneralViewModel');
      
      // TODO: Adaptive Icon ve Shortcut Icon güncelleme
      // await _updateAdaptiveIcon(iconUrl);
      // await _updateShortcutIcon(iconUrl);
      
    } catch (e) {
      Logger.error('❌ GeneralViewModel - Icon güncellenirken hata: $e', tag: 'GeneralViewModel');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
