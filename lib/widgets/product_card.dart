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
  final bool isProfileView;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTag,
    this.hideFavoriteIcon = false,
    this.isProfileView = false,
  });

  String _getCategoryDisplayName(Product product, BuildContext context) {
    // Debug: Kategori bilgilerini logla
    Logger.debug('🔍 ProductCard._getCategoryDisplayName - Product: ${product.title}', tag: 'ProductCard');
    Logger.debug('🔍 ProductCard._getCategoryDisplayName - categoryId: ${product.categoryId}', tag: 'ProductCard');
    Logger.debug('🔍 ProductCard._getCategoryDisplayName - catname: ${product.catname}', tag: 'ProductCard');
    Logger.debug('🔍 ProductCard._getCategoryDisplayName - category.name: ${product.category.name}', tag: 'ProductCard');
    
    // 3 katmanlı kategori sisteminde öncelik sırası:
    // 1. Ana kategori adı (mainCategoryName)
    if (product.mainCategoryName != null &&
        product.mainCategoryName!.isNotEmpty &&
        product.mainCategoryName != 'null' &&
        product.mainCategoryName != 'Kategori' &&
        product.mainCategoryName != 'Kategori Yok') {
      Logger.debug('🔍 ProductCard._getCategoryDisplayName - Using mainCategoryName: ${product.mainCategoryName}', tag: 'ProductCard');
      return product.mainCategoryName!;
    }

    // 2. Üst kategori adı (parentCategoryName)
    if (product.parentCategoryName != null &&
        product.parentCategoryName!.isNotEmpty &&
        product.parentCategoryName != 'null' &&
        product.parentCategoryName != 'Kategori' &&
        product.parentCategoryName != 'Kategori Yok') {
      Logger.debug('🔍 ProductCard._getCategoryDisplayName - Using parentCategoryName: ${product.parentCategoryName}', tag: 'ProductCard');
      return product.parentCategoryName!;
    }

    // 3. Alt kategori adı (subCategoryName)
    if (product.subCategoryName != null &&
        product.subCategoryName!.isNotEmpty &&
        product.subCategoryName != 'null' &&
        product.subCategoryName != 'Kategori' &&
        product.subCategoryName != 'Kategori Yok') {
      Logger.debug('🔍 ProductCard._getCategoryDisplayName - Using subCategoryName: ${product.subCategoryName}', tag: 'ProductCard');
      return product.subCategoryName!;
    }

    // 4. Direkt categoryName alanı (categoryList'ten gelen en spesifik kategori)
    if (product.catname.isNotEmpty &&
        product.catname != 'null' &&
        product.catname != 'Kategori') {
      Logger.debug('🔍 ProductCard._getCategoryDisplayName - Using catname: ${product.catname}', tag: 'ProductCard');
      return product.catname;
    }

    // 5. Category nesnesinin name alanı
    if (product.category.name.isNotEmpty &&
        product.category.name != 'Kategori' &&
        product.category.name != 'Kategori Yok') {
      Logger.debug('🔍 ProductCard._getCategoryDisplayName - Using category.name: ${product.category.name}', tag: 'ProductCard');
      return product.category.name;
    }

    // 6. ProductViewModel'den kategori arama (sadece ana kategoriler için)
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    final categoryName = productViewModel.getCategoryNameById(product.categoryId);
    if (categoryName != 'Kategori Yok') {
      Logger.debug('🔍 ProductCard._getCategoryDisplayName - Using ProductViewModel category: $categoryName', tag: 'ProductCard');
      return categoryName;
    }
    
    // 7. Eğer hiçbir kategori bulunamazsa, en azından "Kategori" yazısını göster
    Logger.debug('🔍 ProductCard._getCategoryDisplayName - No valid category found, using default: Kategori', tag: 'ProductCard');
    return 'Kategori';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    // Responsive boyutlar hesaplandı
    
    // Responsive font boyutları
    final categoryFontSize = screenWidth < 360 ? 9.0 : 11.0;
    final titleFontSize = screenWidth < 360 ? 9.0 : 11.0;
    final locationFontSize = screenWidth < 360 ? 8.0 : 10.0;

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
          borderRadius: BorderRadius.circular(screenWidth < 360 ? 6 : 8),
          border: Border.all(
            color: const Color.fromARGB(255, 209, 209, 209),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim - Responsive yükseklik
            AspectRatio(
              aspectRatio: 1.0, // Kare resim
              child: Stack(
                children: [
                  Builder(
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
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(screenWidth < 360 ? 6 : 8),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey[400],
                                  size: screenWidth < 360 ? 20 : 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Resim yok',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: screenWidth < 360 ? 8 : 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(screenWidth < 360 ? 6 : 8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(screenWidth < 360 ? 6 : 8),
                              ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey[400],
                                      size: screenWidth < 360 ? 20 : 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Resim yüklenemedi',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: screenWidth < 360 ? 8 : 10,
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
                  // Favori kalp ikonu - sadece hideFavoriteIcon false ise göster
                  if (!hideFavoriteIcon)
                    Consumer<ProductViewModel>(
                      builder: (context, productViewModel, child) {
                        final isFavorite = productViewModel.isFavorite(product.id);
                        return Positioned(
                          top: screenWidth < 360 ? 4 : 6,
                          right: screenWidth < 360 ? 4 : 6,
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(screenWidth < 360 ? 8 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(screenWidth < 360 ? 3 : 4),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  key: ValueKey('favorite_${product.id}'),
                                  color: isFavorite ? Colors.red : Colors.grey[600],
                                  size: screenWidth < 360 ? 14 : 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Bilgiler - Responsive yükseklik
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth < 360 ? 6 : 10, 
                  top: screenWidth < 360 ? 8 : 14, 
                  bottom: screenWidth < 360 ? 6 : 8,
                  right: screenWidth < 360 ? 6 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Üst: Kategori ve başlık
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori
                        Text(
                          _getCategoryDisplayName(product, context),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            fontSize: categoryFontSize,
                            height: 0.7,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth < 360 ? 4 : 6),
                        // Başlık
                        Text(
                          product.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: titleFontSize,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Alt: Konum
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: screenWidth < 360 ? 8 : 10,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final cityTitle = product.cityTitle.isNotEmpty ? product.cityTitle : 'Şehir belirtilmemiş';
                              final districtTitle = product.districtTitle.isNotEmpty ? product.districtTitle : 'İlçe belirtilmemiş';
                              final locationText = '$cityTitle/$districtTitle';
                              return Text(
                                locationText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: locationFontSize,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
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