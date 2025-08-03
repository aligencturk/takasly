import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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
    
    // AuthViewModel'i al ve giriş durumunu kontrol et
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // AuthViewModel'i initialize et (hot reload için)
    await authViewModel.checkHotReloadState();
    
    // Widget'ın hala aktif olup olmadığını tekrar kontrol et
    if (!mounted) {
      Logger.warning('⚠️ SplashView - Widget is no longer mounted after auth check, aborting navigation');
      return;
    }
    
    // Kullanıcının giriş durumunu kontrol et
    final isLoggedIn = await authViewModel.isLoggedInAsync;
    
    Logger.info('🔍 SplashView - User login status: $isLoggedIn');
    Logger.info('🔍 SplashView - Current user: ${authViewModel.currentUser?.name ?? 'None'}');
    
    // Widget'ın hala aktif olup olmadığını son kez kontrol et
    if (!mounted) {
      Logger.warning('⚠️ SplashView - Widget is no longer mounted before navigation, aborting');
      return;
    }
    
    // Daha güvenli kontrol: Hem isLoggedIn hem de currentUser kontrolü
    if (isLoggedIn && authViewModel.currentUser != null && authViewModel.currentUser!.id.isNotEmpty) {
      Logger.info('✅ SplashView - User is logged in, navigating to home');
      // Kullanıcı giriş yapmışsa home'a yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } else {
      Logger.info('❌ SplashView - User is not logged in, navigating to login');
      // Kullanıcı giriş yapmamışsa login'e yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  } catch (e) {
    Logger.error('❌ SplashView - Error checking auth status: $e', error: e);
    
    // Hata durumunda da mounted kontrolü yap
    if (!mounted) {
      Logger.warning('⚠️ SplashView - Widget is no longer mounted during error handling, aborting navigation');
      return;
    }
    
    // Hata durumunda login sayfasına yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
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


