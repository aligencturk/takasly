import 'package:flutter/foundation.dart';
import '../services/remote_config_service.dart';
import '../utils/logger.dart';

class RemoteConfigViewModel extends ChangeNotifier {
  final RemoteConfigService _remoteConfigService = RemoteConfigService();

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isAnnouncementShown = false;

  // Remote Config verileri için cache
  String _announcementText = '';
  bool _announcementEnabled = false;
  String _announcementTitle = 'Duyuru';
  String _announcementButtonText = 'Tamam';

  // Resim özellikleri cache
  String _announcementImageUrl = '';
  bool _announcementImageEnabled = false;
  String _announcementImagePosition = 'top';
  double _announcementImageWidth = 300.0;
  double _announcementImageHeight = 200.0;
  String _announcementImageFit = 'cover';

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isAnnouncementShown => _isAnnouncementShown;

  // Remote Config değerleri
  String get announcementText => _announcementText;
  bool get announcementEnabled => _announcementEnabled;
  String get announcementTitle => _announcementTitle;
  String get announcementButtonText => _announcementButtonText;

  // Resim özellikleri getters
  String get announcementImageUrl => _announcementImageUrl;
  bool get announcementImageEnabled => _announcementImageEnabled;
  String get announcementImagePosition => _announcementImagePosition;
  double get announcementImageWidth => _announcementImageWidth;
  double get announcementImageHeight => _announcementImageHeight;
  String get announcementImageFit => _announcementImageFit;

  /// Duyuru gösterilmesi gerekip gerekmediğini kontrol eder
  bool get shouldShowAnnouncement =>
      // Genel enable açıksa ya da sadece görsel enable + url doluysa göster
      (_announcementEnabled ||
          (_announcementImageEnabled && _announcementImageUrl.isNotEmpty)) &&
      !_isAnnouncementShown &&
      (_announcementText.isNotEmpty ||
          (_announcementImageEnabled && _announcementImageUrl.isNotEmpty));

  RemoteConfigViewModel() {
  }

  /// Remote Config'i başlatır
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Remote Config Service'i başlat
      await _remoteConfigService.initialize();

      // Değerleri cache'e al
      await _updateCachedValues();

      _isInitialized = true;
    } catch (e) {
      Logger.error('RemoteConfigViewModel başlatma hatası: $e', error: e);
      _setError('Remote Config başlatılamadı');
    } finally {
      _setLoading(false);
    }
  }

  /// Remote Config değerlerini yeniler
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      // Service'den verileri yenile
      final updated = await _remoteConfigService.refresh();

      if (updated) {
        // Cache'i güncelle
        await _updateCachedValues();
      }
    } catch (e) {
      Logger.error('Remote Config yenileme hatası: $e', error: e);
      _setError('Veriler yenilenemedi');
    } finally {
      _setLoading(false);
    }
  }

  /// Cache'deki değerleri günceller
  Future<void> _updateCachedValues() async {
    try {
      // Temel duyuru özellikleri
      _announcementText = _remoteConfigService.getAnnouncementText();
      _announcementEnabled = _remoteConfigService.isAnnouncementEnabled();
      _announcementTitle = _remoteConfigService.getAnnouncementTitle();
      _announcementButtonText = _remoteConfigService
          .getAnnouncementButtonText();

      // Resim özellikleri
      _announcementImageUrl = _remoteConfigService.getAnnouncementImageUrl();
      _announcementImageEnabled = _remoteConfigService
          .isAnnouncementImageEnabled();
      _announcementImagePosition = _remoteConfigService
          .getAnnouncementImagePosition();
      _announcementImageWidth = _remoteConfigService
          .getAnnouncementImageWidth();
      _announcementImageHeight = _remoteConfigService
          .getAnnouncementImageHeight();
      _announcementImageFit = _remoteConfigService.getAnnouncementImageFit();

      notifyListeners();
    } catch (e) {
      Logger.error('Cache güncelleme hatası: $e', error: e);
    }
  }

  /// Duyuruyu gösterildi olarak işaretler
  void markAnnouncementAsShown() {
    _isAnnouncementShown = true;

    // Service'e de işaretle
    _remoteConfigService.markAnnouncementAsSeen();
    _remoteConfigService.markAnnouncementImageAsSeen();

    notifyListeners();
  }

  /// Duyuru gösterilme durumunu sıfırlar (yeni duyuru için)
  void resetAnnouncementShown() {
    _isAnnouncementShown = false;

    // Service'te de sıfırla
    _remoteConfigService.resetAnnouncementSeenStatus();

    notifyListeners();
  }

  /// Remote Config'den özel bir string değer alır
  String getString(String key, {String defaultValue = ''}) {
    try {
      if (!_isInitialized) {
        return defaultValue;
      }

      return _remoteConfigService.getString(key, defaultValue: defaultValue);
    } catch (e) {
      Logger.error('String değer alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config'den özel bir boolean değer alır
  bool getBool(String key, {bool defaultValue = false}) {
    try {
      if (!_isInitialized) {
        return defaultValue;
      }

      return _remoteConfigService.getBool(key, defaultValue: defaultValue);
    } catch (e) {
      Logger.error('Boolean değer alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config'den özel bir int değer alır
  int getInt(String key, {int defaultValue = 0}) {
    try {
      if (!_isInitialized) {
        return defaultValue;
      }

      return _remoteConfigService.getInt(key, defaultValue: defaultValue);
    } catch (e) {
      Logger.error('Int değer alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config'den özel bir double değer alır
  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      if (!_isInitialized) {
        return defaultValue;
      }

      return _remoteConfigService.getDouble(key, defaultValue: defaultValue);
    } catch (e) {
      Logger.error('Double değer alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Manuel olarak duyuru kontrolü yapar
  Future<bool> checkForAnnouncement() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // En güncel verileri al
      await refresh();

      // Service'den güncel kontrol yap
      final shouldShow = await _remoteConfigService.shouldShowAnnouncement();

      return shouldShow;
    } catch (e) {
      Logger.error('Duyuru kontrolü hatası: $e', error: e);
      return false;
    }
  }

  /// Hatayı temizler
  void clearError() {
    _clearError();
  }

  /// Manual hata seti
  void setError(String error) {
    _setError(error);
  }

  /// Test için duyuru durumunu sıfırlar
  Future<void> resetForTesting() async {
    // Local state'i sıfırla
    _isAnnouncementShown = false;

    // Service'te de sıfırla
    await _remoteConfigService.resetAnnouncementSeenStatus();

    notifyListeners();
  }

  /// Debug için kullanıcı durumunu gösterir
  Future<void> debugPrintUserAnnouncementStatus() async {
    try {
      final hasSeenText = await _remoteConfigService.hasUserSeenAnnouncement();
      final hasSeenImage = await _remoteConfigService
          .hasUserSeenAnnouncementImage();
      final isNewText = await _remoteConfigService.isNewAnnouncement();
      final isNewImage = await _remoteConfigService.isNewAnnouncementImage();
      final shouldShow = await _remoteConfigService.shouldShowAnnouncement();
    } catch (e) {
      Logger.error('Debug print hatası: $e', error: e);
    }
  }

  /// Loading durumunu ayarlar
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Hata mesajını ayarlar
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Hata mesajını temizler
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
