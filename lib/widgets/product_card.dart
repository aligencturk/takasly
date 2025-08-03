import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/utils/logger.dart';
import '../../views/product/product_detail_view.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? heroTag;
  final bool hideFavoriteIcon;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTag,
    this.hideFavoriteIcon = false,
  });

  String _getCategoryDisplayName(Product product, BuildContext context) {
    Logger.debug('Product ${product.id} - 3-Layer Category Check:');
    Logger.debug('  categoryName: "${product.catname}"');
    Logger.debug('  category.name: "${product.category.name}"');
    Logger.debug('  categoryId: "${product.categoryId}"');
    Logger.debug('  mainCategoryName: "${product.mainCategoryName}"');
    Logger.debug('  parentCategoryName: "${product.parentCategoryName}"');
    Logger.debug('  subCategoryName: "${product.subCategoryName}"');

    // 3 katmanlı kategori sisteminde öncelik sırası:
    // 1. Ana kategori adı (mainCategoryName)
    if (product.mainCategoryName != null &&
        product.mainCategoryName!.isNotEmpty &&
        product.mainCategoryName != 'null' &&
        product.mainCategoryName != 'Kategori' &&
        product.mainCategoryName != 'Kategori Yok') {
      Logger.debug('Using mainCategoryName: ${product.mainCategoryName}');
      return product.mainCategoryName!;
    }

    // 2. Üst kategori adı (parentCategoryName)
    if (product.parentCategoryName != null &&
        product.parentCategoryName!.isNotEmpty &&
        product.parentCategoryName != 'null' &&
        product.parentCategoryName != 'Kategori' &&
        product.parentCategoryName != 'Kategori Yok') {
      Logger.debug('Using parentCategoryName: ${product.parentCategoryName}');
      return product.parentCategoryName!;
    }

    // 3. Alt kategori adı (subCategoryName)
    if (product.subCategoryName != null &&
        product.subCategoryName!.isNotEmpty &&
        product.subCategoryName != 'null' &&
        product.subCategoryName != 'Kategori' &&
        product.subCategoryName != 'Kategori Yok') {
      Logger.debug('Using subCategoryName: ${product.subCategoryName}');
      return product.subCategoryName!;
    }

    // 4. Direkt categoryName alanı (categoryList'ten gelen en spesifik kategori)
    if (product.catname.isNotEmpty &&
        product.catname != 'null' &&
        product.catname != 'Kategori') {
      Logger.debug('Using categoryName: ${product.catname}');
      return product.catname;
    }

    // 5. Category nesnesinin name alanı
    if (product.category != null &&
        product.category.name.isNotEmpty &&
        product.category.name != 'Kategori' &&
        product.category.name != 'Kategori Yok') {
      Logger.debug('Using category.name: ${product.category.name}');
      return product.category.name;
    }

    // 6. ProductViewModel'den kategori arama (sadece ana kategoriler için)
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    final categoryName = productViewModel.getCategoryNameById(product.categoryId);
    if (categoryName != 'Kategori Yok') {
      Logger.debug('Found category using getCategoryNameById: $categoryName');
      return categoryName;
    }

    // 7. Kategori ID'sini göster
    if (product.categoryId.isNotEmpty) {
      Logger.debug('No category name found, showing category ID: ${product.categoryId}');
      return 'Kategori ${product.categoryId}';
    }

    Logger.debug('No valid category found, returning "Kategori Yok"');
    return 'Kategori Yok';
  }

  @override
  Widget build(BuildContext context) {
    // Debug log ekle
    Logger.debug('ProductCard - Building card for product: ${product.title} (ID: ${product.id}), hideFavoriteIcon: $hideFavoriteIcon');
    
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag ?? 'default_product_${product.id}',
                    child: Builder(
                      builder: (context) {
                        final imageUrl = product.images.isNotEmpty ? product.images.first : '';
                        
                        // Resim URL'si boş veya geçersizse placeholder göster
                        final uri = Uri.tryParse(imageUrl);
                        if (imageUrl.isEmpty || 
                            imageUrl == 'null' || 
                            imageUrl == 'undefined' ||
                            imageUrl.contains('product_68852b20b6cac.png') ||
                            uri == null ||
                            !uri.hasAbsolutePath) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Resim yok',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                                                     child: CachedNetworkImage(
                             imageUrl: imageUrl,
                             fit: BoxFit.cover,
                             width: double.infinity,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[200]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Resim yüklenemedi',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Favori kalp ikonu - sadece hideFavoriteIcon false ise göster
                  if (!hideFavoriteIcon)
                    Consumer<ProductViewModel>(
                      builder: (context, productViewModel, child) {
                        Logger.debug('ProductCard - Rendering favorite icon for product: ${product.id}');
                        final isFavorite = productViewModel.isFavorite(product.id);
                        return Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () async {
                              final result = await productViewModel.toggleFavorite(product.id);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: result['wasFavorite'] ? Colors.orange : Colors.green,
                                  ),
                                );
                              } else {
                                // 417 hatası veya diğer hatalar için API'den gelen mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey('favorite_${product.id}'),
                                color: isFavorite ? Colors.red : Colors.grey[600],
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Bilgiler
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kategori
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 16, // iOS için minimum yükseklik
                      ),
                      child:                       Text(
                        _getCategoryDisplayName(product, context),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary, // Debug için kırmızı renk
                          fontWeight: FontWeight.w600, // Daha kalın font
                          letterSpacing: 0.5,
                          fontSize: 12, // Daha büyük font boyutu
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Başlık
                    Text(
                      product.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Konum
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined, 
                          size: 12, 
                          color: Colors.grey[500],
                        ),
                        Text(
                          product.cityTitle + "/" + product.districtTitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}