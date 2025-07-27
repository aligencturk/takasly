import 'package:flutter/material.dart';
import 'package:takasly/core/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      pinned: true,
      floating: true,
      title: Text(
        'Takasly',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Arama sayfası implementasyonu
          },
          icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary, size: 28),
          tooltip: 'Ara',
        ),

        IconButton(
          onPressed: () {
            // TODO: Bildirimler sayfası implementasyonu
          },
          icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 28),
          tooltip: 'Bildirimler',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
} 