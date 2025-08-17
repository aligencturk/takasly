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
      Logger.info('🔍 SplashView - Checking authentication status...');

      // Widget'ın hala aktif olup olmadığını kontrol et
      if (!mounted) {
        Logger.warning(
          '⚠️ SplashView - Widget is no longer mounted, aborting navigation',
        );
        return;
      }

      // AuthViewModel'i al
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Hot restart durumunu kontrol et (kullanıcı zaten giriş yapmış olabilir)
      final isHotRestart = await _checkIfHotRestart();

      if (isHotRestart) {
        Logger.info(
          '🔄 SplashView - Hot restart detected, enabling auto-login...',
        );
        await authViewModel.enableHotRestartAutoLogin();

        // Hot restart durumunda otomatik giriş kontrolü yap
        final isLoggedIn = await authViewModel.isLoggedInAsync;

        if (isLoggedIn &&
            authViewModel.currentUser != null &&
            authViewModel.currentUser!.id.isNotEmpty) {
          Logger.info(
            '✅ SplashView - Hot restart: User is logged in, navigating to home',
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeView()),
          );
          return;
        }
      }

      // Normal başlangıç durumunda da otomatik giriş kontrolü yap
      Logger.info('🔍 SplashView - Checking for existing login session...');

      // SharedPreferences'dan token ve user ID kontrolü yap
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.userTokenKey);
      final userId = prefs.getString(AppConstants.userIdKey);
      final userData = prefs.getString(AppConstants.userDataKey);

      Logger.info(
        '🔍 SplashView - Token: ${token?.substring(0, token.length > 10 ? 10 : token.length)}..., UserID: $userId, UserData: ${userData?.length ?? 0} chars',
      );

      // Eğer geçerli token ve user data varsa otomatik giriş yap
      if (token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty &&
          userId != '0' &&
          userData != null &&
          userData.isNotEmpty) {
        Logger.info(
          '✅ SplashView - Valid session found, attempting auto-login...',
        );

        try {
          // AuthViewModel'i güncelle
          await authViewModel.enableHotRestartAutoLogin();

          // Kullanıcı bilgilerini yükle
          final isLoggedIn = await authViewModel.isLoggedInAsync;

          if (isLoggedIn &&
              authViewModel.currentUser != null &&
              authViewModel.currentUser!.id.isNotEmpty) {
            Logger.info(
              '✅ SplashView - Auto-login successful, navigating to home',
            );

            if (!mounted) {
              Logger.warning(
                '⚠️ SplashView - Widget is no longer mounted after auto-login',
              );
              return;
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeView()),
            );
            return;
          } else {
            Logger.warning(
              '⚠️ SplashView - Auto-login failed, user data invalid',
            );
          }
        } catch (e) {
          Logger.error('❌ SplashView - Auto-login error: $e', error: e);
        }
      } else {
        Logger.info('❌ SplashView - No valid session found');
      }

      // Otomatik giriş başarısızsa veya geçerli session yoksa login'e yönlendir
      Logger.info(
        '🔒 SplashView - Navigating to login (no valid session or auto-login failed)',
      );

      // Widget'ın hala aktif olup olmadığını kontrol et
      if (!mounted) {
        Logger.warning(
          '⚠️ SplashView - Widget is no longer mounted before navigation, aborting',
        );
        return;
      }

      // Login sayfasına yönlendir
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
    } catch (e) {
      Logger.error('❌ SplashView - Error during navigation: $e', error: e);

      // Hata durumunda da mounted kontrolü yap
      if (!mounted) {
        Logger.warning(
          '⚠️ SplashView - Widget is no longer mounted during error handling, aborting navigation',
        );
        return;
      }

      // Hata durumunda da login sayfasına yönlendir
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
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
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: Focus(
                        autofocus: false,
                        canRequestFocus: false,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
