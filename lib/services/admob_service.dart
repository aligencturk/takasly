/*
 * AdMob Service - Test ve Production reklamları yönetimi
 * 
 * KULLANIM:
 * 1. Test yaparken: _useTestAds = true
 * 2. Production'a geçerken: _useTestAds = false (ŞU ANDA AKTİF)
 * 
 * ⚠️ PRODUCTION MOD AKTİF:
 * - Gerçek reklamlar gösterilir
 * - Rate limiting aktif (3 saniye minimum interval)
 * - AdMob politikalarına uygun olmalıdır
 * - Test cihazları tanımlanmamış
 * 
 * Test ID'leri her zaman çalışır, production ID'leri onaylanmalıdır.
 */
import 'dart:io';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/logger.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // App IDs (bilgi amaçlı)
  static const String _androidAppId =
      'ca-app-pub-3600325889588673~2182319863'; // Prod (AndroidManifest.xml'de de tanımlı)
  static const String _iosAppId =
      'ca-app-pub-3600325889588673~5340558560'; // Prod (Info.plist'den kullanılıyor)

  // Test Ad Unit IDs (geliştirme ve test için)
  static const String _androidNativeAdUnitIdTest =
      'ca-app-pub-3940256099942544/2247696110'; // Google test native ID
  static const String _iosNativeAdUnitIdTest =
      'ca-app-pub-3940256099942544/3986624511'; // Google test native ID

  static const String _androidBannerAdUnitIdTest =
      'ca-app-pub-3940256099942544/6300978111'; // Google test banner ID
  static const String _iosBannerAdUnitIdTest =
      'ca-app-pub-3940256099942544/2934735716'; // Google test banner ID

  // Production Ad Unit IDs
  static const String _androidNativeAdUnitIdProd =
      'ca-app-pub-3600325889588673/5822213790'; // Gerçek Android prod ID
  static const String _iosNativeAdUnitIdProd =
      'ca-app-pub-3600325889588673/1202018911';

  static const String _androidBannerAdUnitIdProd =
      'ca-app-pub-3600325889588673/7805712447';
  static const String _iosBannerAdUnitIdProd =
      'ca-app-pub-3600325889588673/3365147820'; // iOS production banner ID

  // Debug/Test modu kontrolü
  static const bool _useTestAds = false; // PRODUCTION: Gerçek reklamları kullan

  bool _isInitialized = false;
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasFailed = false;
  bool _isLoading = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  // Production mode rate limiting
  DateTime? _lastAdRequest;
  static const Duration _minRequestInterval = Duration(seconds: 3); // Production'da minimum 3 saniye bekle

  // Thread güvenliği için mutex
  final Completer<void> _initCompleter = Completer<void>();
  bool _isInitializing = false;

  /// AdMob'u başlat
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.debug('ℹ️ AdMobService - AdMob zaten başlatılmış');
      return;
    }

    if (_isInitializing) {
      Logger.debug('🔄 AdMobService - AdMob zaten başlatılıyor, bekle...');
      await _initCompleter.future;
      return;
    }

    _isInitializing = true;

    try {
      Logger.info('🚀 AdMobService - AdMob başlatılıyor...');

      // WidgetsFlutterBinding'in hazır olduğundan emin ol
      if (!WidgetsBinding.instance.isRootWidgetAttached) {
        Logger.warning(
          '⚠️ AdMobService - WidgetsBinding henüz hazır değil, bekleniyor...',
        );
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Flutter binding'in tamamen hazır olduğundan emin ol
      WidgetsFlutterBinding.ensureInitialized();

      // AdMob'u doğrudan başlat
      await MobileAds.instance.initialize();

      // Production modda daha detaylı request configuration
      RequestConfiguration requestConfig;
      
      if (_useTestAds) {
        // Test modda basit config
        requestConfig = RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
          maxAdContentRating: MaxAdContentRating.pg,
        );
      } else {
        // Production modda gelişmiş config
        requestConfig = RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
          maxAdContentRating: MaxAdContentRating.pg,
          // Production için ek ayarlar
          testDeviceIds: [], // Boş liste - production için test cihazı yok
        );
      }

      await MobileAds.instance.updateRequestConfiguration(requestConfig);

      _isInitialized = true;
      _initCompleter.complete();
      Logger.info('✅ AdMobService - AdMob başarıyla başlatıldı');
    } catch (e) {
      Logger.error('❌ AdMobService - AdMob başlatılırken hata: $e');
      _isInitialized = false;
      _initCompleter.completeError(e);
    } finally {
      _isInitializing = false;
    }
  }

  /// Uygulama ID'sini al
  String get appId {
    if (Platform.isAndroid) {
      return _androidAppId;
    } else if (Platform.isIOS) {
      return _iosAppId;
    }
    return _androidAppId; // Default
  }

  /// Native Ad Unit ID'sini al (Test/Production seçimi ile)
  String get nativeAdUnitId {
    if (_useTestAds) {
      // Test reklamları kullan
      if (Platform.isAndroid) {
        final id = _androidNativeAdUnitIdTest;
        Logger.info('📡 AdMobService - Android TEST NativeAdUnitId: $id');
        return id;
      } else if (Platform.isIOS) {
        final id = _iosNativeAdUnitIdTest;
        Logger.info('📡 AdMobService - iOS TEST NativeAdUnitId: $id');
        return id;
      }
      return _androidNativeAdUnitIdTest; // Default test
    } else {
      // Production reklamları kullan
      if (Platform.isAndroid) {
        final id = _androidNativeAdUnitIdProd;
        Logger.info('📡 AdMobService - Android PROD NativeAdUnitId: $id');
        return id;
      } else if (Platform.isIOS) {
        final id = _iosNativeAdUnitIdProd;
        Logger.info('📡 AdMobService - iOS PROD NativeAdUnitId: $id');
        return id;
      }
      return _androidNativeAdUnitIdProd; // Default prod
    }
  }

  /// Banner Ad Unit ID'sini al (Test/Production seçimi ile)
  String get bannerAdUnitId {
    if (_useTestAds) {
      // Test reklamları kullan
      if (Platform.isAndroid) {
        final id = _androidBannerAdUnitIdTest;
        Logger.info('📡 AdMobService - Android TEST BannerAdUnitId: $id');
        return id;
      } else if (Platform.isIOS) {
        final id = _iosBannerAdUnitIdTest;
        Logger.info('📡 AdMobService - iOS TEST BannerAdUnitId: $id');
        return id;
      }
      return _androidBannerAdUnitIdTest; // Default test
    } else {
      // Production reklamları kullan
      if (Platform.isAndroid) {
        final id = _androidBannerAdUnitIdProd;
        Logger.info('📡 AdMobService - Android PROD BannerAdUnitId: $id');
        return id;
      } else if (Platform.isIOS) {
        final id = _iosBannerAdUnitIdProd;
        Logger.info('📡 AdMobService - iOS PROD BannerAdUnitId: $id');
        return id;
      }
      return _androidBannerAdUnitIdProd; // Default prod
    }
  }

  /// Native reklam yükle (performans optimizasyonlu)
  Future<void> loadNativeAd() async {
    if (!_isInitialized) {
      Logger.info('🔄 AdMobService - AdMob başlatılmamış, başlatılıyor...');
      await initialize();
    }

    // Production modda rate limiting kontrolü
    if (!_useTestAds && _lastAdRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastAdRequest!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        Logger.info('⏱️ AdMobService - Production rate limiting: ${waitTime.inSeconds}s bekleniyor...');
        await Future.delayed(waitTime);
      }
    }

    // Eğer zaten yükleniyorsa, bekle
    if (_isLoading) {
      Logger.debug('🔄 AdMobService - Reklam zaten yükleniyor, bekle...');
      return;
    }

    // Eğer daha önce hata aldıysak ve maksimum deneme sayısına ulaştıysak, tekrar deneme
    if (_hasFailed && _retryCount >= _maxRetries) {
      Logger.warning(
        '⚠️ AdMobService - Maksimum deneme sayısına ulaşıldı, reklam yüklenmeyecek',
      );
      return;
    }

    // Eğer reklam zaten yüklüyse ve geçerliyse, yeni reklam yükleme
    if (_isAdLoaded && _nativeAd != null && _isAdValid()) {
      Logger.debug('ℹ️ AdMobService - Reklam zaten yüklü ve geçerli');
      return;
    }

    // Request zamanını kaydet
    _lastAdRequest = DateTime.now();

    _isLoading = true;
    _retryCount++;

    try {
      Logger.info(
        '🚀 AdMobService - Native reklam yükleniyor... (Deneme: $_retryCount)',
      );

      // Reklam yükleme işlemini arka planda yap
      await _loadAdInBackground();
    } catch (e) {
      Logger.error('❌ AdMobService - Native reklam yüklenirken hata: $e');
      _handleLoadError();
    } finally {
      _isLoading = false;
    }
  }

  // Reklamın geçerli olup olmadığını kontrol et
  bool _isAdValid() {
    try {
      if (_nativeAd == null) return false;

      // Reklamın durumunu kontrol et - daha detaylı kontrol
      if (!_isAdLoaded) return false;

      return true;
    } catch (e) {
      Logger.error('❌ AdMobService - Reklam gecerlilik kontrolu hatasi: $e');
      return false;
    }
  }

  // Arka planda reklam yükleme
  Future<void> _loadAdInBackground() async {
    try {
      // Eğer eski reklam varsa temizle
      if (_nativeAd != null) {
        await _disposeCurrentAd();
      }

      // Production'da özel request configuration
      AdRequest adRequest;
      
      if (_useTestAds) {
        // Test modda standart request
        adRequest = const AdRequest();
      } else {
        // Production modda optimize edilmiş request
        adRequest = const AdRequest(
          // Production için ekstra metadata
          keywords: ['takasly', 'takas', 'ilan', 'ürün'], // Uygulama ile ilgili keywords
          nonPersonalizedAds: false, // Personalize edilmiş reklamlar
        );
      }

      // Reklam oluştur
      _nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        factoryId: 'listTile',
        request: adRequest,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            Logger.info('✅ AdMobService - Native reklam basariyla yuklendi');
            _isAdLoaded = true;
            _hasFailed = false;
            _retryCount = 0; // Başarılı yüklemede sayacı sıfırla
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ AdMobService - Native reklam yuklenemedi: ${error.message}',
            );
            Logger.error('❌ AdMobService - Error code: ${error.code}');
            _handleLoadError();
            _safeDisposeAd(ad as NativeAd);
          },
          onAdClicked: (ad) {
            Logger.info('👆 AdMobService - Native reklam tiklandi');
          },
          onAdImpression: (ad) {
            Logger.info('👁️ AdMobService - Native reklam gosterildi');
          },
          onAdOpened: (ad) {
            Logger.info('🚪 AdMobService - Native reklam acildi');
          },
          onAdClosed: (ad) {
            Logger.info('🚪 AdMobService - Native reklam kapandi');
          },
        ),
      );

      // Reklam yükleme işlemini UI thread'i bloklamayacak şekilde yap
      await _nativeAd!.load().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Reklam yukleme zaman asimi');
        },
      );
    } catch (e) {
      Logger.error('❌ AdMobService - Arka plan reklam yukleme hatasi: $e');
      // Hata durumunda reklamı temizle
      await _disposeCurrentAd();
      rethrow;
    }
  }

  // Güvenli reklam dispose etme
  void _safeDisposeAd(NativeAd ad) {
    try {
      ad.dispose();
    } catch (e) {
      Logger.error('❌ AdMobService - Güvenli reklam dispose hatası: $e');
    }
  }

  // Hata durumunu işle
  void _handleLoadError() {
    _isAdLoaded = false;
    _hasFailed = true;

    // Hata durumunda reklamı temizle
    _disposeCurrentAd();

    // Eğer maksimum deneme sayısına ulaşmadıysak, tekrar dene
    if (_retryCount < _maxRetries) {
      Logger.info('🔄 AdMobService - $_retryDelay sonra tekrar denenecek...');
      _retryTimer?.cancel();
      _retryTimer = Timer(_retryDelay, () {
        if (!_isLoading) {
          loadNativeAd();
        }
      });
    }
  }

  // Mevcut reklamı temizle
  Future<void> _disposeCurrentAd() async {
    if (_nativeAd != null) {
      Logger.debug('🧹 AdMobService - Eski reklam temizleniyor...');
      try {
        _nativeAd!.dispose();
      } catch (e) {
        Logger.error('❌ AdMobService - Reklam temizleme hatası: $e');
      }
      _nativeAd = null;
      _isAdLoaded = false;
    }
  }

  /// Native reklamın yüklenip yüklenmediğini kontrol et
  bool get isAdLoaded {
    try {
      // Eğer nativeAd objesi varsa ama _isAdLoaded false ise, true döndür
      if (_nativeAd != null && !_isAdLoaded && _isAdValid()) {
        Logger.warning(
          '⚠️ AdMobService - nativeAd mevcut ama _isAdLoaded false, duzeltiliyor...',
        );
        _isAdLoaded = true;
      }
      return _isAdLoaded && _isAdValid();
    } catch (e) {
      Logger.error('❌ AdMobService - isAdLoaded getter hatasi: $e');
      return false;
    }
  }

  /// Native reklamı al (güvenli)
  NativeAd? get nativeAd {
    try {
      if (_nativeAd != null && _isAdValid()) {
        return _nativeAd;
      }
      return null;
    } catch (e) {
      Logger.error('❌ AdMobService - nativeAd getter hatası: $e');
      return null;
    }
  }

  /// Reklamı temizle
  void dispose() {
    Logger.debug('🧹 AdMobService - Reklam temizleniyor...');
    _retryTimer?.cancel();
    _disposeCurrentAd();
  }

  /// Yeni reklam yükle (mevcut reklamı temizleyip)
  Future<void> reloadAd() async {
    Logger.info('🔄 AdMobService - Reklam yeniden yükleniyor...');
    _retryTimer?.cancel();
    _retryCount = 0;
    _hasFailed = false;
    await _disposeCurrentAd();
    await loadNativeAd();
  }

  /// Hata durumunu sıfırla (yeniden deneme için)
  void resetFailedState() {
    Logger.info('🔄 AdMobService - Hata durumu sıfırlanıyor...');
    _retryTimer?.cancel();
    _hasFailed = false;
    _retryCount = 0;
  }

  /// Yükleme durumunu kontrol et
  bool get isLoading => _isLoading;
}
