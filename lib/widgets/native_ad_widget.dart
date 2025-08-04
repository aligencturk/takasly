import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({Key? key}) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  final AdMobService _adMobService = AdMobService();
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeAd();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isAdLoaded || _isDisposed) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Logger.info('🚀 NativeAdWidget - Reklam yukleniyor...');
      
      // AdMob servisinden reklam yükle
      await _adMobService.loadNativeAd();
      
      if (mounted && !_isDisposed) {
        final nativeAd = _adMobService.nativeAd;
        final isAdLoaded = _adMobService.isAdLoaded;
        
        setState(() {
          _nativeAd = nativeAd;
          _isAdLoaded = isAdLoaded;
          _isLoading = false;
        });
        
        if (_isAdLoaded && _nativeAd != null && _isAdValid()) {
          Logger.info('✅ NativeAdWidget - Reklam basariyla yuklendi');
        } else {
          Logger.warning('⚠️ NativeAdWidget - Reklam yuklenemedi');
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (e) {
      Logger.error('❌ NativeAdWidget - Reklam yukleme hatasi: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _disposeAd() {
    try {
      if (_nativeAd != null) {
        _nativeAd!.dispose();
        _nativeAd = null;
      }
    } catch (e) {
      Logger.error('❌ NativeAdWidget - Reklam temizleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Widget dispose edilmişse boş container döndür
      if (_isDisposed) {
        return const SizedBox.shrink();
      }

      if (_isLoading) {
        return _buildLoadingWidget();
      }

      if (_hasError || !_isAdLoaded || _nativeAd == null) {
        return _buildErrorWidget();
      }

      return _buildAdWidget();
    } catch (e) {
      Logger.error('❌ NativeAdWidget - Build hatasi: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text(
              'Reklam yükleniyor...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              'Reklam yüklenemedi',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdWidget() {
    // Son güvenlik kontrolü
    if (_nativeAd == null || _isDisposed) {
      return _buildErrorWidget();
    }

    try {
      // Reklamın geçerli olup olmadığını kontrol et
      if (!_isAdValid()) {
        Logger.warning('⚠️ NativeAdWidget - Reklam gecersiz, hata widget gosteriliyor');
        return _buildErrorWidget();
      }

      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AdWidget(ad: _nativeAd!),
        ),
      );
    } catch (e) {
      Logger.error('❌ NativeAdWidget - AdWidget oluşturma hatası: $e');
      return _buildErrorWidget();
    }
  }

  // Reklamın geçerli olup olmadığını kontrol et
  bool _isAdValid() {
    try {
      if (_nativeAd == null) return false;
      
      // AdMob servisinden reklam durumunu kontrol et
      return _adMobService.isAdLoaded && _isAdLoaded;
    } catch (e) {
      Logger.error('❌ NativeAdWidget - Reklam geçerlilik kontrolü hatası: $e');
      return false;
    }
  }
} 