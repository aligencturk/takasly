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
