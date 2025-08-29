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
      title: 'Takasly\'e Hoşgeldiniz!',
      description:
          'Takasly, eşyalarınızı tamamen ücretsiz ve komisyonsuz şekilde takas edebileceğiniz güvenilir bir platformdur.',
      imagePath: 'assets/images/1.png',
    ),
    const OnboardingModel(
      title: 'Takas Teklifleri Anında!',
      description:
          'Eşyanı ilan olarak ekle, Kullanıcıların tekliflerini gör, Beğendiğin teklifi kabul et, kolayca takas yap!',
      imagePath: 'assets/images/2.png',
    ),
    const OnboardingModel(
      title: 'Komisyon Yok, Masraf Yok!',
      description:
          'Tüm ilanlar ücretsiz! Kolay arama ve kategori filtreleriyle ihtiyacını hemen bul! Şimdi başlayarak ilk takasını yap!',
      imagePath: 'assets/images/3.png',
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
      // TEST MODU: Her zaman false döndür (onboarding her girişte gösterilsin)
      Logger.info(
        '🧪 TEST MODU: Onboarding durumu her zaman false döndürülüyor',
      );
      return false;

      // Normal mod için aşağıdaki kodu kullan:
      // return await CacheService().isOnboardingCompleted() ?? false;
    } catch (e) {
      Logger.error('Onboarding durumu kontrol hatası: $e', error: e);
      return false;
    }
  }
}
