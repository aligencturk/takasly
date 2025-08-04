import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/logger.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Test ID'leri - Production'da gerçek ID'lerle değiştirilecek
  static const String _androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String _iosAppId = 'ca-app-pub-3940256099942544~1458002511';
  
  // Test Native Advanced Ad ID'leri
  static const String _androidNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _iosNativeAdUnitId = 'ca-app-pub-3940256099942544/3985214057';

  bool _isInitialized = false;
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasFailed = false;
  bool _isLoading = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  
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
        Logger.warning('⚠️ AdMobService - WidgetsBinding henüz hazır değil, bekleniyor...');
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      // Flutter binding'in tamamen hazır olduğundan emin ol
      WidgetsFlutterBinding.ensureInitialized();
      
      // AdMob'u doğrudan başlat
      await MobileAds.instance.initialize();
      
      // Test modunu etkinleştir (sadece debug modda)
      if (kDebugMode) {
        Logger.info('🔧 AdMobService - Debug modda test cihazları ayarlanıyor...');
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: ['EMULATOR']),
        );
      }

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

  /// Native Ad Unit ID'sini al
  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return _androidNativeAdUnitId;
    } else if (Platform.isIOS) {
      return _iosNativeAdUnitId;
    }
    return _androidNativeAdUnitId; // Default
  }

  /// Native reklam yükle (performans optimizasyonlu)
  Future<void> loadNativeAd() async {
    if (!_isInitialized) {
      Logger.info('🔄 AdMobService - AdMob başlatılmamış, başlatılıyor...');
      await initialize();
    }

    // Eğer zaten yükleniyorsa, bekle
    if (_isLoading) {
      Logger.debug('🔄 AdMobService - Reklam zaten yükleniyor, bekle...');
      return;
    }

    // Eğer daha önce hata aldıysak ve maksimum deneme sayısına ulaştıysak, tekrar deneme
    if (_hasFailed && _retryCount >= _maxRetries) {
      Logger.warning('⚠️ AdMobService - Maksimum deneme sayısına ulaşıldı, reklam yüklenmeyecek');
      return;
    }

    // Eğer reklam zaten yüklüyse ve geçerliyse, yeni reklam yükleme
    if (_isAdLoaded && _nativeAd != null && _isAdValid()) {
      Logger.debug('ℹ️ AdMobService - Reklam zaten yüklü ve geçerli');
      return;
    }

    _isLoading = true;
    _retryCount++;

    try {
      Logger.info('🚀 AdMobService - Native reklam yükleniyor... (Deneme: $_retryCount)');
      
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

      // Reklam oluştur
      _nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        factoryId: 'listTile',
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            Logger.info('✅ AdMobService - Native reklam basariyla yuklendi');
            _isAdLoaded = true;
            _hasFailed = false;
            _retryCount = 0; // Başarılı yüklemede sayacı sıfırla
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error('❌ AdMobService - Native reklam yuklenemedi: ${error.message}');
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
        Logger.warning('⚠️ AdMobService - nativeAd mevcut ama _isAdLoaded false, duzeltiliyor...');
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