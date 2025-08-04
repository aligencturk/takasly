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
  bool _isInitialized = false;

  bool get isAdLoaded => _isAdLoaded;
  bool get isLoadingAd => _isLoadingAd;
  int get productCount => _productCount;
  int get adFrequency => _adFrequency;

  /// AdMob'u başlat (performans optimizasyonlu)
  Future<void> initializeAdMob() async {
    if (_isInitialized) {
      Logger.debug('ℹ️ AdViewModel - AdMob zaten başlatılmış');
      return;
    }

    try {
      Logger.info('🚀 AdViewModel - AdMob başlatılıyor...');
      
      // WidgetsFlutterBinding'in hazır olduğundan emin ol
      if (!WidgetsBinding.instance.isRootWidgetAttached) {
        Logger.warning('⚠️ AdViewModel - WidgetsBinding henüz hazır değil, bekleniyor...');
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      // UI thread'i bloklamamak için arka planda başlat
      await _initializeInBackground();
      
      _isInitialized = true;
      
      // Reklam yükleme işlemini de arka planda yap
      _loadAdInBackground();
      
    } catch (e) {
      Logger.error('❌ AdViewModel - AdMob başlatılırken hata: $e');
    }
  }

  // Arka planda AdMob başlatma
  Future<void> _initializeInBackground() async {
    try {
      await _adMobService.initialize();
      Logger.info('✅ AdViewModel - AdMob başlatma tamamlandı');
    } catch (e) {
      Logger.error('❌ AdViewModel - Arka plan AdMob başlatma hatası: $e');
      rethrow;
    }
  }

  // Arka planda reklam yükleme
  void _loadAdInBackground() {
    // UI thread'i bloklamamak için microtask kullan
    Future.microtask(() async {
      try {
        await loadAd();
      } catch (e) {
        Logger.error('❌ AdViewModel - Arka plan reklam yükleme hatası: $e');
      }
    });
  }

  /// Reklam yükle (performans optimizasyonlu)
  Future<void> loadAd() async {
    if (_isLoadingAd) {
      Logger.debug('🔄 AdViewModel - Reklam zaten yükleniyor, bekle...');
      return;
    }

    try {
      Logger.info('🔄 AdViewModel - Reklam yükleniyor...');
      _isLoadingAd = true;
      notifyListeners();

      await _adMobService.loadNativeAd();
      
      // Reklam durumunu kontrol et
      _isAdLoaded = _adMobService.isAdLoaded;
      Logger.info('✅ AdViewModel - Reklam yükleme tamamlandı. isAdLoaded: $_isAdLoaded');
      
      // Eğer nativeAd objesi varsa ama isAdLoaded false ise, düzelt
      if (_adMobService.nativeAd != null && !_isAdLoaded) {
        Logger.warning('⚠️ AdViewModel - nativeAd mevcut ama isAdLoaded false, düzeltiliyor...');
        _isAdLoaded = true;
      }
      
      if (_isAdLoaded) {
        Logger.info('✅ AdViewModel - Native reklam başarıyla yüklendi');
      } else {
        Logger.warning('⚠️ AdViewModel - Reklam yüklenemedi');
      }
    } catch (e) {
      Logger.error('❌ AdViewModel - Reklam yüklenirken hata: $e');
      _isAdLoaded = false;
    } finally {
      _isLoadingAd = false;
      notifyListeners();
    }
  }

  /// Ürün sayısını güncelle
  void updateProductCount(int count) {
    _productCount = count;
    Logger.info('📊 AdViewModel - Ürün sayısı güncellendi: $_productCount');
  }

  /// Belirli bir index'te reklam gösterilip gösterilmeyeceğini kontrol et
  bool shouldShowAdAt(int index) {
    if (!_isAdLoaded) {
      return false;
    }

    // İlk reklamı 3. üründen sonra göster
    if (index == 3) {
      _lastAdIndex = index;
      return true;
    }

    // Sonraki reklamları belirli aralıklarla göster
    if (index > _lastAdIndex + _adFrequency) {
      _lastAdIndex = index;
      return true;
    }

    return false;
  }

  /// Reklamı yeniden yükle
  Future<void> reloadAd() async {
    Logger.info('🔄 AdViewModel - Reklam yeniden yükleniyor...');
    _isAdLoaded = false;
    _isLoadingAd = false;
    _lastAdIndex = -1;
    notifyListeners();
    
    // Arka planda yeniden yükle
    _loadAdInBackground();
  }

  /// Reklam frekansını ayarla
  void setAdFrequency(int frequency) {
    if (frequency > 0) {
      _adFrequency = frequency;
      Logger.info('⚙️ AdViewModel - Reklam frekansı ayarlandı: $_adFrequency');
    }
  }

  /// Reklam durumunu sıfırla
  void resetAdState() {
    Logger.info('🔄 AdViewModel - Reklam durumu sıfırlanıyor...');
    _isAdLoaded = false;
    _isLoadingAd = false;
    _lastAdIndex = -1;
    _adMobService.resetFailedState();
    notifyListeners();
  }

  @override
  void dispose() {
    Logger.debug('🧹 AdViewModel - AdViewModel dispose ediliyor...');
    _adMobService.dispose();
    super.dispose();
  }
} 