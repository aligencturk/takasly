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
    FocusScope.of(context).unfocus();
    // Tüm focus'ları temizle
    FocusManager.instance.primaryFocus?.unfocus();
  });

  _controller = VideoPlayerController.asset("assets/splash/powered_by_rivorya_yazilim.mp4")
    ..initialize().then((_) {
      setState(() {});
      // Video başladıktan 3 saniye sonra giriş kontrolü yap
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _checkAuthAndNavigate();
        }
      });
      _controller.play();
    });
}

Future<void> _checkAuthAndNavigate() async {
  try {
    Logger.info('🔍 SplashView - Always navigating to login for first entry');
    
    // Her zaman login sayfasına git (ilk giriş için)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  } catch (e) {
    Logger.error('❌ SplashView - Error navigating to login: $e', error: e);
    // Hata durumunda da login sayfasına yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }
}


  @override
  void dispose() {
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
            FocusScope.of(context).unfocus();
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


