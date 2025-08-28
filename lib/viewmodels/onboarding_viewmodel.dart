import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

class OnboardingViewModel extends ChangeNotifier {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Getter'lar
  PageController get pageController => _pageController;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;

  // Onboarding sayfaları
  final List<OnboardingModel> onboardingPages = [
    const OnboardingModel(
      title: 'Takasly\'e Hoş Geldin',
      description: 'Eşyalarını takas et, yeni değerler keşfet!',
      imagePath: 'assets/logo/takasly image.png',
    ),
    const OnboardingModel(
      title: 'Takasly Nedir?',
      description:
          'Takasly, eşyalarını başkalarıyla takas etmeni sağlayan güvenli ve kolay bir platformdur. Artık kullanmadığın eşyalarını değerlendir, ihtiyacın olan şeyleri ücretsiz elde et!',
      imagePath: 'assets/images/takasly splash image.png',
    ),
    const OnboardingModel(
      title: 'Hazır mısın?',
      description:
          'Takas dünyasına adım atmaya hazır mısın? Hemen başla ve eşyalarını takas etmeye başla!',
      imagePath: 'assets/logo/takasly image.png',
      isLastPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Sayfa değişikliği
  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
    Logger.info('Onboarding sayfa değişti: $page');
  }

  // Sonraki sayfa
  void nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Önceki sayfa
  void previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Onboarding'i tamamla
  Future<void> completeOnboarding() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Onboarding tamamlandı olarak işaretle
      await CacheService().setOnboardingCompleted(true);

      Logger.info('Onboarding başarıyla tamamlandı');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      Logger.error('Onboarding tamamlama hatası: $e', error: e);
    }
  }

  // Onboarding tamamlanmış mı kontrol et
  Future<bool> isOnboardingCompleted() async {
    try {
      return await CacheService().isOnboardingCompleted() ?? false;
    } catch (e) {
      Logger.error('Onboarding durumu kontrol hatası: $e', error: e);
      return false;
    }
  }
}
