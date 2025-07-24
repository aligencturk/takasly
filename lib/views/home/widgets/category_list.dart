import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<ProductViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.categories.isEmpty) {
            // TODO: Skeleton loader (Shimmer) eklenecek
            return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()));
          }
          
          return SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vm.categories.length + 1, // "Tümü" için +1
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryItem(
                    context: context,
                    label: 'Tümü',
                    icon: Icons.apps_rounded,
                    isSelected: vm.currentCategoryId == null,
                    onTap: () => vm.filterByCategory(null),
                  );
                }
                final category = vm.categories[index - 1];
                return _buildCategoryItem(
                  context: context,
                  label: category.name,
                  icon: _getCategoryIcon(category.icon), // API'den gelen ikona göre
                  isSelected: vm.currentCategoryId == category.id,
                  onTap: () => vm.filterByCategory(category.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppTheme.surface : AppTheme.primary;
    final bgColor = isSelected ? AppTheme.primary : AppTheme.surface;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppTheme.borderRadius,
                boxShadow: isSelected ? AppTheme.cardShadow : null,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: AppTheme.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  // Bu ikon eşleştirme, API'den gelen string'lere göre düzenlenmeli
  IconData _getCategoryIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'elektronik': return Icons.phone_iphone_rounded;
      case 'giyim': return Icons.checkroom_rounded;
      case 'kitap': return Icons.menu_book_rounded;
      case 'ev & yaşam': return Icons.chair_rounded;
      case 'spor': return Icons.sports_soccer_rounded;
      default: return Icons.category_rounded;
    }
  }
} 