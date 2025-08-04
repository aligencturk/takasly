import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

class AdViewModel extends ChangeNotifier {
  final AdMobService _adMobService = AdMobService();
  
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  int _productCount = 0;
  int _adFrequency = 4; // Her 4 üründen sonra 1 reklam
  int _lastAdIndex = -1;

  bool get isAdLoaded => _isAdLoaded;
  bool get isLoadingAd => _isLoadingAd;
  int get productCount => _productCount;
  int get adFrequency => _adFrequency;

  /// AdMob'u başlat
  Future<void> initializeAdMob() async {
    try {
      Logger.info('🚀 AdViewModel - AdMob başlatılıyor...');
      await _adMobService.initialize();
      await loadAd();
    } catch (e) {
      Logger.error('❌ AdViewModel - AdMob başlatılırken hata: $e');
    }
  }

  /// Reklam yükle
  Future<void> loadAd() async {
    if (_isLoadingAd) return;

    try {
      _isLoadingAd = true;
      // Build sırasında notifyListeners çağırmamak için güvenli şekilde çağır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      await _adMobService.loadNativeAd();
      
      _isAdLoaded = _adMobService.isAdLoaded;
    } catch (e) {
      Logger.error('❌ AdViewModel - Reklam yüklenirken hata: $e');
      _isAdLoaded = false;
    } finally {
      _isLoadingAd = false;
      // Build sırasında notifyListeners çağırmamak için güvenli şekilde çağır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Ürün sayısını güncelle
  void updateProductCount(int count) {
    _productCount = count;
  }

  /// Belirtilen index'te reklam gösterilip gösterilmeyeceğini kontrol et
  bool shouldShowAdAt(int index) {
    // İlk ürünlerde reklam gösterme
    if (index < _adFrequency) return false;
    
    // Her 4 üründen sonra reklam göster (4, 8, 12, 16, ...)
    bool shouldShow = (index + 1) % _adFrequency == 0;
    
    // Aynı reklamı tekrar gösterme
    if (shouldShow && index == _lastAdIndex) {
      shouldShow = false;
    }
    
    if (shouldShow) {
      _lastAdIndex = index;
      // Reklam gösterilecekse ve yüklü değilse yükle
      if (!_isAdLoaded && !_isLoadingAd) {
        Future.microtask(() => ensureAdLoaded());
      }
    }
    
    return shouldShow;
  }

  /// Reklamın yüklenip yüklenmediğini kontrol et ve gerekirse yükle
  Future<void> ensureAdLoaded() async {
    if (!_isAdLoaded && !_isLoadingAd) {
      // State değişikliğini güvenli şekilde yap
      try {
        await loadAd();
      } catch (e) {
        // Hata durumunda tekrar deneme yapma
        Logger.error('❌ AdViewModel - ensureAdLoaded hatası: $e');
      }
    }
  }

  /// Yeni reklam yükle
  Future<void> reloadAd() async {
    try {
      await _adMobService.reloadAd();
      _isAdLoaded = _adMobService.isAdLoaded;
      notifyListeners();
    } catch (e) {
      Logger.error('❌ AdViewModel - Reklam yeniden yüklenirken hata: $e');
    }
  }

  /// Hata durumunu sıfırla ve yeniden dene
  Future<void> retryAd() async {
    try {
      _adMobService.resetFailedState();
      await loadAd();
    } catch (e) {
      Logger.error('❌ AdViewModel - Reklam yeniden deneme hatası: $e');
    }
  }

  /// AdMob servisinden native reklamı al
  get nativeAd => _adMobService.nativeAd;

  @override
  void dispose() {
    _adMobService.dispose();
    super.dispose();
  }
} 