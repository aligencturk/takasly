import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';
import '../core/app_theme.dart';

/// Ürün detay sayfasında haritanın altındaki gri alan için küçük native reklam
class NativeAdDetailFooter extends StatefulWidget {
  const NativeAdDetailFooter({super.key});

  @override
  State<NativeAdDetailFooter> createState() => _NativeAdDetailFooterState();
}

class _NativeAdDetailFooterState extends State<NativeAdDetailFooter>
    with AutomaticKeepAliveClientMixin {
  final AdMobService _adMobService = AdMobService();
  NativeAd? _nativeAd;
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
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    try {
      await _adMobService.initialize();

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
            _adWidget = AdWidget(ad: _nativeAd!);
            _adKey = ValueKey(_nativeAd);
            _isLoaded = true;
            _hasError = false;
            if (mounted) setState(() {});
            Logger.info('✅ NativeAdDetailFooter - Reklam yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ NativeAdDetailFooter - Yükleme hatası: ${error.code} ${error.message}',
            );
            try {
              ad.dispose();
            } catch (_) {}
            _nativeAd = null;
            _isLoaded = false;
            _hasError = true;
            if (mounted) setState(() {});
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
      Logger.error('❌ NativeAdDetailFooter load error: $e');
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

    // Küçük, detay altı reklam alanı; Product detail ile uyumlu görünüm
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    // Yükseklik: kompakt listTile tarzı
    final double height = screenWidth < 360 ? 70 : 78;

    if (!_isLoaded || _nativeAd == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: decoration,
        height: height,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth < 360 ? 16 : 18,
              height: screenWidth < 360 ? 16 : 18,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              _hasError ? 'Reklam yüklenemedi' : 'Reklam yükleniyor',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: decoration,
      height: height,
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
