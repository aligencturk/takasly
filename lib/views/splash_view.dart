import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../core/constants.dart';
import '../services/location_service.dart';
import '../utils/logger.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Logger.info('🚀 SplashView initialized');
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    Logger.info('🔍 SplashView: Checking authentication status...');
    
    // Kısa bir delay (hot reload için daha hızlı)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Hot reload durumunu kontrol et
    await authViewModel.checkHotReloadState();
    
    // AuthViewModel'in initialization'ını bekle
    int retryCount = 0;
    while (!authViewModel.isInitialized && retryCount < 10) {
      Logger.info('⏳ Waiting for AuthViewModel initialization... (attempt ${retryCount + 1})');
      await Future.delayed(const Duration(milliseconds: 200));
      retryCount++;
    }
    
    if (!authViewModel.isInitialized) {
      Logger.warning('⚠️ AuthViewModel not initialized after retries, forcing reinitialize...');
      await authViewModel.reinitializeForHotReload();
    }
    
    // Konum izinlerini kontrol et (arka planda)
    _requestLocationPermission();
    
    if (!mounted) return;
    
    // Authentication durumuna göre yönlendir
    if (authViewModel.isLoggedIn && authViewModel.currentUser != null) {
      Logger.info('✅ User is logged in, navigating to home: ${authViewModel.currentUser!.name}');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Logger.info('❌ User is not logged in, navigating to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      Logger.info('📍 SplashView: Checking location permissions...');
      final locationService = LocationService();
      
      // Konum servisinin aktif olup olmadığını kontrol et
      final isLocationEnabled = await locationService.isLocationServiceEnabled();
      Logger.info('📍 Location service enabled: $isLocationEnabled');
      
      if (!isLocationEnabled) {
        Logger.warning('⚠️ Location service is disabled - Enable in emulator settings');
        Logger.info('📍 Settings > Location > Location services açın');
        return;
      }
      
      // Konum iznini iste
      Logger.info('📍 Requesting location permission...');
      final hasPermission = await locationService.requestLocationPermission();
      Logger.info('📍 Location permission result: $hasPermission');
      
      if (hasPermission) {
        Logger.info('✅ Location permission granted');
        // Test için konumu al
        Logger.info('📍 Getting current location...');
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          Logger.info('📍 Location obtained: ${position.latitude}, ${position.longitude}');
        } else {
          Logger.warning('⚠️ Could not get location - Set test location in emulator');
        }
      } else {
        Logger.warning('❌ Location permission denied');
        Logger.info('📍 In emulator: Settings > Apps > Takasly > Permissions > Location > Allow');
      }
    } catch (e) {
      Logger.error('❌ Error getting location permission: $e', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10B981), // AppTheme.primary ile uyumlu yeşil
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Takasly Logo
            Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/takasly splash image.png',
                  fit: BoxFit.contain,
                  width: 180,
                  height: 100,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name (artık gerekli değil çünkü logo'da var)
            // const Text(
            //   AppConstants.appName,
            //   style: TextStyle(
            //     fontSize: 32,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),
            
            // const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              'Kullanmadığın Eşyaları Takaslayarak Yenile',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
} 