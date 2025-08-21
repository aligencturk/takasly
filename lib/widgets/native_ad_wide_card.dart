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
  late final String _widgetId =
      'native_ad_wide_${DateTime.now().millisecondsSinceEpoch}_${hashCode}';

  @override
  void initState() {
    super.initState();
    Logger.info('🚀 NativeAdWideCard - Initializing: $_widgetId');
    // Biraz gecikme ile load et, platform view conflict'larını önlemek için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadAd();
      } else {
        Logger.info(
          '🔄 NativeAdWideCard - Widget disposed during initState, skipping ad load',
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dependencies değiştiğinde widget hala mounted mı kontrol et
    if (!mounted || _isDisposed) {
      Logger.info(
        '🔄 NativeAdWideCard - Widget disposed during didChangeDependencies',
      );
      return;
    }
  }

  @override
  void didUpdateWidget(covariant NativeAdWideCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget güncellendiğinde widget hala mounted mı kontrol et
    if (!mounted || _isDisposed) {
      Logger.info(
        '🔄 NativeAdWideCard - Widget disposed during didUpdateWidget',
      );
      return;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload sırasında widget hala mounted mı kontrol et
    if (!mounted || _isDisposed) {
      Logger.info('🔄 NativeAdWideCard - Widget disposed during reassemble');
      return;
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    // Widget deactivate edildiğinde log
    Logger.info('🔄 NativeAdWideCard - Widget deactivated: $_widgetId');
  }

  @override
  void activate() {
    super.activate();
    // Widget activate edildiğinde log
    Logger.info('🔄 NativeAdWideCard - Widget activated: $_widgetId');
  }



  @override
  void dispose() {
    Logger.info('🧹 NativeAdWideCard - Disposing widget: $_widgetId');
    _isDisposed = true;

    // BannerAd'i güvenli şekilde temizle
    try {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
        _bannerAd = null;
        Logger.info('✅ NativeAdWideCard - BannerAd disposed successfully');
      }
    } catch (e) {
      Logger.error('❌ NativeAdWideCard - Dispose hatası: $e');
    }

    // Timer'ları temizle
    try {
      // Eğer retry timer varsa temizle
      // Timer'lar zaten Future.delayed ile oluşturulduğu için otomatik temizlenir
    } catch (e) {
      Logger.error('❌ NativeAdWideCard - Timer cleanup hatası: $e');
    }

    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) return;

    // Widget hala mounted mı kontrol et
    if (!mounted) {
      Logger.info('🔄 NativeAdWideCard - Widget not mounted, skipping ad load');
      return;
    }

    _isLoading = true;
    try {
      await _adMobService.initialize();

      // Önceki reklamı temizle
      try {
        _bannerAd?.dispose();
        _bannerAd = null;
      } catch (e) {
        Logger.error('❌ NativeAdWideCard - Dispose hatası: $e');
      }

      // Widget hala mounted mı tekrar kontrol et
      if (!mounted || _isDisposed) {
        Logger.info(
          '🔄 NativeAdWideCard - Widget disposed during ad load, aborting',
        );
        return;
      }

      final ad = BannerAd(
        adUnitId: _adMobService.bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted && !_isDisposed) {
              Logger.info(
                '✅ NativeAdWideCard - Ad loaded successfully: $_widgetId',
              );
              setState(() {
                _bannerAd = ad as BannerAd;
                _isLoaded = true;
                _hasError = false;
              });
            } else {
              Logger.info(
                '🔄 NativeAdWideCard - Widget disposed after ad load, disposing ad',
              );
              ad.dispose();
            }
          },
          onAdFailedToLoad: (ad, error) {
            if (mounted && !_isDisposed) {
              Logger.error('❌ NativeAdWideCard - Ad failed to load: $error');
              setState(() {
                _hasError = true;
                _retryCount++;
              });

              // Retry logic
              if (_retryCount < _maxRetries) {
                Future.delayed(Duration(seconds: _retryCount * 2), () {
                  if (mounted && !_isDisposed) {
                    _loadAd();
                  }
                });
              }
            }
            ad.dispose();
          },
        ),
      );

      // Widget hala mounted mı son kez kontrol et
      if (!mounted || _isDisposed) {
        Logger.info(
          '🔄 NativeAdWideCard - Widget disposed before ad.load(), aborting',
        );
        ad.dispose();
        return;
      }

      await ad.load();
    } catch (e) {
      if (mounted && !_isDisposed) {
        Logger.error('❌ NativeAdWideCard load error: $e');
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Widget dispose edilmişse boş widget döndür
    if (_isDisposed) {
      Logger.info(
        '🔄 NativeAdWideCard - Widget disposed, returning empty widget',
      );
      return const SizedBox.shrink();
    }

    // Context mounted kontrolü
    if (!mounted) {
      Logger.info(
        '🔄 NativeAdWideCard - Widget not mounted, returning empty widget',
      );
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Screen width validation
    if (screenWidth.isInfinite || screenWidth <= 0) {
      Logger.warning(
        '⚠️ NativeAdWideCard - Geçersiz screenWidth: $screenWidth',
      );
      return const SizedBox.shrink();
    }

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
        // Widget dispose edilmişse boş widget döndür
        if (_isDisposed) {
          Logger.info(
            '🔄 NativeAdWideCard - Widget disposed in LayoutBuilder, returning empty widget',
          );
          return const SizedBox.shrink();
        }

        // Constraint güvenliği kontrolü
        if (constraints.maxWidth.isInfinite || constraints.maxWidth <= 0) {
          Logger.warning(
            '⚠️ NativeAdWideCard - Geçersiz constraint: maxWidth=${constraints.maxWidth}',
          );
          return const SizedBox.shrink();
        }

        // Grid constraint kontrolü - grid içinde kullanıldığında maxWidth sınırlı olmalı
        if (constraints.maxWidth > 1000) {
          Logger.warning(
            '⚠️ NativeAdWideCard - Grid dışı constraint: maxWidth=${constraints.maxWidth}',
          );
          return const SizedBox.shrink();
        }

        // ProductCard ile aynı aspect ratio kullan (kare format)
        final cardWidth = constraints.maxWidth;
        final cardHeight =
            cardWidth / 0.7; // ProductCard'daki childAspectRatio: 0.7

        // Height validation
        if (cardHeight.isInfinite || cardHeight <= 0) {
          Logger.warning(
            '⚠️ NativeAdWideCard - Geçersiz cardHeight: $cardHeight',
          );
          return const SizedBox.shrink();
        }

        // Grid height constraint kontrolü
        if (constraints.hasBoundedHeight &&
            constraints.maxHeight < cardHeight) {
          Logger.warning(
            '⚠️ NativeAdWideCard - Grid height constraint çok küçük: maxHeight=${constraints.maxHeight}, required=$cardHeight',
          );
          return SizedBox(
            height: constraints.maxHeight,
            child: const Center(
              child: Icon(Icons.ad_units_outlined, color: Colors.grey),
            ),
          );
        }

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
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

          // Loading state - güvenli height ile
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
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(screenWidth < 360 ? 6 : 8),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth < 360 ? 20 : 28,
                            height: screenWidth < 360 ? 20 : 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reklam yükleniyor...',
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
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              : _buildAdContent(),
        );
      },
    );
  }

  Widget _buildAdContent() {
    // Widget dispose edilmişse boş widget döndür
    if (_isDisposed || _bannerAd == null) {
      Logger.warning(
        '⚠️ NativeAdWideCard - _buildAdContent called with disposed widget or null ad',
      );
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Screen width validation
    if (screenWidth.isInfinite || screenWidth <= 0) {
      Logger.warning(
        '⚠️ NativeAdWideCard - Geçersiz screenWidth: $screenWidth',
      );
      return const SizedBox.shrink();
    }

    final cardHeight =
        screenWidth / 0.7; // ProductCard'daki childAspectRatio: 0.7

    // Card height validation
    if (cardHeight.isInfinite || cardHeight <= 0) {
      Logger.warning('⚠️ NativeAdWideCard - Geçersiz cardHeight: $cardHeight');
      return const SizedBox.shrink();
    }

    return Column(
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
              child: Builder(
                builder: (context) {
                  try {
                    if (_bannerAd != null && !_isDisposed) {
                      return AdWidget(
                        key: ValueKey('${_widgetId}_${_bannerAd.hashCode}'),
                        ad: _bannerAd!,
                      );
                    } else {
                      Logger.warning(
                        '⚠️ NativeAdWideCard - AdWidget build failed: ad is null or widget disposed',
                      );
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.ad_units_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    Logger.error(
                      '❌ NativeAdWideCard - AdWidget build error: $e',
                    );
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  }
                },
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
