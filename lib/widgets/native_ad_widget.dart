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

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isAdLoaded) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Logger.info('🚀 NativeAdWidget - Reklam yükleniyor...');
      
      // AdMob servisinden reklam yükle
      await _adMobService.loadNativeAd();
      
      if (mounted) {
        setState(() {
          _nativeAd = _adMobService.nativeAd;
          _isAdLoaded = _adMobService.isAdLoaded;
          _isLoading = false;
        });
        
        if (_isAdLoaded) {
          Logger.info('✅ NativeAdWidget - Reklam başarıyla yüklendi');
        } else {
          Logger.warning('⚠️ NativeAdWidget - Reklam yüklenemedi');
          _hasError = true;
        }
      }
    } catch (e) {
      Logger.error('❌ NativeAdWidget - Reklam yükleme hatası: $e');
      if (mounted) {
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
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError || !_isAdLoaded || _nativeAd == null) {
      return _buildErrorWidget();
    }

    return _buildAdWidget();
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
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
} 