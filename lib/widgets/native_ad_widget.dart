import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/app_theme.dart';
import '../utils/logger.dart';

class NativeAdWidget extends StatefulWidget {
  final NativeAd? nativeAd;
  final double? height;
  final EdgeInsets? margin;

  const NativeAdWidget({
    super.key,
    required this.nativeAd,
    this.height,
    this.margin,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkAdStatus();
  }

  void _checkAdStatus() {
    if (widget.nativeAd != null) {
      setState(() {
        _isAdLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || widget.nativeAd == null) {
      return const SizedBox.shrink();
    }

    return AdWidget(ad: widget.nativeAd!);
  }
} 