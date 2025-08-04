import 'dart:io';
import 'package:flutter/foundation.dart';
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
  bool _hasFailed = false; // Hata durumunu takip etmek için

  /// AdMob'u başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('🚀 AdMob başlatılıyor...');
      
      await MobileAds.instance.initialize();
      
      // Test modunu etkinleştir (sadece debug modda)
      if (kDebugMode) {
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: ['EMULATOR']),
        );
      }

      _isInitialized = true;
      Logger.info('✅ AdMob başarıyla başlatıldı');
    } catch (e) {
      Logger.error('❌ AdMob başlatılırken hata: $e');
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

  /// Native reklam yükle
  Future<void> loadNativeAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Eğer daha önce hata aldıysak, tekrar deneme
    if (_hasFailed) {
      return;
    }

    try {
      Logger.info('🚀 Native reklam yükleniyor... AdUnitId: $nativeAdUnitId, FactoryId: listTile');
      
      _nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        factoryId: 'listTile', // Her iki platform için aynı factory ID kullan
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            Logger.info('✅ Native reklam başarıyla yüklendi');
            _isAdLoaded = true;
            _hasFailed = false; // Başarılı yüklemede hata durumunu sıfırla
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error('❌ Native reklam yüklenemedi: ${error.message}');
            _isAdLoaded = false;
            _hasFailed = true; // Hata durumunu işaretle
            ad.dispose();
          },
          onAdClicked: (ad) {
            Logger.info('👆 Native reklam tıklandı');
          },
          onAdImpression: (ad) {
            Logger.info('👁️ Native reklam gösterildi');
          },
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      Logger.error('❌ Native reklam yüklenirken hata: $e');
      _isAdLoaded = false;
      _hasFailed = true; // Hata durumunu işaretle
    }
  }

  /// Native reklamın yüklenip yüklenmediğini kontrol et
  bool get isAdLoaded => _isAdLoaded;

  /// Native reklamı al
  NativeAd? get nativeAd => _nativeAd;

  /// Reklamı temizle
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isAdLoaded = false;
  }

  /// Yeni reklam yükle (mevcut reklamı temizleyip)
  Future<void> reloadAd() async {
    dispose();
    _hasFailed = false; // Hata durumunu sıfırla
    await loadNativeAd();
  }

  /// Hata durumunu sıfırla (yeniden deneme için)
  void resetFailedState() {
    _hasFailed = false;
  }
} 