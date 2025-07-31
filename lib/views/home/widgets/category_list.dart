import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import 'package:takasly/models/product_filter.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return SliverToBoxAdapter(
      child: Consumer<ProductViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.categories.isEmpty) {
            // TODO: Skeleton loader (Shimmer) eklenecek
            return SizedBox(
              height: isSmallScreen ? 90 : 100,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          
          return SizedBox(
            height: isSmallScreen ? 90 : 100, // Yüksekliği artırdım çünkü metin 2 satıra çıkabilir
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
              ),
              itemCount: vm.categories.length + 1, // "Tümü" için +1
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryItem(
                    context: context,
                    label: 'Tümü',
                    icon: Icons.apps_rounded,
                    isSelected: vm.currentFilter.categoryId == null,
                    onTap: () => _applyCategoryFilter(vm, null),
                    isSmallScreen: isSmallScreen,
                  );
                }
                final category = vm.categories[index - 1];
                return _buildCategoryItem(
                  context: context,
                  label: category.name,
                  icon: _getCategoryIcon(category.icon), // API'den gelen ikona göre
                  isSelected: vm.currentFilter.categoryId == category.id,
                  onTap: () => _applyCategoryFilter(vm, category.id),
                  isSmallScreen: isSmallScreen,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _applyCategoryFilter(ProductViewModel vm, String? categoryId) {
    // Mevcut filtreyi koruyarak sadece kategoriyi değiştir
    final newFilter = vm.currentFilter.copyWith(categoryId: categoryId);
    vm.applyFilter(newFilter);
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    final color = isSelected ? AppTheme.surface : AppTheme.primary;
    final bgColor = isSelected ? AppTheme.primary : AppTheme.surface;
    
    // Responsive boyutlar
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final containerSize = isSmallScreen ? 45.0 : 50.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;
    final horizontalPadding = isSmallScreen ? 8.0 : 10.0;
    
    return Container(
      width: isSmallScreen ? 70.0 : 80.0, // Sabit genişlik
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimum boyut kullan
          children: [
            // İkon container'ı - sabit yükseklik
            Container(
              height: containerSize + spacing + 32, // İkon + spacing + metin için sabit yükseklik
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Üstten başla
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      boxShadow: isSelected ? AppTheme.cardShadow : null,
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: AppTheme.textPrimary,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                    maxLines: 2, // İki satıra kadar izin ver
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center, // Metni ortala
                  ),
                ],
              ),
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
      default: return Icons.category_sharp;
    }
  }
} 