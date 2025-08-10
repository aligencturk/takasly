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
        // Resim özellikleri
        'announcement_image_url': '',
        'announcement_image_enabled': false,
        'announcement_image_position': 'top', // top, bottom, background
        'announcement_image_width': 300.0,
        'announcement_image_height': 200.0,
        'announcement_image_fit': 'cover', // cover, contain, fill, fitWidth, fitHeight
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

  /// Duyuru resim URL'ini getirir
  String getAnnouncementImageUrl() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return '';
      }
      
      final url = _remoteConfig!.getString('announcement_image_url');
      Logger.debug('🖼️ Duyuru resim URL alındı: ${url.isNotEmpty ? "Mevcut" : "Boş"}');
      return url;
      
    } catch (e) {
      Logger.error('❌ Duyuru resim URL alma hatası: $e', error: e);
      return '';
    }
  }

  /// Duyuru resminin aktif olup olmadığını kontrol eder
  bool isAnnouncementImageEnabled() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return false;
      }
      
      final enabled = _remoteConfig!.getBool('announcement_image_enabled');
      Logger.debug('🖼️ Duyuru resim durumu: ${enabled ? "Aktif" : "Pasif"}');
      return enabled;
      
    } catch (e) {
      Logger.error('❌ Duyuru resim durumu alma hatası: $e', error: e);
      return false;
    }
  }

  /// Duyuru resim pozisyonunu getirir (top, bottom, background)
  String getAnnouncementImagePosition() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return 'top';
      }
      
      final position = _remoteConfig!.getString('announcement_image_position');
      final validPositions = ['top', 'bottom', 'background'];
      final finalPosition = validPositions.contains(position) ? position : 'top';
      Logger.debug('📍 Duyuru resim pozisyonu: $finalPosition');
      return finalPosition;
      
    } catch (e) {
      Logger.error('❌ Duyuru resim pozisyonu alma hatası: $e', error: e);
      return 'top';
    }
  }

  /// Duyuru resim genişliğini getirir
  double getAnnouncementImageWidth() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return 300.0;
      }
      
      final width = _remoteConfig!.getDouble('announcement_image_width');
      Logger.debug('📏 Duyuru resim genişlik: $width');
      return width > 0 ? width : 300.0;
      
    } catch (e) {
      Logger.error('❌ Duyuru resim genişlik alma hatası: $e', error: e);
      return 300.0;
    }
  }

  /// Duyuru resim yüksekliğini getirir
  double getAnnouncementImageHeight() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return 200.0;
      }
      
      final height = _remoteConfig!.getDouble('announcement_image_height');
      Logger.debug('📏 Duyuru resim yükseklik: $height');
      return height > 0 ? height : 200.0;
      
    } catch (e) {
      Logger.error('❌ Duyuru resim yükseklik alma hatası: $e', error: e);
      return 200.0;
    }
  }

  /// Duyuru resim fit modunu getirir
  String getAnnouncementImageFit() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning('⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor');
        return 'cover';
      }
      
      final fit = _remoteConfig!.getString('announcement_image_fit');
      final validFits = ['cover', 'contain', 'fill', 'fitWidth', 'fitHeight'];
      final finalFit = validFits.contains(fit) ? fit : 'cover';
      Logger.debug('📐 Duyuru resim fit: $finalFit');
      return finalFit;
      
    } catch (e) {
      Logger.error('❌ Duyuru resim fit alma hatası: $e', error: e);
      return 'cover';
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
      Logger.debug('🔧 --- Resim Özellikleri ---');
      Logger.debug('🔧 announcement_image_url: "${getAnnouncementImageUrl()}"');
      Logger.debug('🔧 announcement_image_enabled: ${isAnnouncementImageEnabled()}');
      Logger.debug('🔧 announcement_image_position: "${getAnnouncementImagePosition()}"');
      Logger.debug('🔧 announcement_image_width: ${getAnnouncementImageWidth()}');
      Logger.debug('🔧 announcement_image_height: ${getAnnouncementImageHeight()}');
      Logger.debug('🔧 announcement_image_fit: "${getAnnouncementImageFit()}"');
      Logger.debug('🔧 ============================');
      
    } catch (e) {
      Logger.error('❌ Remote Config debug print hatası: $e', error: e);
    }
  }
}
