import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  // SharedPreferences key'leri
  static const String _announcementShownKey = 'announcement_shown';
  static const String _announcementIdKey = 'announcement_id';
  static const String _announcementImageShownKey = 'announcement_image_shown';
  static const String _announcementImageIdKey = 'announcement_image_id';

  /// Remote Config'i başlatır
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        return;
      }

      _remoteConfig = FirebaseRemoteConfig.instance;

      // Remote Config ayarları
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1), // Production ayarı
        ),
      );

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
        'announcement_image_fit':
            'cover', // cover, contain, fill, fitWidth, fitHeight
      });

      // İlk fetch işlemi
      await _fetchAndActivate();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Remote Config başlatılamadı: $e');
    }
  }

  /// Uzaktan yapılandırma verilerini çeker ve aktifleştirir
  Future<bool> _fetchAndActivate() async {
    try {
      final bool updated = await _remoteConfig!.fetchAndActivate();
      return updated;
    } catch (e) {
      return false;
    }
  }

  /// Manuel olarak yapılandırma verilerini yeniler
  Future<bool> refresh() async {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        await initialize();
      }

      return await _fetchAndActivate();
    } catch (e) {
      return false;
    }
  }

  /// Duyuru metnini getirir
  String getAnnouncementText() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
        return '';
      }

      final text = _remoteConfig!.getString('announcement_text');
      Logger.debug(
        '📢 Duyuru metni alındı: ${text.isNotEmpty ? "Mevcut" : "Boş"}',
      );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
        return '';
      }

      final url = _remoteConfig!.getString('announcement_image_url');
      Logger.debug(
        '🖼️ Duyuru resim URL alındı: ${url.isNotEmpty ? "Mevcut" : "Boş"}',
      );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
        return 'top';
      }

      final position = _remoteConfig!.getString('announcement_image_position');
      final validPositions = ['top', 'bottom', 'background'];
      final finalPosition = validPositions.contains(position)
          ? position
          : 'top';
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue',
        );
        return defaultValue;
      }

      final value = _remoteConfig!.getString(key);
      Logger.debug(
        '🔧 Remote Config değer alındı [$key]: ${value.isNotEmpty ? "Mevcut" : "Boş"}',
      );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue',
        );
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
        Logger.warning(
          '⚠️ Remote Config henüz başlatılmamış, varsayılan değer döndürülüyor: $defaultValue',
        );
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

  /// Kullanıcının duyuruyu görüp görmediğini kontrol eder
  Future<bool> hasUserSeenAnnouncement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_announcementShownKey) ?? false;
      Logger.debug(
        '🔍 Kullanıcı duyuru durumu: ${hasSeen ? "Görmüş" : "Görmemiş"}',
      );
      return hasSeen;
    } catch (e) {
      Logger.error('❌ Duyuru görülme durumu kontrol hatası: $e', error: e);
      return false;
    }
  }

  /// Kullanıcının resimli duyuruyu görüp görmediğini kontrol eder
  Future<bool> hasUserSeenAnnouncementImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_announcementImageShownKey) ?? false;
      Logger.debug(
        '🔍 Kullanıcı resimli duyuru durumu: ${hasSeen ? "Görmüş" : "Görmemiş"}',
      );
      return hasSeen;
    } catch (e) {
      Logger.error(
        '❌ Resimli duyuru görülme durumu kontrol hatası: $e',
        error: e,
      );
      return false;
    }
  }

  /// Duyuru ID'sini kontrol eder (yeni duyuru mu?)
  Future<bool> isNewAnnouncement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentId = getAnnouncementText().hashCode.toString();
      final savedId = prefs.getString(_announcementIdKey);

      final isNew = savedId != currentId;
      Logger.debug(
        '🔍 Duyuru ID kontrolü: ${isNew ? "Yeni duyuru" : "Eski duyuru"} (Saved: $savedId, Current: $currentId)',
      );
      return isNew;
    } catch (e) {
      Logger.error('❌ Duyuru ID kontrol hatası: $e', error: e);
      return true; // Hata durumunda yeni olarak kabul et
    }
  }

  /// Resimli duyuru ID'sini kontrol eder (yeni resimli duyuru mu?)
  Future<bool> isNewAnnouncementImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentId = getAnnouncementImageUrl().hashCode.toString();
      final savedId = prefs.getString(_announcementImageIdKey);

      final isNew = savedId != currentId;
      Logger.debug(
        '🔍 Resimli duyuru ID kontrolü: ${isNew ? "Yeni resim" : "Eski resim"} (Saved: $savedId, Current: $currentId)',
      );
      return isNew;
    } catch (e) {
      Logger.error('❌ Resimli duyuru ID kontrol hatası: $e', error: e);
      return true; // Hata durumunda yeni olarak kabul et
    }
  }

  /// Duyuruyu görüldü olarak işaretler
  Future<void> markAnnouncementAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentId = getAnnouncementText().hashCode.toString();

      await prefs.setBool(_announcementShownKey, true);
      await prefs.setString(_announcementIdKey, currentId);

      Logger.info('✅ Duyuru görüldü olarak işaretlendi (ID: $currentId)');
    } catch (e) {
      Logger.error('❌ Duyuru işaretleme hatası: $e', error: e);
    }
  }

  /// Resimli duyuruyu görüldü olarak işaretler
  Future<void> markAnnouncementImageAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentId = getAnnouncementImageUrl().hashCode.toString();

      await prefs.setBool(_announcementImageShownKey, true);
      await prefs.setString(_announcementImageIdKey, currentId);

      Logger.info(
        '✅ Resimli duyuru görüldü olarak işaretlendi (ID: $currentId)',
      );
    } catch (e) {
      Logger.error('❌ Resimli duyuru işaretleme hatası: $e', error: e);
    }
  }

  /// Duyuru gösterim durumunu sıfırlar (test için)
  Future<void> resetAnnouncementSeenStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_announcementShownKey);
      await prefs.remove(_announcementIdKey);
      await prefs.remove(_announcementImageShownKey);
      await prefs.remove(_announcementImageIdKey);

      Logger.info('🔄 Duyuru görülme durumları sıfırlandı');
    } catch (e) {
      Logger.error('❌ Duyuru durumu sıfırlama hatası: $e', error: e);
    }
  }

  /// Duyuru gösterilip gösterilmeyeceğini kontrol eder
  Future<bool> shouldShowAnnouncement() async {
    try {
      // Duyuru aktif değilse gösterme
      if (!isAnnouncementEnabled() && !isAnnouncementImageEnabled()) {
        Logger.debug('🔍 Duyuru gösterim kontrolü: Duyuru aktif değil');
        return false;
      }

      // Metin duyurusu varsa kontrol et
      if (isAnnouncementEnabled() && getAnnouncementText().isNotEmpty) {
        final hasSeen = await hasUserSeenAnnouncement();
        final isNew = await isNewAnnouncement();

        if (hasSeen && !isNew) {
          Logger.debug(
            '🔍 Metin duyurusu gösterim kontrolü: Kullanıcı zaten görmüş',
          );
          return false;
        }
      }

      // Resimli duyuru varsa kontrol et
      if (isAnnouncementImageEnabled() &&
          getAnnouncementImageUrl().isNotEmpty) {
        final hasSeenImage = await hasUserSeenAnnouncementImage();
        final isNewImage = await isNewAnnouncementImage();

        if (hasSeenImage && !isNewImage) {
          Logger.debug(
            '🔍 Resimli duyuru gösterim kontrolü: Kullanıcı zaten görmüş',
          );
          return false;
        }
      }

      Logger.debug('🔍 Duyuru gösterim kontrolü: Gösterilecek');
      return true;
    } catch (e) {
      Logger.error('❌ Duyuru gösterim kontrolü hatası: $e', error: e);
      return false;
    }
  }

  /// Tüm Remote Config verilerini debug için loglar
  void debugPrintAllValues() {
    try {
      if (!_isInitialized || _remoteConfig == null) {
        Logger.debug(
          '🔧 Remote Config henüz başlatılmamış, debug bilgisi alınamıyor',
        );
        return;
      }

      Logger.debug('🔧 === Remote Config Debug ===');
      Logger.debug('🔧 announcement_text: "${getAnnouncementText()}"');
      Logger.debug('🔧 announcement_enabled: ${isAnnouncementEnabled()}');
      Logger.debug('🔧 announcement_title: "${getAnnouncementTitle()}"');
      Logger.debug(
        '🔧 announcement_button_text: "${getAnnouncementButtonText()}"',
      );
      Logger.debug('🔧 --- Resim Özellikleri ---');
      Logger.debug('🔧 announcement_image_url: "${getAnnouncementImageUrl()}"');
      Logger.debug(
        '🔧 announcement_image_enabled: ${isAnnouncementImageEnabled()}',
      );
      Logger.debug(
        '🔧 announcement_image_position: "${getAnnouncementImagePosition()}"',
      );
      Logger.debug(
        '🔧 announcement_image_width: ${getAnnouncementImageWidth()}',
      );
      Logger.debug(
        '🔧 announcement_image_height: ${getAnnouncementImageHeight()}',
      );
      Logger.debug('🔧 announcement_image_fit: "${getAnnouncementImageFit()}"');
      Logger.debug('🔧 ============================');
    } catch (e) {
      Logger.error('❌ Remote Config debug print hatası: $e', error: e);
    }
  }
}
