import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../core/constants.dart';
import '../services/location_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Konum izinlerini kontrol et ve iste
    await _requestLocationPermission();
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    if (authViewModel.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      print('📍 SplashView: Konum izinleri kontrol ediliyor...');
      final locationService = LocationService();
      
      // Konum servisinin aktif olup olmadığını kontrol et
      final isLocationEnabled = await locationService.isLocationServiceEnabled();
      print('📍 Konum servisi aktif mi: $isLocationEnabled');
      
      if (!isLocationEnabled) {
        print('⚠️ Konum servisi kapalı - Emülatörde açmanız gerekebilir');
        print('📍 Settings > Location > Location services açın');
        return;
      }
      
      // Konum iznini iste
      print('📍 Konum izni isteniyor...');
      final hasPermission = await locationService.requestLocationPermission();
      print('📍 Konum izni sonucu: $hasPermission');
      
      if (hasPermission) {
        print('✅ Konum izni verildi');
        // Test için konumu al
        print('📍 Konum alınmaya çalışılıyor...');
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          print('📍 Konum alındı: ${position.latitude}, ${position.longitude}');
        } else {
          print('⚠️ Konum alınamadı - Emülatörde test konumu ayarlayın');
        }
      } else {
        print('❌ Konum izni reddedildi');
        print('📍 Emülatörde: Settings > Apps > Takasly > Permissions > Location > Allow');
      }
    } catch (e) {
      print('❌ Konum izni alınırken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
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
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 60,
                color: Color(0xFF2196F3),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              'Kullanmadığın Eşyaları Takaslayarak Yenile',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
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