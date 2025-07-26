import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:takasly/core/app_theme.dart';
import 'package:takasly/models/product.dart';
import '../../views/product/product_detail_view.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? heroTag;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: product.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadius,
        ),
        elevation: 2,
        color: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Expanded(
              flex: 5,
              child: Hero(
                tag: heroTag ?? 'product_image_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
                child: Builder(
                  builder: (context) {
                    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
                    print('🖼️ [CARD] Displaying image for ${product.title}: $imageUrl');
                    print('🖼️ [CARD] Total images: ${product.images.length}');
                    print('🖼️ [CARD] All images: ${product.images}');
                    
                    // Resim URL'si boş veya geçersizse placeholder göster
                    final uri = Uri.tryParse(imageUrl);
                    if (imageUrl.isEmpty || 
                        imageUrl == 'null' || 
                        imageUrl == 'undefined' ||
                        imageUrl.contains('product_68852b20b6cac.png') || // Bu spesifik hatalı URL'yi filtrele
                        uri == null || // URL parse edilemiyorsa
                        !uri.hasAbsolutePath) { // URL formatını kontrol et
                      print('⚠️ [CARD] Empty or invalid image URL for ${product.title}: $imageUrl');
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Resim yok',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) {
                        print('❌ [CARD] Image load error for ${product.title}: $error');
                        print('❌ [CARD] Failed URL: $url');
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Resim yüklenemedi',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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
                    Text(
                      product.category.name.toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Başlık
                    Text(
                      product.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Konum veya Sahip
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.owner.location?.city ?? 'Türkiye', // Varsayılan konum
                            style: textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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