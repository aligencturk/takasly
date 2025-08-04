import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takasly/views/home/home_view.dart';
import 'package:takasly/views/auth/login_view.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:video_player/video_player.dart';
import 'package:takasly/utils/logger.dart';

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

  _controller = VideoPlayerController.asset("assets/splash/powered_by_rivorya_yazilim.mp4")
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

Future<void> _checkAuthAndNavigate() async {
  try {
    Logger.info('🔍 SplashView - Checking authentication status...');
    
    // Widget'ın hala aktif olup olmadığını kontrol et
    if (!mounted) {
      Logger.warning('⚠️ SplashView - Widget is no longer mounted, aborting navigation');
      return;
    }
    
    // AuthViewModel'i al
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Hot restart durumunu kontrol et (kullanıcı zaten giriş yapmış olabilir)
    final isHotRestart = await _checkIfHotRestart();
    
    if (isHotRestart) {
      Logger.info('🔄 SplashView - Hot restart detected, enabling auto-login...');
      await authViewModel.enableHotRestartAutoLogin();
      
      // Hot restart durumunda otomatik giriş kontrolü yap
      final isLoggedIn = await authViewModel.isLoggedInAsync;
      
      if (isLoggedIn && authViewModel.currentUser != null && authViewModel.currentUser!.id.isNotEmpty) {
        Logger.info('✅ SplashView - Hot restart: User is logged in, navigating to home');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
        return;
      }
    }
    
    // Normal durum veya hot restart'ta giriş yapılmamışsa login'e yönlendir
    Logger.info('🔒 SplashView - Navigating to login (normal startup or no valid session)');
    
    // Widget'ın hala aktif olup olmadığını kontrol et
    if (!mounted) {
      Logger.warning('⚠️ SplashView - Widget is no longer mounted before navigation, aborting');
      return;
    }
    
    // Login sayfasına yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
    
  } catch (e) {
    Logger.error('❌ SplashView - Error during navigation: $e', error: e);
    
    // Hata durumunda da mounted kontrolü yap
    if (!mounted) {
      Logger.warning('⚠️ SplashView - Widget is no longer mounted during error handling, aborting navigation');
      return;
    }
    
    // Hata durumunda da login sayfasına yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }
}

// Hot restart durumunu kontrol et
Future<bool> _checkIfHotRestart() async {
  try {
    // SharedPreferences'dan bir flag kontrol et
    final prefs = await SharedPreferences.getInstance();
    final lastAppStart = prefs.getInt('last_app_start') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Eğer son uygulama başlatma zamanı 10 saniye içindeyse hot restart olabilir
    final isHotRestart = (currentTime - lastAppStart) < 10000; // 10 saniye
    
    // Şimdiki zamanı kaydet
    await prefs.setInt('last_app_start', currentTime);
    
    Logger.info('🔍 SplashView - Hot restart check: $isHotRestart (time diff: ${currentTime - lastAppStart}ms)');
    
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


