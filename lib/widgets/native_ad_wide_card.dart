import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../utils/logger.dart';

/// İlan gridinde 2 sütunu kaplayan geniş banner reklam kartı
class NativeAdWideCard extends StatefulWidget {
  const NativeAdWideCard({super.key});


  @override
  State<NativeAdWideCard> createState() => _NativeAdWideCardState();
}


class _NativeAdWideCardState extends State<NativeAdWideCard>
    with AutomaticKeepAliveClientMixin {
  final AdMobService _adMobService = AdMobService();
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool _isLoading = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  
  // Benzersiz widget ID'si oluştur
  late final String _widgetId = 'native_ad_wide_${DateTime.now().millisecondsSinceEpoch}_${hashCode}';

  @override
  void initState() {
    super.initState();
    Logger.info('🚀 NativeAdWideCard - Initializing: $_widgetId');
    // Biraz gecikme ile load et, platform view conflict'larını önlemek için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadAd();
      }
    });
  }

  @override
  void dispose() {
    Logger.info('🧹 NativeAdWideCard - Disposing widget: $_widgetId');
    _isDisposed = true;
    
    // BannerAd'i güvenli şekilde temizle
    try {
      _bannerAd?.dispose();
      _bannerAd = null;
    } catch (e) {
      Logger.error('❌ NativeAdWideCard - Dispose hatası: $e');
    }
    
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    try {
      await _adMobService.initialize();

      // Önceki reklamı temizle
      try {
        _bannerAd?.dispose();
        _bannerAd = null;
      } catch (e) {
        Logger.error('❌ NativeAdWideCard - Önceki reklam temizleme hatası: $e');
      }
      
      _isLoaded = false;
      _hasError = false;

      Logger.info('🔄 NativeAdWideCard - Yeni reklam yükleniyor: $_widgetId');
      
      final ad = BannerAd(
        adUnitId: _adMobService.bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (_isDisposed) {
              ad.dispose();
              return;
            }
            try {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
              _hasError = false;
              if (mounted) setState(() {});
              Logger.info('✅ NativeAdWideCard - Banner reklam yüklendi: $_widgetId');
            } catch (e) {
              Logger.error('❌ NativeAdWideCard - Ad loading hatası: $e');
              ad.dispose();
              _hasError = true;
              if (mounted) setState(() {});
            }
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error(
              '❌ NativeAdWideCard - Yükleme hatası: ${error.code} ${error.message}',
            );
            try {
              ad.dispose();
            } catch (_) {}
            _bannerAd = null;
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
    
    // ProductCard ile aynı styling kullan
    final borderRadius = BorderRadius.circular(screenWidth < 360 ? 6 : 8);

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
        // ProductCard ile aynı aspect ratio kullan (kare format)
        final cardWidth = constraints.maxWidth;
        final cardHeight = cardWidth / 0.7; // ProductCard'daki childAspectRatio: 0.7

        if (!_isLoaded || _bannerAd == null) {
          if (_hasError) {
            return Container(
              height: cardHeight,
              decoration: decoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst kısım - resim alanı
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(screenWidth < 360 ? 6 : 8),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ad_units_outlined,
                              color: Colors.grey[400],
                              size: screenWidth < 360 ? 20 : 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reklam yüklenemedi',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: screenWidth < 360 ? 8 : 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Alt kısım - bilgi alanı
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth < 360 ? 6 : 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reklam',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 9.0 : 11.0,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Sponsorlu İçerik',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 10.0 : 12.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: screenWidth < 360 ? 10 : 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Türkiye',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 8.0 : 10.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Container(
          height: cardHeight,
          decoration: decoration,
          child: _isDisposed || _bannerAd == null
              ? Container(
                  decoration: decoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst kısım - placeholder resim alanı
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(screenWidth < 360 ? 6 : 8),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.ad_units_outlined,
                                  color: Colors.grey[400],
                                  size: screenWidth < 360 ? 20 : 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reklam Alanı',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: screenWidth < 360 ? 8 : 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Alt kısım - bilgi alanı
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth < 360 ? 6 : 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reklam',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 9.0 : 11.0,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Sponsorlu İçerik',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 10.0 : 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: screenWidth < 360 ? 10 : 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Türkiye',
                                    style: TextStyle(
                                      fontSize: screenWidth < 360 ? 8.0 : 10.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst kısım - reklam alanı
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(screenWidth < 360 ? 6 : 8),
                        ),
                        child: Container(
                          width: double.infinity,
                          child: AdWidget(
                            key: ValueKey('${_widgetId}_${_bannerAd.hashCode}'),
                            ad: _bannerAd!,
                          ),
                        ),
                      ),
                    ),
                    // Alt kısım - bilgi alanı (ProductCard benzeri)
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth < 360 ? 6 : 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reklam',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 9.0 : 11.0,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Sponsorlu İçerik',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 10.0 : 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: screenWidth < 360 ? 10 : 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Türkiye',
                                  style: TextStyle(
                                    fontSize: screenWidth < 360 ? 8.0 : 10.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
