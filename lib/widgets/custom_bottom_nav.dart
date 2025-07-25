import 'package:flutter/material.dart';

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
        color: Colors.white,
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
          height: 55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Ana Sayfa'),
              _buildNavItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Sohbet'),
              _buildCenterTradeButton(),
              _buildNavItem(3, Icons.swap_horiz_outlined, Icons.swap_horiz, 'Takaslarım'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Hesap'),
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
              color: isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTradeButton() {
    final isActive = currentIndex == 2;
    
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF10B981) : const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Takasla',
              style: TextStyle(
                color: isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}