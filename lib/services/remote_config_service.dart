import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/logger.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  /// Remote Config'i başlatır
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        Logger.debug('🔧 Remote Config zaten başlatılmış');
        return;
      }

      Logger.info('🚀 Firebase Remote Config başlatılıyor...');
      
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Remote Config ayarları
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Production ayarı
      ));

      // Varsayılan değerler
      await _remoteConfig!.setDefaults(const {
        'announcement_text': '',
        'announcement_enabled': false,
        'announcement_title': 'Duyuru',
        'announcement_button_text': 'Tamam',
      });

      // İlk fetch işlemi
      await _fetchAndActivate();
      
      _isInitialized = true;
      Logger.info('✅ Firebase Remote Config başarıyla başlatıldı');
      
    } catch (e) {
      Logger.error('❌ Firebase Remote Config başlatma hatası: $e', error: e);
      throw Exception('Remote Config başlatılamadı: $e');
    }
  }

  /// Uzaktan yapılandırma verilerini çeker ve aktifleştirir
  Future<bool> _fetchAndActivate() async {
    try {
      Logger.debug('📡 Remote Config verileri çekiliyor...');
      
      final bool updated = await _remoteConfig!.fetchAndActivate();
      
      if (updated) {
        Logger.info('✅ Remote Config verileri güncellendi');
      } else {
        Logger.debug('ℹ️ Remote Config verileri zaten güncel');
      }
      
      return updated;
      
    } catch (e) {
      Logger.error('❌ Remote Config fetch hatası: $e', error: e);
      return false;
    }
  }

  /// Manuel olarak yapılandırma verilerini yeniler
  Future<bool> refresh() async {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış');
        await initialize();
      }
      
      return await _fetchAndActivate();
      
    } catch (e) {
      Logger.error('❌ Remote Config refresh hatası: $e', error: e);
      return false;
    }
  }

  /// Duyuru metnini getirir
  String getAnnouncementText() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return '';
      }
      
      final text = _remoteConfig!.getString('announcement_text');
      Logger.debug('📢 Duyuru metni alındı: ${text.isNotEmpty ? "Mevcut" : "Boş"}');
      return text;
      
    } catch (e) {
      Logger.error('❌ Duyuru metni alma hatası: $e', error: e);
      return '';
    }
  }

  /// Duyurunun aktif olup olmadığını kontrol eder
  bool isAnnouncementEnabled() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return false;
      }
      
      final enabled = _remoteConfig!.getBool('announcement_enabled');
      Logger.debug('📢 Duyuru durumu: ${enabled ? "Aktif" : "Pasif"}');
      return enabled;
      
    } catch (e) {
      Logger.error('❌ Duyuru durum kontrolü hatası: $e', error: e);
      return false;
    }
  }

  /// Duyuru başlığını getirir
  String getAnnouncementTitle() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return 'Duyuru';
      }
      
      final title = _remoteConfig!.getString('announcement_title');
      Logger.debug('📢 Duyuru başlığı alındı: $title');
      return title.isNotEmpty ? title : 'Duyuru';
      
    } catch (e) {
      Logger.error('❌ Duyuru başlığı alma hatası: $e', error: e);
      return 'Duyuru';
    }
  }

  /// Duyuru buton metnini getirir
  String getAnnouncementButtonText() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return 'Tamam';
      }
      
      final buttonText = _remoteConfig!.getString('announcement_button_text');
      Logger.debug('📢 Duyuru buton metni alındı: $buttonText');
      return buttonText.isNotEmpty ? buttonText : 'Tamam';
      
    } catch (e) {
      Logger.error('❌ Duyuru buton metni alma hatası: $e', error: e);
      return 'Tamam';
    }
  }

  /// Remote Config'den string değer alır
  String getString(String key, {String defaultValue = ''}) {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue');
        return defaultValue;
      }
      
      final value = _remoteConfig!.getString(key);
      Logger.debug('🔧 Remote Config değer alındı [$key]: ${value.isNotEmpty ? "Mevcut" : "Boş"}');
      return value.isNotEmpty ? value : defaultValue;
      
    } catch (e) {
      Logger.error('❌ Remote Config string alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config'den boolean değer alır
  bool getBool(String key, {bool defaultValue = false}) {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue');
        return defaultValue;
      }
      
      final value = _remoteConfig!.getBool(key);
      Logger.debug('🔧 Remote Config boolean alındı [$key]: $value');
      return value;
      
    } catch (e) {
      Logger.error('❌ Remote Config boolean alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config'den int değer alır
  int getInt(String key, {int defaultValue = 0}) {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue');
        return defaultValue;
      }
      
      final value = _remoteConfig!.getInt(key);
      Logger.debug('🔧 Remote Config int alındı [$key]: $value');
      return value;
      
    } catch (e) {
      Logger.error('❌ Remote Config int alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config'den double değer alır
  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue');
        return defaultValue;
      }
      
      final value = _remoteConfig!.getDouble(key);
      Logger.debug('🔧 Remote Config double alındı [$key]: $value');
      return value;
      
    } catch (e) {
      Logger.error('❌ Remote Config double alma hatası [$key]: $e', error: e);
      return defaultValue;
    }
  }

  /// Remote Config başlatılıp başlatılmadığını kontrol eder
  bool get isInitialized => _isInitialized;

  /// Tüm Remote Config verilerini debug için loglar
  void debugPrintAllValues() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.debug('🔧 Remote Config henüz başlatılmamış, debug bilgisi alınamıyor');
        return;
      }
      
      Logger.debug('🔧 === Remote Config Debug ===');
      Logger.debug('🔧 announcement_text: "${getAnnouncementText()}"');
      Logger.debug('🔧 announcement_enabled: ${isAnnouncementEnabled()}');
      Logger.debug('🔧 announcement_title: "${getAnnouncementTitle()}"');
      Logger.debug('🔧 announcement_button_text: "${getAnnouncementButtonText()}"');
      Logger.debug('🔧 ============================');
      
    } catch (e) {
      Logger.error('❌ Remote Config debug print hatası: $e', error: e);
    }
  }
}
