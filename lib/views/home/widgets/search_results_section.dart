import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../widgets/error_widget.dart' as custom_error;
import '../../../widgets/product_card.dart';
import '../../../widgets/skeletons/product_grid_skeleton.dart';

class SearchResultsSection extends StatelessWidget {
  final String currentQuery;
  final VoidCallback onRetry;
  final VoidCallback onAfterFilterApplied;

  const SearchResultsSection({
    super.key,
    required this.currentQuery,
    required this.onRetry,
    required this.onAfterFilterApplied,
  });

  // Responsive grid sütun sayısı
  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  // Kart oranı: görsel ağırlıklı, modern oran
  double _calculateChildAspectRatio(BuildContext context) {
    final crossAxisCount = _calculateCrossAxisCount(context);
    // Kolon arttıkça kartı biraz daha dikey tut
    switch (crossAxisCount) {
      case 5:
        return 0.78;
      case 4:
        return 0.76;
      case 3:
        return 0.74;
      default: 
        return 0.75;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.products.isEmpty) {
          return const ProductGridSkeleton();
        }

        if (vm.hasError && vm.products.isEmpty) {
          return custom_error.CustomErrorWidget(
            message: vm.errorMessage ?? 'Arama sonuçları yüklenemedi.',
            onRetry: onRetry,
          );
        }

        if (vm.products.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: AppTheme.borderRadius,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppTheme.background,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sonuç Bulunamadı',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"$currentQuery" için sonuç bulunamadı. Farklı anahtar kelimeler deneyebilir veya filtreleri güncelleyebilirsiniz.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (vm.popularCategories.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.borderRadius,
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Popüler Kategoriler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.popularCategories.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final category = vm.popularCategories[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: const Icon(
                              Icons.category_rounded,
                              color: AppTheme.textSecondary,
                              size: 22,
                            ),
                            title: Text(
                              category.catName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${category.productCount} ürün',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () {
                              final vm = context.read<ProductViewModel>();
                              vm.addCategorySearchHistory(
                                category.catName,
                                category.catId.toString(),
                              );

                              final filter = vm.currentFilter.copyWith(
                                categoryId: category.catId.toString(),
                                searchText: null,
                              );
                              vm.applyFilter(filter);
                              onAfterFilterApplied();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vm.products.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentQuery.isNotEmpty
                          ? '"$currentQuery" için sonuç'
                          : 'Sonuçlar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppTheme.background,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _calculateCrossAxisCount(context);
                    final aspectRatio = _calculateChildAspectRatio(context);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: vm.products.length,
                      itemBuilder: (context, index) {
                        final product = vm.products[index];

                        bool isOwnProduct = false;
                        if (vm.myProducts.isNotEmpty) {
                          isOwnProduct = vm.myProducts.any(
                            (myProduct) => myProduct.id == product.id,
                          );
                        } else {
                          final authViewModel = Provider.of<AuthViewModel>(
                            context,
                            listen: false,
                          );
                          final currentUserId = authViewModel.currentUser?.id;
                          isOwnProduct = currentUserId != null &&
                              product.ownerId == currentUserId;
                        }

                        return ProductCard(
                          product: product,
                          heroTag: 'search_product_${product.id}_$index',
                          hideFavoriteIcon: isOwnProduct,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


