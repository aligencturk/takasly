import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});

  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd>
    with AutomaticKeepAliveClientMixin {
  final AdMobService _adMobService = AdMobService();
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      await _adMobService.initialize();
      _bannerAd?.dispose();
      _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: _adMobService.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isLoaded = true;
            if (mounted) setState(() {});
            Logger.info('✅ InlineBannerAd - Yüklendi');
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ InlineBannerAd - Hata: ${error.code} ${error.message}',
            );
            try {
              ad.dispose();
            } catch (_) {}
            _isLoaded = false;
            if (mounted) setState(() {});
          },
        ),
      );
      await _bannerAd!.load();
    } catch (e) {
      Logger.error('❌ InlineBannerAd yükleme hatası: $e');
    }
  }

  @override
  void dispose() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_bannerAd == null || !_isLoaded) {
      return const SizedBox(height: 50);
    }
    return Container(
      alignment: Alignment.center,
      height: _bannerAd!.size.height.toDouble(),
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
