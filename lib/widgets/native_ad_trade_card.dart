import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

/// Trade listesinde `TradeCard` görünümünde native reklam kartı
class NativeAdTradeCard extends StatefulWidget {
  const NativeAdTradeCard({super.key});

  @override
  State<NativeAdTradeCard> createState() => _NativeAdTradeCardState();
}

class _NativeAdTradeCardState extends State<NativeAdTradeCard>
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
        // Aynı fabrika ID'si kullanılıyor; görünümü dış kapsayıcı ile TradeCard'a benzetiyoruz
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
            Logger.info('✅ NativeAdTradeCard - Reklam yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ NativeAdTradeCard - Yükleme hatası: ${error.code} ${error.message}',
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
      Logger.error('❌ NativeAdTradeCard load error: $e');
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

    // TradeCard'a benzer kapsayıcı dekorasyon
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    // Yükseklik: TradeCard tipik yüksekliğine yakın sabit bir yükseklik
    final double height = screenWidth < 360 ? 150 : 170;

    if (!_isLoaded || _nativeAd == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(width: 12),
            Text(
              _hasError ? 'Reklam yüklenemedi' : 'Reklam yükleniyor',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: screenWidth < 360 ? 12 : 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
