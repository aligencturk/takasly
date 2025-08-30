import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

/// Sayfanın altında sabit duracak banner reklam widget'ı
class FixedBottomBannerAd extends StatefulWidget {
  const FixedBottomBannerAd({super.key});

  @override
  State<FixedBottomBannerAd> createState() => _FixedBottomBannerAdState();
}

class _FixedBottomBannerAdState extends State<FixedBottomBannerAd> {
  final AdMobService _adMobService = AdMobService();
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool _isLoading = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  
  // Her instance için benzersiz ID
  late final String _instanceId;

  @override
  void initState() {
    super.initState();
    _instanceId = 'banner_${DateTime.now().millisecondsSinceEpoch}_${hashCode}';
    Logger.info('🚀 FixedBottomBannerAd[$_instanceId] - Widget başlatıldı');
    
    // Platform view/surface hazır olmadan yükleme yapmamak için ilk frame sonra başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadAd();
      }
    });
  }

  @override
  void dispose() {
    Logger.info('🗑️ FixedBottomBannerAd[$_instanceId] - Widget dispose edildi');
    _isDisposed = true;
    
    // Reklamı güvenli şekilde temizle
    _disposeAd();
    
    super.dispose();
  }

  void _disposeAd() {
    try {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
        _bannerAd = null;
        Logger.info('🧹 FixedBottomBannerAd[$_instanceId] - Reklam temizlendi');
      }
    } catch (e) {
      Logger.error('❌ FixedBottomBannerAd[$_instanceId] - Reklam temizleme hatası: $e');
    }
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) {
      Logger.info('⏸️ FixedBottomBannerAd[$_instanceId] - Yükleme atlandı');
      return;
    }
    
    _isLoading = true;
    Logger.info('📥 FixedBottomBannerAd[$_instanceId] - Reklam yükleniyor...');
    
    try {
      await _adMobService.initialize();

      // Önceki reklamı temizle
      _disposeAd();
      
      // Her instance için TAMAMEN YENİ reklam objesi oluştur
      _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: _adMobService.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (_isDisposed) {
              Logger.info('⚠️ FixedBottomBannerAd[$_instanceId] - Widget dispose edildi, reklam temizleniyor');
              ad.dispose();
              return;
            }
            
            _isLoaded = true;
            _hasError = false;
            _retryCount = 0;
            
            if (mounted) setState(() {});
            Logger.info('✅ FixedBottomBannerAd[$_instanceId] - Reklam başarıyla yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ FixedBottomBannerAd[$_instanceId] - Yükleme hatası: ${error.code} ${error.message}',
            );
            
            try {
              ad.dispose();
            } catch (_) {}
            
            _isLoaded = false;
            _hasError = true;
            if (mounted) setState(() {});
            
            // Retry logic
            if (!_isDisposed && _retryCount < _maxRetries) {
              _retryCount++;
              Logger.info('🔄 FixedBottomBannerAd[$_instanceId] - Tekrar deneniyor...');
              
              Timer(const Duration(seconds: 3), () {
                if (mounted && !_isDisposed) {
                  _loadAd();
                }
              });
            }
          },
          onAdClicked: (ad) {
            Logger.info('👆 FixedBottomBannerAd[$_instanceId] - Reklam tıklandı');
          },
          onAdImpression: (ad) {
            Logger.info('👁️ FixedBottomBannerAd[$_instanceId] - Reklam gösterildi');
          },
        ),
      );

      await _bannerAd!.load();
      Logger.info('📤 FixedBottomBannerAd[$_instanceId] - Reklam yükleme isteği gönderildi');
      
    } catch (e) {
      Logger.error('❌ FixedBottomBannerAd[$_instanceId] - Beklenmeyen hata: $e');
      _hasError = true;
      if (mounted) setState(() {});
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reklam yüklenmemişse veya hata varsa widget gösterme
    if (!_isLoaded || _bannerAd == null || _hasError) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60, // Standard banner ad height + padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(
            // Her instance için benzersiz key kullan
            key: ValueKey(_instanceId),
            ad: _bannerAd!,
          ),
        ),
      ),
    );
  }
}
