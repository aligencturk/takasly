import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

/// İlan gridinde 2 sütunu kaplayan geniş native reklam kartı
class NativeAdWideCard extends StatefulWidget {
  const NativeAdWideCard({super.key});

  @override
  State<NativeAdWideCard> createState() => _NativeAdWideCardState();
}

class _NativeAdWideCardState extends State<NativeAdWideCard>
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
            Logger.info('✅ NativeAdWideCard - Reklam yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ NativeAdWideCard - Yükleme hatası: ${error.code} ${error.message}',
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
      Logger.error('❌ NativeAdWideCard load error: $e');
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
    final borderRadius = BorderRadius.circular(screenWidth < 360 ? 10 : 12);

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: borderRadius,
      border: Border.all(
        color: const Color.fromARGB(255, 209, 209, 209),
        width: 1,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth == double.infinity
            ? screenWidth
            : constraints.maxWidth;
        // Responsive yükseklik: küçük ekranlarda daha yüksek oran
        final double base = width * (width < 360 ? 0.9 : 0.8);
        final double height = base.clamp(260.0, 480.0);

        if (!_isLoaded || _nativeAd == null) {
          return Container(
            height: height,
            decoration: decoration,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: screenWidth < 360 ? 16 : 20,
                  height: screenWidth < 360 ? 16 : 20,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  _hasError ? 'Reklam yüklenemedi' : 'Reklam yükleniyor',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: screenWidth < 360 ? 11 : 12,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: height,
          decoration: decoration,
          child: _adWidget == null
              ? Container(color: Colors.grey[200])
              : SizedBox.expand(
                  child: KeyedSubtree(key: _adKey, child: _adWidget!),
                ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
