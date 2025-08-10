import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:takasly/services/admob_service.dart';
import 'package:takasly/utils/logger.dart';

/// Grid içerisindeki ürün kartları ile aynı görünümde native reklam kartı
class NativeAdGridCard extends StatefulWidget {
  const NativeAdGridCard({super.key});

  @override
  State<NativeAdGridCard> createState() => _NativeAdGridCardState();
}

class _NativeAdGridCardState extends State<NativeAdGridCard>
    with AutomaticKeepAliveClientMixin {
  final AdMobService _adMobService = AdMobService();
  NativeAd? _nativeAd;
  // Platform view yeniden yaratma hatasını önlemek için AdWidget'ı tekil tut
  Widget? _adWidget;
  Key? _adKey;
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
      _nativeAd?.dispose();
    } catch (e) {
      Logger.error('❌ NativeAdGridCard dispose error: $e');
    }
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    try {
      // AdMob initialize
      await _adMobService.initialize();

      // Mevcut reklamı temizle
      try {
        _nativeAd?.dispose();
      } catch (_) {}
      _nativeAd = null;
      _adWidget = null;
      _adKey = null;
      _isLoaded = false;
      _hasError = false;

      final ad = NativeAd(
        adUnitId: _adMobService.nativeAdUnitId,
        factoryId: 'listTile',
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (_isDisposed) {
              ad.dispose();
              return;
            }
            _nativeAd = ad as NativeAd;
            // AdWidget'ı bir kez oluştur ve aynı instance'ı kullan
            _adWidget = AdWidget(ad: _nativeAd!);
            _adKey = ValueKey(_nativeAd);
            _isLoaded = true;
            _hasError = false;
            if (mounted) setState(() {});
            Logger.info('✅ NativeAdGridCard - Reklam yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error('❌ NativeAdGridCard - Yükleme hatası: ${error.code} ${error.message}');
            try { ad.dispose(); } catch (_) {}
            _nativeAd = null;
            _isLoaded = false;
            _hasError = true;
            if (mounted) setState(() {});
            // Sınırlı sayıda yeniden dene
            if (!_isDisposed && _retryCount < _maxRetries) {
              _retryCount++;
              Timer(const Duration(seconds: 4), () {
                if (mounted && !_isDisposed) {
                  _loadAd();
                }
              });
            }
          },
        ),
      );

      await ad.load();
    } catch (e) {
      Logger.error('❌ NativeAdGridCard load error: $e');
      _hasError = true;
      if (mounted) setState(() {});
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = BorderRadius.circular(screenWidth < 360 ? 6 : 8);

    // Ürün kartı ile aynı çerçeve
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: borderRadius,
      border: Border.all(
        color: const Color.fromARGB(255, 209, 209, 209),
        width: 1,
      ),
    );

    if (!_isLoaded || _nativeAd == null) {
      // Basit iskelet - ürün kartı ile hizalı
      return Container(
        decoration: decoration,
        child: Column(
          children: [
            // Üstte görsel alanı kadar placeholder
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: borderRadius.topLeft),
                child: Container(color: Colors.grey[200]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 6 : 10,
                  vertical: screenWidth < 360 ? 6 : 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth < 360 ? 14 : 18,
                      height: screenWidth < 360 ? 14 : 18,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasError ? 'Reklam yüklenemedi' : 'Reklam yükleniyor',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth < 360 ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Yüklü reklam - platform view; ClipRRect bazı cihazlarda görünümü gizleyebildiği için kaldırıldı
    return Container(
      decoration: decoration,
      child: _adWidget == null
          ? Container(color: Colors.grey[200])
          : SizedBox.expand(
              child: KeyedSubtree(key: _adKey, child: _adWidget!),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}


