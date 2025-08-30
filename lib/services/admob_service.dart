import 'dart:io';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:takasly/utils/logger.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();





  bool _isInitialized = false;

  // Native Ad değişkenleri
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasFailed = false;
  bool _isLoading = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5; // iOS için daha fazla deneme
  static const Duration _retryDelay = Duration(seconds: 10); // iOS için daha uzun bekleme

  // Rewarded Ad değişkenleri
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  bool _isRewardedAdLoading = false;
  bool _rewardedAdFailed = false;
  int _rewardedAdRetryCount = 0;

  // Production mode rate limiting
  DateTime? _lastAdRequest;
  static const Duration _minRequestInterval = Duration(
    seconds: 3,
  ); // Production'da minimum 3 saniye bekle

  // Thread güvenliği için mutex
  final Completer<void> _initCompleter = Completer<void>();
  bool _isInitializing = false;

  // Ödüllü reklam otomatik yükleme kontrolü
  bool _autoReloadRewardedAd = true;

  /// AdMob'u başlat
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }

    _isInitializing = true;

    try {

      // WidgetsFlutterBinding'in hazır olduğundan emin ol
      if (!WidgetsBinding.instance.isRootWidgetAttached) {
        
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Flutter binding'in tamamen hazır olduğundan emin ol
      WidgetsFlutterBinding.ensureInitialized();

      // AdMob'u doğrudan başlat
      await MobileAds.instance.initialize();

      // ExoPlayer/AudioTrack loglarını ve arka plan sesini azaltmak için uygulama seviyesinde reklam sesini kapat
      try {
        await MobileAds.instance.setAppMuted(true);
        await MobileAds.instance.setAppVolume(0.0);
      } catch (e) {
      
      }

      // GEÇİCİ TEST modunda config - Production reklamlar aktif olduğunda kaldır
      RequestConfiguration requestConfig = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        maxAdContentRating: MaxAdContentRating.pg,
        // Test mode için test device ekle (gerekirse)
        testDeviceIds: [], // Geçici olarak boş - gerçek cihazda test için
      );

      await MobileAds.instance.updateRequestConfiguration(requestConfig);

      _isInitialized = true;
      _initCompleter.complete();
      
      // Platform bilgilerini logla
      if (Platform.isIOS) {
      } else if (Platform.isAndroid) {
      }
    } catch (e) {
      _isInitialized = false;
      _initCompleter.completeError(e);
    } finally {
      _isInitializing = false;
    }
  }


  /// Native Ad Unit ID'sini al (Production only)
  String get nativeAdUnitId {
    // GEÇİCİ TEST - AdMob production reklam birimleri henüz aktif değilse
    // TODO: Production reklamlar aktif olduğunda bu kısmı kaldır!
    if (Platform.isAndroid) {
      // Geçici test - Production: _androidNativeAdUnitIdProd
      final id = 'ca-app-pub-3940256099942544/2247696110'; // TEST NATIVE
      return id;
    } else if (Platform.isIOS) {
      // Geçici test - Production: _iosNativeAdUnitIdProd
      final id = 'ca-app-pub-3940256099942544/3986624511'; // TEST NATIVE iOS
      return id;
    }
    return 'ca-app-pub-3940256099942544/2247696110'; // Default test
  }

  /// Banner Ad Unit ID'sini al (Production only)
  String get bannerAdUnitId {
    // GEÇİCİ TEST - AdMob production reklam birimleri henüz aktif değilse
    // TODO: Production reklamlar aktif olduğunda bu kısmı kaldır!
    if (Platform.isAndroid) {
      // Geçici test - Production: _androidBannerAdUnitIdProd
      final id = 'ca-app-pub-3940256099942544/6300978111'; // TEST BANNER
      return id;
    } else if (Platform.isIOS) {
      // Geçici test - Production: _iosBannerAdUnitIdProd  
      final id = 'ca-app-pub-3940256099942544/2934735716'; // TEST BANNER iOS
      return id;
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // Default test
  }

  /// Rewarded Ad Unit ID'sini al (Production only)
  String get rewardedAdUnitId {
    // GEÇİCİ TEST - AdMob production reklam birimleri henüz aktif değilse
    // TODO: Production reklamlar aktif olduğunda bu kısmı kaldır!
    if (Platform.isAndroid) {
      // Geçici test - Production: _androidRewardedAdUnitIdProd
      final id = 'ca-app-pub-3940256099942544/5224354917'; // TEST REWARDED
      return id;
    } else if (Platform.isIOS) {
      // Geçici test - Production: _iosRewardedAdUnitIdProd
      final id = 'ca-app-pub-3940256099942544/1712485313'; // TEST REWARDED iOS
      return id;
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // Default test
  }

  /// Native reklam yükle (performans optimizasyonlu)
  Future<void> loadNativeAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Production modda rate limiting kontrolü
    if (_lastAdRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastAdRequest!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }

    // Eğer zaten yükleniyorsa, bekle
    if (_isLoading) {
      return;
    }

    // Eğer daha önce hata aldıysak ve maksimum deneme sayısına ulaştıysak, tekrar deneme
    if (_hasFailed && _retryCount >= _maxRetries) {
   
      return;
    }

    // Eğer reklam zaten yüklüyse ve geçerliyse, yeni reklam yükleme
    if (_isAdLoaded && _nativeAd != null && _isAdValid()) {
      return;
    }

    // Request zamanını kaydet
    _lastAdRequest = DateTime.now();

    _isLoading = true;
    _retryCount++;

    try {
  

      // Reklam yükleme işlemini arka planda yap
      await _loadAdInBackground();
    } catch (e) {
    
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

      // GEÇİCİ TEST için optimize edilmiş request
      AdRequest adRequest = const AdRequest(
        // Test reklamları için basit metadata
        keywords: [
          'takasly',
          'takas',
          'ilan',
          'ürün',
          'test', // Test için eklendi
        ],
        nonPersonalizedAds: false, // Test reklamlarda personalization
      );

      // Reklam oluştur
      _nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        factoryId: 'listTile',
        request: adRequest,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
          
            _isAdLoaded = true;
            _hasFailed = false;
            _retryCount = 0; // Başarılı yüklemede sayacı sıfırla
          },
          onAdFailedToLoad: (ad, error) {
            
            
            // iOS için özel hata yönetimi
            if (Platform.isIOS) {
              
            }
            
            _handleLoadError();
            _safeDisposeAd(ad as NativeAd);
          },
          onAdClicked: (ad) {
           
          },
          onAdImpression: (ad) {
           
          },
          onAdOpened: (ad) {
           
          },
          onAdClosed: (ad) {
           
          },
        ),
      );

      // Reklam yükleme işlemini UI thread'i bloklamayacak şekilde yap
      await _nativeAd!.load().timeout(
        const Duration(seconds: 15), // iOS için daha uzun timeout
        onTimeout: () {
          throw TimeoutException('Reklam yukleme zaman asimi');
        },
      );
    } catch (e) {
      
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
      
      try {
        _nativeAd!.dispose();
      } catch (e) {
        
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
        
        _isAdLoaded = true;
      }
      return _isAdLoaded && _isAdValid();
    } catch (e) {
      
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
      
      return null;
    }
  }

  /// Ödüllü reklam yükle
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) {
      
      await initialize();
    }

    // Eğer zaten yükleniyorsa veya yüklüyse, bekle
    if (_isRewardedAdLoading) {
      
      return;
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      
      return;
    }

    // Maksimum deneme sayısına ulaştıysak, çık
    if (_rewardedAdFailed && _rewardedAdRetryCount >= _maxRetries) {
     
      return;
    }

    _isRewardedAdLoading = true;
    _rewardedAdRetryCount++;

    try {
     

      // Eski reklamı temizle
      if (_rewardedAd != null) {
        _rewardedAd!.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
      }

      // AdRequest oluştur - GEÇİCİ TEST modu
      AdRequest adRequest = const AdRequest(
        keywords: ['takasly', 'takas', 'ilan', 'ürün', 'test'],
        nonPersonalizedAds: false,
      );

      // Ödüllü reklam yükle
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {

            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _rewardedAdFailed = false;
            _rewardedAdRetryCount = 0;
            _isRewardedAdLoading = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
    
            
            // iOS için özel hata yönetimi
            if (Platform.isIOS) {
            
            }
            
            _rewardedAdFailed = true;
            _isRewardedAdLoaded = false;
            _isRewardedAdLoading = false;

            // Retry logic
            if (_rewardedAdRetryCount < _maxRetries) {
             
              Timer(_retryDelay, () => loadRewardedAd());
            }
          },
        ),
      );
    } catch (e) {
    
      _rewardedAdFailed = true;
      _isRewardedAdLoaded = false;
      _isRewardedAdLoading = false;
    }
  }

  /// Ödüllü reklamı göster
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      Logger.warning('⚠️ AdMobService - Ödüllü reklam yüklenmemiş');
      return false;
    }

    bool rewardEarned = false;
    final completer = Completer<bool>();

    try {
      Logger.info('🎬 AdMobService - Ödüllü reklam gösteriliyor...');

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          Logger.info('🎬 AdMobService - Ödüllü reklam tam ekran gösterildi');
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          Logger.info('🎬 AdMobService - Ödüllü reklam kapatıldı, ödül: $rewardEarned');
          
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;

          // Sonucu döndür
          if (!completer.isCompleted) {
            completer.complete(rewardEarned);
          }

          // Sadece ödül kazanıldıysa otomatik yeni reklam yükle
          if (_autoReloadRewardedAd && rewardEarned) {
            Logger.info('🔄 AdMobService - Ödül kazanıldı, yeni reklam yükleniyor...');
            Future.microtask(() => loadRewardedAd());
          } else {
            Logger.info('⏸️ AdMobService - Ödül kazanılmadı, otomatik reklam yükleme durduruldu');
          }
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          Logger.error('❌ AdMobService - Ödüllü reklam gösterilemedi: ${error.message}');
          
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;

          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          Logger.info('🎉 AdMobService - Ödül kazanıldı: ${reward.amount} ${reward.type}');
          rewardEarned = true;
        },
      );
    } catch (e) {
      Logger.error('❌ AdMobService - Ödüllü reklam gösterme hatası: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  /// Ödüllü reklamın yüklenip yüklenmediğini kontrol et
  bool get isRewardedAdLoaded => _isRewardedAdLoaded && _rewardedAd != null;

  /// Ödüllü reklam yüklenme durumunu kontrol et
  bool get isRewardedAdLoading => _isRewardedAdLoading;

  /// Reklamı temizle
  void dispose() {
   
    _retryTimer?.cancel();
    _disposeCurrentAd();

    // Ödüllü reklamı da temizle
    if (_rewardedAd != null) {
      _rewardedAd!.dispose();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    }
  }

  /// Yeni reklam yükle (mevcut reklamı temizleyip)
  Future<void> reloadAd() async {
   
    _retryTimer?.cancel();
    _retryCount = 0;
    _hasFailed = false;
    await _disposeCurrentAd();
    await loadNativeAd();
  }

  /// Hata durumunu sıfırla (yeniden deneme için)
  void resetFailedState() {
  
    _retryTimer?.cancel();
    _hasFailed = false;
    _retryCount = 0;
    _rewardedAdFailed = false;
    _rewardedAdRetryCount = 0;
  }

  /// Yükleme durumunu kontrol et
  bool get isLoading => _isLoading;

  /// Ödüllü reklam otomatik yükleme durumunu kontrol et
  bool get autoReloadRewardedAd => _autoReloadRewardedAd;
  
  /// Ödüllü reklam otomatik yükleme durumunu ayarla
  void setAutoReloadRewardedAd(bool enabled) {
    _autoReloadRewardedAd = enabled;
    Logger.info('🔄 AdMobService - Ödüllü reklam otomatik yükleme: ${enabled ? "açık" : "kapalı"}');
  }
  
  /// Ödüllü reklamı manuel olarak yeniden yükle
  Future<void> reloadRewardedAd() async {
    Logger.info('🔄 AdMobService - Ödüllü reklam manuel olarak yeniden yükleniyor...');
    await loadRewardedAd();
  }
}
