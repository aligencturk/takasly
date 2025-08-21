import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takasly/views/home/home_view.dart';
import 'package:takasly/views/auth/login_view.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/viewmodels/notification_viewmodel.dart';
import 'package:video_player/video_player.dart';
import 'package:takasly/utils/logger.dart';
import 'package:takasly/core/constants.dart';

class SplashVideoPage extends StatefulWidget {
  @override
  _SplashVideoPageState createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Klavyeyi hemen kapat ve focus'u engelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        // Tüm focus'ları temizle
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });

    _controller =
        VideoPlayerController.asset(
            "assets/splash/powered_by_rivorya_yazilim.mp4",
          )
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              // Video başladıktan 3 saniye sonra giriş kontrolü yap
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  _checkAuthAndNavigate();
                }
              });
              _controller.play();
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FCM'i başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notificationViewModel = Provider.of<NotificationViewModel>(
          context,
          listen: false,
        );
        notificationViewModel.initializeFCM();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      Logger.info(
        '🔍 SplashView - Navigating directly to home (no auth check required)...',
      );

      // Widget'ın hala aktif olup olmadığını kontrol et
      if (!mounted) {
        Logger.warning(
          '⚠️ SplashView - Widget is no longer mounted, aborting navigation',
        );
        return;
      }

      // Direkt ana sayfaya yönlendir (artık auth kontrolü yapılmıyor)
      Logger.info('🏠 SplashView - Navigating to home page directly');

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
    } catch (e) {
      Logger.error('❌ SplashView - Error during navigation: $e', error: e);

      // Hata durumunda da mounted kontrolü yap
      if (!mounted) {
        Logger.warning(
          '⚠️ SplashView - Widget is no longer mounted during error handling, aborting navigation',
        );
        return;
      }

      // Hata durumunda da ana sayfaya yönlendir
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
    }
  }

  // Hot restart durumunu kontrol et
  Future<bool> _checkIfHotRestart() async {
    try {
      // SharedPreferences'dan bir flag kontrol et
      final prefs = await SharedPreferences.getInstance();
      final lastAppStart = prefs.getInt(AppConstants.lastAppStartKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Eğer son uygulama başlatma zamanı 10 saniye içindeyse hot restart olabilir
      final isHotRestart = (currentTime - lastAppStart) < 10000; // 10 saniye

      // Şimdiki zamanı kaydet
      await prefs.setInt(AppConstants.lastAppStartKey, currentTime);

      Logger.info(
        '🔍 SplashView - Hot restart check: $isHotRestart (time diff: ${currentTime - lastAppStart}ms)',
      );

      return isHotRestart;
    } catch (e) {
      Logger.error('❌ SplashView - Error checking hot restart: $e', error: e);
      return false;
    }
  }

  @override
  void dispose() {
    Logger.info('🔄 SplashView - Disposing splash view');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Focus(
        autofocus: false,
        canRequestFocus: false,
        child: GestureDetector(
          onTap: () {
            // Klavyeyi kapat
            if (mounted) {
              FocusScope.of(context).unfocus();
            }
          },
          child: _controller.value.isInitialized
              ? Builder(
                  builder: (context) {
                    try {
                      // Video boyutlarını güvenli bir şekilde al
                      final videoSize = _controller.value.size;
                      if (videoSize.width <= 0 || videoSize.height <= 0) {
                        Logger.warning(
                          'Video boyutları geçersiz: ${videoSize.width}x${videoSize.height}',
                          tag: 'SplashView',
                        );
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Ekran boyutlarını al
                      final screenSize = MediaQuery.of(context).size;
                      
                      Logger.info(
                        'Video boyutları: ${videoSize.width}x${videoSize.height}, Ekran boyutları: ${screenSize.width}x${screenSize.height}',
                        tag: 'SplashView',
                      );

                      return SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: videoSize.width,
                            height: videoSize.height,
                            child: Focus(
                              autofocus: false,
                              canRequestFocus: false,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      Logger.error(
                        'Video player build hatası: $e',
                        tag: 'SplashView',
                      );
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
