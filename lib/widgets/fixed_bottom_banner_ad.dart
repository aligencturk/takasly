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

class _FixedBottomBannerAdState extends State<FixedBottomBannerAd>
    with AutomaticKeepAliveClientMixin {
  final AdMobService _adMobService = AdMobService();
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool _isLoading = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    try {
      await _adMobService.initialize();

      try {
        _bannerAd?.dispose();
      } catch (_) {}
      
      _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: _adMobService.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (_isDisposed) {
              ad.dispose();
              return;
            }
            _isLoaded = true;
            _hasError = false;
            if (mounted) setState(() {});
            Logger.info('✅ FixedBottomBannerAd - Reklam yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ FixedBottomBannerAd - Yükleme hatası: ${error.code} ${error.message}',
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
              Timer(const Duration(seconds: 3), () {
                if (mounted && !_isDisposed) {
                  _loadAd();
                }
              });
            }
          },
          onAdClicked: (ad) {
            Logger.info('👆 FixedBottomBannerAd - Reklam tıklandı');
          },
          onAdImpression: (ad) {
            Logger.info('👁️ FixedBottomBannerAd - Reklam gösterildi');
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      Logger.error('❌ FixedBottomBannerAd load error: $e');
      _hasError = true;
      if (mounted) setState(() {});
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
