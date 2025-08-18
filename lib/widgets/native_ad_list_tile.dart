import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

/// Chat listesinde tek satır (ListTile) görünümlü native reklam
class BannerAdListTile extends StatefulWidget {
  const BannerAdListTile({super.key});

  @override
  State<BannerAdListTile> createState() => _BannerAdListTileState();
}

class _BannerAdListTileState extends State<BannerAdListTile>
    with AutomaticKeepAliveClientMixin {
  final AdMobService _adMobService = AdMobService();
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Platform view hazır olunca yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadAd();
      }
    });
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
            Logger.info('✅ BannerAdListTile - Reklam yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ BannerAdListTile - Yükleme hatası: ${error.code} ${error.message}',
            );
            try {
              ad.dispose();
            } catch (_) {}
            _isLoaded = false;
            _hasError = true;
            if (mounted) setState(() {});
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      Logger.error('❌ BannerAdListTile load error: $e');
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

    // Chat satırı ile uyumlu tek satır yüksekliği
    final double height = 60; // Banner yüksekliği için sabit değer

    final decoration = BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
    );

    if (!_isLoaded || _bannerAd == null) {
      return Container(
        height: height,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
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
      height: height,
      decoration: decoration,
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
