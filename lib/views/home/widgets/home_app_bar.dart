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
      expandedHeight: 60,
      title: Row(
        children: [
          Image.asset(
            'assets/logo/logo.png',
            height: 32,
            width: 32,
          ),
          const SizedBox(width: 8),
          Text(
            'Takasly',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
} 