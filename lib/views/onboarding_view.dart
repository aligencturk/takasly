import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../models/onboarding_model.dart';
import '../core/app_theme.dart';
import '../utils/logger.dart';

import 'home/home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  AnimationController? _buttonAnimationController;
  Animation<Offset>? _buttonSlideAnimation;
  Animation<double>? _buttonFadeAnimation;
  Animation<double>? _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    Logger.info('🎯 OnboardingView başlatıldı');

    // Animasyon controller'ı başlat
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Daha hızlı ve responsive
      vsync: this,
    );

    // Animasyonları hemen başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAnimations();
        _startButtonAnimation();
      }
    });
  }

  void _initializeAnimations() {
    if (!mounted) return;
    if (_buttonAnimationController == null) return;

    // Slide animasyonu (arkadan yukarı)
    _buttonSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.8), // Daha yakından başla
          end: Offset.zero, // Normal pozisyon
        ).animate(
          CurvedAnimation(
            parent: _buttonAnimationController!,
            curve: Curves.easeOutCubic, // Daha yumuşak ve kurumsal
          ),
        );

    // Fade animasyonu
    _buttonFadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController!,
        curve: Curves.easeOut, // Daha yumuşak fade
      ),
    );

    // Scale animasyonu
    _buttonScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController!,
        curve: Curves.easeOutCubic, // Daha yumuşak ve kurumsal
      ),
    );
  }

  void _startButtonAnimation() {
    if (!mounted) return;
    if (_buttonAnimationController == null) return;

    // Animasyonu sıfırla
    _buttonAnimationController!.reset();

    // Hemen başlat
    _buttonAnimationController!.forward();
  }

  @override
  void dispose() {
    _buttonAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: Stack(
              children: [
                // Tam ekran resim
                PageView.builder(
                  controller: viewModel.pageController,
                  onPageChanged: (page) {
                    viewModel.onPageChanged(page);
                    // Sayfa değişiminde buton animasyonlarını tekrar başlat
                    _startButtonAnimation();
                  },
                  itemCount: viewModel.onboardingPages.length,
                  itemBuilder: (context, index) {
                    final page = viewModel.onboardingPages[index];
                    return _OnboardingPage(page: page);
                  },
                ),

                // Sayfa indicator'ları (üst kısımda)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 0,
                  right: 0,
                  child: _buildPageIndicators(viewModel),
                ),

                // Butonlar (alt kısımda) - Animasyonlu
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 0,
                  right: 0,
                  child:
                      _buttonSlideAnimation != null &&
                          _buttonFadeAnimation != null &&
                          _buttonScaleAnimation != null &&
                          _buttonAnimationController != null
                      ? SlideTransition(
                          position: _buttonSlideAnimation!,
                          child: FadeTransition(
                            opacity: _buttonFadeAnimation!,
                            child: ScaleTransition(
                              scale: _buttonScaleAnimation!,
                              child: _buildButtons(viewModel),
                            ),
                          ),
                        )
                      : _buildButtons(
                          viewModel,
                        ), // Animasyonlar hazır değilse normal göster
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators(OnboardingViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        viewModel.onboardingPages.length,
        (index) => _buildPageIndicator(
          index: index,
          isActive: index == viewModel.currentPage,
        ),
      ),
    );
  }

  Widget _buildPageIndicator({required int index, required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 32 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildButtons(OnboardingViewModel viewModel) {
    // 2. ve 3. sayfa için farklı padding ve boyutlar
    final isSecondOrThirdPage =
        viewModel.currentPage == 1 || viewModel.currentPage == 2;

    return Padding(
      padding: EdgeInsets.only(
        left: isSecondOrThirdPage
            ? 10.0
            : 24.0, // 2. ve 3. sayfada sola yaklaştır
        right: isSecondOrThirdPage ? 40.0 : 24.0,
        bottom: isSecondOrThirdPage ? 20.0 : 0.0, // Alt kısımda da biraz azalt
      ),
      child: Row(
        children: [
          // Atlama butonu (ilk iki sayfada)
          if (viewModel.currentPage < viewModel.onboardingPages.length - 1)
            Expanded(
              flex: 1, // Her zaman eşit uzunluk
              child: _buildButton(
                text: 'Atla',
                onPressed: () => _handleCompleteOnboarding(context, viewModel),
                isOutlined: true,
                isSmall: isSecondOrThirdPage, // Küçük boyut için flag
              ),
            ),

          if (viewModel.currentPage < viewModel.onboardingPages.length - 1)
            SizedBox(
              width: isSecondOrThirdPage
                  ? 12.0
                  : 16.0, // 2. ve 3. sayfada daha az boşluk
            ), // Daha az boşluk
          // İleri/Tamamla butonu
          Expanded(
            flex: 1, // Her zaman eşit uzunluk
            child: _buildButton(
              text:
                  viewModel.currentPage == viewModel.onboardingPages.length - 1
                  ? 'Başla'
                  : 'İleri',
              onPressed:
                  viewModel.currentPage == viewModel.onboardingPages.length - 1
                  ? () => _handleCompleteOnboarding(context, viewModel)
                  : viewModel.nextPage,
              isSmall: isSecondOrThirdPage, // Küçük boyut için flag
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isOutlined = false,
    bool isSmall = false,
  }) {
    return SizedBox(
      height: isSmall ? 50 : 50, // 2. ve 3. sayfa için daha küçük
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppTheme.primary,
          foregroundColor: isOutlined ? AppTheme.primary : Colors.white,
          side: isOutlined
              ? BorderSide(color: AppTheme.primary, width: isSmall ? 1.0 : 2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: isSmall
                ? BorderRadius.circular(
                    8,
                  ) // Küçük butonlar için daha az rounded
                : AppTheme.borderRadius,
          ),
          elevation: isOutlined ? 0 : (isSmall ? 1 : 2),
        ),
        child: Text(
          text,
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: isOutlined ? AppTheme.primary : Colors.white,
            fontSize: isSmall ? 13 : 16, // 2. ve 3. sayfa için daha küçük font
            fontWeight: FontWeight.w600, // Daha kalın font
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteOnboarding(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) async {
    try {
      await viewModel.completeOnboarding();

      if (mounted) {
        // Ana sayfaya yönlendir
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
      }
    } catch (e) {
      Logger.error('Onboarding tamamlama hatası: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingModel page;

  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        page.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          Logger.error('Onboarding resim yükleme hatası: $error', error: error);
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.surface,
            child: Icon(
              Icons.image_not_supported,
              size: 80,
              color: AppTheme.textSecondary,
            ),
          );
        },
      ),
    );
  }
}
