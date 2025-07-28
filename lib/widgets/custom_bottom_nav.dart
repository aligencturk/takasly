import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, FontAwesomeIcons.house, FontAwesomeIcons.house, 'Ana Sayfa'),
              _buildNavItem(1, FontAwesomeIcons.comments, FontAwesomeIcons.comments, 'Sohbet'),
              _buildCenterTradeButton(),
              _buildNavItem(3, FontAwesomeIcons.list, FontAwesomeIcons.list, 'Takaslarım'),
              _buildNavItem(4, FontAwesomeIcons.user, FontAwesomeIcons.user, 'Hesap'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ortadaki butonun yarısı dışarıda (üstte) olacak şekilde, nav bar'ın üst sınırından taşacak şekilde konumlandırılmış hali
  Widget _buildCenterTradeButton() {
    final isActive = currentIndex == 2;

    return Column(
      children: [
        // Butonun yarısı nav bar'ın dışında (üstte) olacak şekilde negatif margin ile yukarı taşıyoruz
        Transform.translate(
          offset: const Offset(0, -12), // Biraz daha az taşma
          child: GestureDetector(
            onTap: () => onTap(2),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.surface,
                  width: 3,
                ),
              ),
              child: Icon(
                FontAwesomeIcons.exchange,
                color: AppTheme.surface,
                size: 20,
              ),
            ),
          ),
        ),
        // Metin dairenin altında, diğer butonlarla aynı hizada
        Transform.translate(
          offset: const Offset(0, -6), // Metni daha az yukarı çek
          child: Text(
            'İlan Ekle',
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}