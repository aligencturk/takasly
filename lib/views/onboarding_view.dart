import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../models/onboarding_model.dart';
import '../core/app_theme.dart';
import '../utils/logger.dart';
import 'auth/login_view.dart';
import 'home/home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  @override
  void initState() {
    super.initState();
    Logger.info('🎯 OnboardingView başlatıldı');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(
              child: Column(
                children: [
                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: viewModel.pageController,
                      onPageChanged: viewModel.onPageChanged,
                      itemCount: viewModel.onboardingPages.length,
                      itemBuilder: (context, index) {
                        final page = viewModel.onboardingPages[index];
                        return _OnboardingPage(page: page);
                      },
                    ),
                  ),

                  // Alt kısım - Butonlar ve indicator
                  _buildBottomSection(context, viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Sayfa indicator'ları
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              viewModel.onboardingPages.length,
              (index) => _buildPageIndicator(
                index: index,
                isActive: index == viewModel.currentPage,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Butonlar
          Row(
            children: [
              // Geri butonu (ilk sayfada gizli)
              if (viewModel.currentPage > 0)
                Expanded(
                  child: _buildButton(
                    text: 'Geri',
                    onPressed: viewModel.previousPage,
                    isOutlined: true,
                  ),
                ),

              if (viewModel.currentPage > 0) const SizedBox(width: 16),

              // İleri/Tamamla butonu
              Expanded(
                flex: viewModel.currentPage > 0 ? 1 : 1,
                child: _buildButton(
                  text:
                      viewModel.currentPage ==
                          viewModel.onboardingPages.length - 1
                      ? 'Başla'
                      : 'İleri',
                  onPressed:
                      viewModel.currentPage ==
                          viewModel.onboardingPages.length - 1
                      ? () => _handleCompleteOnboarding(context, viewModel)
                      : viewModel.nextPage,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Giriş yap butonu (son sayfada)
          if (viewModel.currentPage == viewModel.onboardingPages.length - 1)
            SizedBox(
              width: double.infinity,
              child: _buildButton(
                text: 'Giriş Yap',
                onPressed: () => _navigateToLogin(context),
                isOutlined: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator({required int index, required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary
            : AppTheme.textSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppTheme.primary,
          foregroundColor: isOutlined ? AppTheme.primary : Colors.white,
          side: isOutlined
              ? BorderSide(color: AppTheme.primary, width: 2)
              : null,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
          elevation: isOutlined ? 0 : 2,
        ),
        child: Text(
          text,
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: isOutlined ? AppTheme.primary : Colors.white,
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

  void _navigateToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingModel page;

  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Resim
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  Logger.error(
                    'Onboarding resim yükleme hatası: $error',
                    error: error,
                  );
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: AppTheme.borderRadius,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Başlık
          Text(
            page.title,
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Açıklama
          Text(
            page.description,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
